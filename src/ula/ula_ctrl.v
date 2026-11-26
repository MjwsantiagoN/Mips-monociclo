// ============================================================================
// Grupo: BJLM (Brenno, Joao, Leticia, Marcos)
// Atividade: Projeto 02 - 2VA (Implementacao de MIPS Monociclo em Verilog)
// Disciplina: Arquitetura e Organizacao de Computadores
// Semestre letivo: 2026.2
// Arquivo: src/ula/ula_ctrl.v
// Descricao: Unidade de Controle da ULA (decodificacao em dois niveis).
//            Recebe ALUOp (4 bits) da unidade de controle principal (ctrl) e
//            o campo funct (6 bits) da instrucao para gerar o sinal OP (4 bits)
//            que define a operacao executada pela ULA.
// ============================================================================

module ula_ctrl (
    input  wire [3:0] ALUOp,  // Operacao base definida pela unidade de controle (ctrl)
    input  wire [5:0] funct,  // Campo Instruction[5:0] usado nas instrucoes Tipo-R
    output reg  [3:0] OP      // Codigo da operacao enviado para o modulo ula
);

    // Codigos de ALUOp (4 bits para suportar todas as instrucoes Tipo-I do projeto)
    localparam [3:0]
        ALUOP_ADD   = 4'b0000, // lw, sw, addi
        ALUOP_SUB   = 4'b0001, // beq, bne
        ALUOP_RTYPE = 4'b0010, // Instrucoes Tipo-R (decodificacao via funct)
        ALUOP_AND   = 4'b0011, // andi
        ALUOP_OR    = 4'b0100, // ori
        ALUOP_XOR   = 4'b0101, // xori
        ALUOP_SLT   = 4'b0110, // slti
        ALUOP_SLTU  = 4'b0111, // sltiu
        ALUOP_LUI   = 4'b1000, // lui
        ALUOP_IDLE  = 4'b1111; // j, jal (ULA ociosa)

    // Codigos funct oficiais da ISA MIPS para as instrucoes Tipo-R do projeto
    localparam [5:0]
        FUNCT_SLL  = 6'b000000, // 0x00
        FUNCT_SRL  = 6'b000010, // 0x02
        FUNCT_SRA  = 6'b000011, // 0x03
        FUNCT_SLLV = 6'b000100, // 0x04
        FUNCT_SRLV = 6'b000110, // 0x06
        FUNCT_SRAV = 6'b000111, // 0x07
        FUNCT_JR   = 6'b001000, // 0x08
        FUNCT_ADD  = 6'b100000, // 0x20
        FUNCT_SUB  = 6'b100010, // 0x22
        FUNCT_AND  = 6'b100100, // 0x24
        FUNCT_OR   = 6'b100101, // 0x25
        FUNCT_XOR  = 6'b100110, // 0x26
        FUNCT_NOR  = 6'b100111, // 0x27
        FUNCT_SLT  = 6'b101010, // 0x2A
        FUNCT_SLTU = 6'b101011; // 0x2B

    // Codigos de operacao OP reconhecidos pela ULA (devem coincidir com ula.v)
    localparam [3:0]
        OP_AND  = 4'b0000,
        OP_OR   = 4'b0001,
        OP_ADD  = 4'b0010,
        OP_XOR  = 4'b0011,
        OP_SLL  = 4'b0100,
        OP_SRL  = 4'b0101,
        OP_SUB  = 4'b0110,
        OP_SLT  = 4'b0111,
        OP_SLTU = 4'b1000,
        OP_SRA  = 4'b1001,
        OP_LUI  = 4'b1010,
        OP_NOR  = 4'b1100,
        OP_NOP  = 4'b1111;

    // Bloco combinacional de decodificacao em dois niveis (ALUOp -> funct)
    always @(*) begin
        // Padrao seguro para evitar inferencia de latches em estados nao mapeados
        OP = OP_NOP;

        case (ALUOp)
            // Instrucoes Tipo-I e Tipo-J: ALUOp ja define diretamente a operacao
            ALUOP_ADD:  OP = OP_ADD;
            ALUOP_SUB:  OP = OP_SUB;
            ALUOP_AND:  OP = OP_AND;
            ALUOP_OR:   OP = OP_OR;
            ALUOP_XOR:  OP = OP_XOR;
            ALUOP_SLT:  OP = OP_SLT;
            ALUOP_SLTU: OP = OP_SLTU;
            ALUOP_LUI:  OP = OP_LUI;
            ALUOP_IDLE: OP = OP_NOP;

            // Instrucoes Tipo-R (opcode = 0): segundo nivel consulta o campo funct
            ALUOP_RTYPE: begin
                case (funct)
                    FUNCT_ADD:  OP = OP_ADD;
                    FUNCT_SUB:  OP = OP_SUB;
                    FUNCT_AND:  OP = OP_AND;
                    FUNCT_OR:   OP = OP_OR;
                    FUNCT_XOR:  OP = OP_XOR;
                    FUNCT_NOR:  OP = OP_NOR;
                    FUNCT_SLT:  OP = OP_SLT;
                    FUNCT_SLTU: OP = OP_SLTU;
                    FUNCT_SLL,
                    FUNCT_SLLV: OP = OP_SLL;
                    FUNCT_SRL,
                    FUNCT_SRLV: OP = OP_SRL;
                    FUNCT_SRA,
                    FUNCT_SRAV: OP = OP_SRA;
                    FUNCT_JR:   OP = OP_NOP;
                    default:    OP = OP_NOP;
                endcase
            end

            default: OP = OP_NOP;
        endcase
    end

endmodule
