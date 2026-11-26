// ============================================================================
// Grupo: BJLM (Brenno, Joao, Leticia, Marcos)
// Atividade: Projeto 02 - 2VA (Implementacao de MIPS Monociclo em Verilog)
// Disciplina: Arquitetura e Organizacao de Computadores
// Semestre letivo: 2026.2
// Arquivo: src/mips.v
// Descricao: Nucleo MIPS monociclo (top-level). Integra pc, next_pc, i_mem,
//            ctrl, regfile, ula_ctrl, ula e d_mem, alem dos MUXes e da
//            extensao de imediato. Interface: clock e reset (entradas);
//            PC atual, saida da ULA e saida da memoria de dados (saidas).
//
// Pontos de integracao que a ctrl NAO resolve sozinha (tratados aqui):
//   - jr  : detectado por opcode = 0 e funct = 0x08; bloqueia RegWrite
//           (o PC e carregado com R[$rs] dentro do next_pc).
//   - jal : ctrl nao seleciona $31; usa-se o sinal Jal para forcar o
//           registrador de destino 31 e gravar PC+4.
//   - sll/srl/sra : o fator de deslocamento (shamt) entra em In1 da ULA.
//   - reset: o pc nao possui reset (conforme enunciado); enquanto reset = 1
//           o nextPC e forcado a 0 para o programa comecar na instrucao 0.
// ============================================================================

