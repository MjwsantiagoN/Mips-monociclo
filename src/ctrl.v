// ============================================================================
// Grupo: BJLM (Brenno, Joao, Leticia, Marcos)
// Atividade: Projeto 02 - 2VA (Implementacao de MIPS Monociclo em Verilog)
// Disciplina: Arquitetura e Organizacao de Computadores
// Semestre letivo: 2026.2
// Arquivo: src/ctrl.v
// Descricao: Unidade de Controle Principal combinacional do MIPS monociclo.
//            Recebe o campo opcode (bits [31:26] da instrucao de 32 bits) e
//            gera os sinais de controle do datapath e o codigo ALUOp (4 bits)
//            alinhado ao contrato de integracao com src/ula_ctrl.v e src/ula.v.
//
// Subconjunto ISA coberto (28 instrucoes no total):
//   - Tipo-R (15): add, sub, and, or, xor, nor, slt, sltu,
//                  sll, srl, sra, sllv, srlv, srav, jr
//   - Tipo-I (11): addi, andi, ori, xori, slti, sltiu, lui, lw, sw, beq, bne
//   - Tipo-J  (2): j, jal
// ============================================================================

module ctrl (
    input  wire [5:0] opcode,   // Bits [31:26] da instrucao MIPS

    // Sinais de controle para o caminho de dados (datapath)
    output reg        RegDst,   // MUX de escrita no regfile: 0 = rt [20:16] | 1 = rd [15:11]
    output reg        ALUSrc,   // MUX da 2a entrada da ULA: 0 = ReadData2 ($rt) | 1 = imediato estendido
    output reg        MemtoReg, // MUX de dado para o regfile: 0 = saida da ULA | 1 = dado da memoria (lw)
    output reg        RegWrite, // Habilita escrita no banco de registradores (1 = escreve)
    output reg        MemRead,  // Habilita leitura na memoria de dados (1 = le, usado em lw)
    output reg        MemWrite, // Habilita escrita na memoria de dados (1 = escreve, usado em sw)
    output reg        BranchEq, // Desvio condicional beq: PC desvia quando (BranchEq & Zero_flag)
    output reg        BranchNE, // Desvio condicional bne: PC desvia quando (BranchNE & ~Zero_flag)
    output reg        Jump,     // Salto incondicional por endereco imediato (1 = j ou jal)
    output reg        Jal,      // Jump and Link: 1 = grava PC+4 no registrador $ra ($31)
    output reg        SignExt,  // Tipo de extensao do imediato: 1 = com sinal | 0 = com zeros

    // Codigo de 4 bits para ula_ctrl (deve espelhar docs/contrato_ula.md e src/ula_ctrl.v)
    output reg  [3:0] ALUOp
);

    // ------------------------------------------------------------------------
    // Opcodes oficiais da arquitetura MIPS (6 bits: Instruction[31:26])
    // ------------------------------------------------------------------------
    localparam [5:0]
        OP_RTYPE = 6'b000000, // 0x00 - Todas as Tipo-R (ula_ctrl olha o funct)
        OP_J     = 6'b000010, // 0x02 - j     (salto incondicional)
        OP_JAL   = 6'b000011, // 0x03 - jal   (salto incondicional + salva PC+4 em $31)
        OP_BEQ   = 6'b000100, // 0x04 - beq   (desvia se rs == rt)
        OP_BNE   = 6'b000101, // 0x05 - bne   (desvia se rs != rt)
        OP_ADDI  = 6'b001000, // 0x08 - addi  (soma imediato com sinal)
        OP_SLTI  = 6'b001010, // 0x0A - slti  (compara menor com sinal)
        OP_SLTIU = 6'b001011, // 0x0B - sltiu (compara menor sem sinal; imediato estendido com sinal)
        OP_ANDI  = 6'b001100, // 0x0C - andi  (AND com imediato estendido com zeros)
        OP_ORI   = 6'b001101, // 0x0D - ori   (OR  com imediato estendido com zeros)
        OP_XORI  = 6'b001110, // 0x0E - xori  (XOR com imediato estendido com zeros)
        OP_LUI   = 6'b001111, // 0x0F - lui   (carrega 16 bits na metade superior)
        OP_LW    = 6'b100011, // 0x23 - lw    (le palavra da memoria para rt)
        OP_SW    = 6'b101011; // 0x2B - sw    (grava palavra de rt na memoria)

    // ------------------------------------------------------------------------
    // Codigos ALUOp de 4 bits (identicos aos definidos em src/ula_ctrl.v)
    // ------------------------------------------------------------------------
    localparam [3:0]
        ALUOP_ADD   = 4'b0000, // lw, sw, addi
        ALUOP_SUB   = 4'b0001, // beq, bne
        ALUOP_RTYPE = 4'b0010, // Tipo-R (ula_ctrl decodifica pelo funct)
        ALUOP_AND   = 4'b0011, // andi
        ALUOP_OR    = 4'b0100, // ori
        ALUOP_XOR   = 4'b0101, // xori
        ALUOP_SLT   = 4'b0110, // slti
        ALUOP_SLTU  = 4'b0111, // sltiu
        ALUOP_LUI   = 4'b1000, // lui
        ALUOP_IDLE  = 4'b1111; // j, jal (ULA ociosa -> OP_NOP)

    // ------------------------------------------------------------------------
    // Bloco combinacional: sempre que 'opcode' mudar, recalcula os sinais
    // ------------------------------------------------------------------------
    always @(*) begin
        // Valores padrao seguros antes do case:
        // evita criacao de latches e impede bits indefinidos ('x').
        RegDst   = 1'b0;
        ALUSrc   = 1'b0;
        MemtoReg = 1'b0;
        RegWrite = 1'b0;
        MemRead  = 1'b0;
        MemWrite = 1'b0;
        BranchEq = 1'b0;
        BranchNE = 1'b0;
        Jump     = 1'b0;
        Jal      = 1'b0;
        SignExt  = 1'b0;
        ALUOp    = ALUOP_IDLE;

        case (opcode)
            // ----------------------------------------------------------------
            // Tipo-R (add, sub, and, or, xor, nor, slt, sltu, shifts e jr)
            // Nota: para 'jr', o campo rd na codificacao MIPS e $0 ($zero),
            // que o regfile protege contra escrita. A selecao de PC = $rs
            // (e opcionalmente bloqueio de RegWrite) usa funct == 6'h08 no
            // controle de desvios / top-level (mips.v).
            // ----------------------------------------------------------------
            OP_RTYPE: begin
                RegDst   = 1'b1;        // Destino eh rd [15:11]
                ALUSrc   = 1'b0;        // 2o operando da ULA vem de rt (ReadData2)
                MemtoReg = 1'b0;        // Dado gravado vem da ULA
                RegWrite = 1'b1;        // Habilita escrita no regfile
                ALUOp    = ALUOP_RTYPE; // ula_ctrl decide a operacao pelo funct
            end

            // ----------------------------------------------------------------
            // lw: calcula endereco (rs + offset com sinal), le memoria -> rt
            // ----------------------------------------------------------------
            OP_LW: begin
                RegDst   = 1'b0;        // Destino eh rt [20:16]
                ALUSrc   = 1'b1;        // 2o operando eh o offset imediato
                MemtoReg = 1'b1;        // Dado gravado vem da memoria de dados
                RegWrite = 1'b1;        // Grava o valor lido em rt
                MemRead  = 1'b1;        // Habilita leitura na memoria
                SignExt  = 1'b1;        // Offset de endereco tem sinal
                ALUOp    = ALUOP_ADD;   // ULA soma rs + offset
            end

            // ----------------------------------------------------------------
            // sw: calcula endereco (rs + offset com sinal) e grava rt na mem
            // ----------------------------------------------------------------
            OP_SW: begin
                ALUSrc   = 1'b1;        // 2o operando eh o offset imediato
                MemWrite = 1'b1;        // Habilita escrita na memoria de dados
                SignExt  = 1'b1;        // Offset de endereco tem sinal
                ALUOp    = ALUOP_ADD;   // ULA soma rs + offset
            end

            // ----------------------------------------------------------------
            // beq / bne: subtrai (rs - rt) na ULA; PC decide usando Zero_flag
            // ----------------------------------------------------------------
            OP_BEQ: begin
                ALUSrc   = 1'b0;        // Compara dois registradores (rs e rt)
                BranchEq = 1'b1;        // Desvia se Zero_flag == 1
                SignExt  = 1'b1;        // Offset do desvio tem sinal
                ALUOp    = ALUOP_SUB;   // ULA faz rs - rt
            end

            OP_BNE: begin
                ALUSrc   = 1'b0;        // Compara dois registradores (rs e rt)
                BranchNE = 1'b1;        // Desvia se Zero_flag == 0
                SignExt  = 1'b1;        // Offset do desvio tem sinal
                ALUOp    = ALUOP_SUB;   // ULA faz rs - rt
            end

            // ----------------------------------------------------------------
            // Tipo-I aritmetico/comparacao com extensao de SINAL
            // ----------------------------------------------------------------
            OP_ADDI: begin
                ALUSrc   = 1'b1;        // Usa imediato estendido
                RegWrite = 1'b1;        // Grava em rt (RegDst = 0)
                SignExt  = 1'b1;        // Imediato com sinal
                ALUOp    = ALUOP_ADD;
            end

            OP_SLTI: begin
                ALUSrc   = 1'b1;
                RegWrite = 1'b1;
                SignExt  = 1'b1;        // Imediato com sinal
                ALUOp    = ALUOP_SLT;
            end

            OP_SLTIU: begin
                ALUSrc   = 1'b1;
                RegWrite = 1'b1;
                SignExt  = 1'b1;        // Na ISA MIPS, sltiu estende com sinal e compara unsigned
                ALUOp    = ALUOP_SLTU;
            end

            // ----------------------------------------------------------------
            // Tipo-I logico / lui com extensao com ZEROS
            // ----------------------------------------------------------------
            OP_ANDI: begin
                ALUSrc   = 1'b1;
                RegWrite = 1'b1;
                SignExt  = 1'b0;        // Extensao com zeros (bits superiores = 0)
                ALUOp    = ALUOP_AND;
            end

            OP_ORI: begin
                ALUSrc   = 1'b1;
                RegWrite = 1'b1;
                SignExt  = 1'b0;        // Extensao com zeros
                ALUOp    = ALUOP_OR;
            end

            OP_XORI: begin
                ALUSrc   = 1'b1;
                RegWrite = 1'b1;
                SignExt  = 1'b0;        // Extensao com zeros
                ALUOp    = ALUOP_XOR;
            end

            OP_LUI: begin
                ALUSrc   = 1'b1;        // Envia imediato em ula.In2 (ula faz {In2[15:0], 16'b0})
                RegWrite = 1'b1;        // Grava resultado em rt
                SignExt  = 1'b0;        // Extensao com zeros
                ALUOp    = ALUOP_LUI;
            end

            // ----------------------------------------------------------------
            // Tipo-J: j (apenas salto) e jal (salto + salva PC+4 em $31)
            // ----------------------------------------------------------------
            OP_J: begin
                Jump  = 1'b1;           // Seleciona endereco de jump no PC
                ALUOp = ALUOP_IDLE;     // ULA ociosa
            end

            OP_JAL: begin
                RegWrite = 1'b1;        // Grava PC+4 no registrador $ra ($31)
                Jump     = 1'b1;        // Seleciona endereco de jump no PC
                Jal      = 1'b1;        // MUXes gravam PC+4 no registrador 31
                ALUOp    = ALUOP_IDLE;  // ULA ociosa
            end

            // ----------------------------------------------------------------
            // Opcode desconhecido: mantem todas as saidas no padrao seguro
            // ----------------------------------------------------------------
            default: begin
                ALUOp = ALUOP_IDLE;
            end
        endcase
    end

endmodule