module mips #(
    parameter I_DEPTH   = 256,                 // Numero de palavras da i_mem
    parameter D_DEPTH   = 256,                 // Numero de palavras da d_mem
    parameter INIT_FILE = "instruction.list"   // Programa (binario, 1 instrucao/linha)
) (
    input  wire        clock,     // Clock do processador
    input  wire        reset,     // Reset (zera o regfile e segura o PC em 0)
    output wire [31:0] pc_out,    // Valor atual do PC
    output wire [31:0] ula_out,   // Valor atual da saida da ULA
    output wire [31:0] dmem_out   // Valor atual da saida da memoria de dados
);

    // ------------------------------------------------------------------
    // Fios internos
    // ------------------------------------------------------------------
    wire [31:0] PC, nextPC, pc_plus4;      // Contador de programa
    wire [31:0] instr;                     // Instrucao atual
    wire [31:0] rd1, rd2;                  // Leituras do regfile
    wire [31:0] imm_ext;                   // Imediato estendido
    wire [31:0] ula_in1, ula_in2;          // Operandos da ULA
    wire [31:0] ula_result;                // Resultado da ULA
    wire [3:0]  ula_op;                    // Operacao enviada a ULA (ula_ctrl)
    wire        zero;                      // Zero_flag da ULA
    wire [31:0] dmem_rdata;                // Dado lido da d_mem
    wire [31:0] wb_data;                   // Dado escrito no regfile
    wire [4:0]  wr_addr;                   // Registrador de destino

    // Sinais de controle (ctrl)
    wire       RegDst, ALUSrc, MemtoReg, RegWrite, MemRead, MemWrite;
    wire       BranchEq, BranchNE, Jump, Jal, SignExt;
    wire [3:0] ALUOp;

    // Campos da instrucao
    wire [5:0]  opcode = instr[31:26];
    wire [4:0]  rs     = instr[25:21];
    wire [4:0]  rt     = instr[20:16];
    wire [4:0]  rd     = instr[15:11];
    wire [4:0]  shamt  = instr[10:6];
    wire [5:0]  funct  = instr[5:0];
    wire [15:0] imm    = instr[15:0];

    // Deteccoes baseadas em opcode/funct
    wire is_rtype = (opcode == 6'b000000);
    wire is_jr    = is_rtype && (funct == 6'h08);                        // jr
    wire is_shamt = is_rtype && (funct == 6'h00 || funct == 6'h02 ||
                                 funct == 6'h03);                        // sll, srl, sra

    // ------------------------------------------------------------------
    // Busca de instrucao: PC -> i_mem
    // ------------------------------------------------------------------
    pc u_pc (
        .clock  (clock),
        .nextPC (reset ? 32'h00000000 : nextPC),   // reset segura o PC em 0
        .PC     (PC)
    );

    i_mem #(.DEPTH(I_DEPTH), .INIT_FILE(INIT_FILE)) u_i_mem (
        .address (PC),
        .i_out   (instr)
    );

    // ------------------------------------------------------------------
    // Unidade de controle
    // ------------------------------------------------------------------
    ctrl u_ctrl (
        .opcode   (opcode),
        .RegDst   (RegDst),
        .ALUSrc   (ALUSrc),
        .MemtoReg (MemtoReg),
        .RegWrite (RegWrite),
        .MemRead  (MemRead),
        .MemWrite (MemWrite),
        .BranchEq (BranchEq),
        .BranchNE (BranchNE),
        .Jump     (Jump),
        .Jal      (Jal),
        .SignExt  (SignExt),
        .ALUOp    (ALUOp)
    );

    // ------------------------------------------------------------------
    // Banco de registradores
    //   destino : jal -> $31 | RegDst=1 -> rd | RegDst=0 -> rt
    //   dado    : jal -> PC+4 | MemtoReg=1 -> d_mem | senao ULA
    //   jr nao escreve em registrador
    // ------------------------------------------------------------------
    assign wr_addr = Jal ? 5'd31 : (RegDst ? rd : rt);
    assign wb_data = Jal ? pc_plus4 : (MemtoReg ? dmem_rdata : ula_result);

    regfile u_regfile (
        .Clock     (clock),
        .Reset     (reset),
        .RegWrite  (RegWrite & ~is_jr),
        .ReadAddr1 (rs),
        .ReadAddr2 (rt),
        .WriteAddr (wr_addr),
        .WriteData (wb_data),
        .ReadData1 (rd1),
        .ReadData2 (rd2)
    );

    // ------------------------------------------------------------------
    // Extensao do imediato: SignExt = 1 (sinal) | 0 (zeros)
    // ------------------------------------------------------------------
    assign imm_ext = SignExt ? {{16{imm[15]}}, imm} : {16'h0000, imm};

    // ------------------------------------------------------------------
    // ULA
    //   In1: $rs ou shamt (sll/srl/sra)    In2: $rt ou imediato (ALUSrc)
    // ------------------------------------------------------------------
    assign ula_in1 = is_shamt ? {27'b0, shamt} : rd1;
    assign ula_in2 = ALUSrc   ? imm_ext        : rd2;

    ula_ctrl u_ula_ctrl (
        .ALUOp (ALUOp),
        .funct (funct),
        .OP    (ula_op)
    );

    ula u_ula (
        .In1       (ula_in1),
        .In2       (ula_in2),
        .OP        (ula_op),
        .result    (ula_result),
        .Zero_flag (zero)
    );

    // ------------------------------------------------------------------
    // Memoria de dados (endereco = saida da ULA, dado = $rt)
    // ------------------------------------------------------------------
    d_mem #(.DEPTH(D_DEPTH)) u_d_mem (
        .Clock     (clock),
        .Address   (ula_result),
        .WriteData (rd2),
        .MemWrite  (MemWrite),
        .MemRead   (MemRead),
        .ReadData  (dmem_rdata)
    );

    // ------------------------------------------------------------------
    // Proximo PC: PC+4, desvio, j/jal ou jr
    // ------------------------------------------------------------------
    next_pc u_next_pc (
        .PC        (PC),
        .instr     (instr),
        .ReadData1 (rd1),
        .Zero_flag (zero),
        .BranchEq  (BranchEq),
        .BranchNE  (BranchNE),
        .Jump      (Jump),
        .pc_plus4  (pc_plus4),
        .nextPC    (nextPC)
    );

    // ------------------------------------------------------------------
    // Saidas do top-level
    // ------------------------------------------------------------------
    assign pc_out   = PC;
    assign ula_out  = ula_result;
    assign dmem_out = dmem_rdata;

endmodule
