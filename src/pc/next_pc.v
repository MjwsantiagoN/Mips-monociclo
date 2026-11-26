// ============================================================================
// Grupo: BJLM (Brenno, Joao, Leticia, Marcos)
// Atividade: Projeto 02 - 2VA (Implementacao de MIPS Monociclo em Verilog)
// Disciplina: Arquitetura e Organizacao de Computadores
// Semestre letivo: 2026.2
// Arquivo: src/pc/next_pc.v
// Descricao: Logica combinacional do proximo PC e dos desvios/saltos.
//            Calcula PC+4 e escolhe o valor de nextPC (entrada do modulo pc):
//
//              1. PC + 4                                   (padrao)
//              2. PC + 4 + (SignExt(imm) << 2)             (beq / bne tomado)
//              3. {(PC+4)[31:28], address, 2'b00}          (j / jal)
//              4. R[$rs]                                   (jr)
//
//            Prioridade: jr > j/jal > desvio condicional > PC+4.
//
// Decisao de desvio (a ULA faz rs - rt):
//   beq desvia quando (BranchEq &  Zero_flag)
//   bne desvia quando (BranchNE & ~Zero_flag)
//
// Deteccao do jr: a ctrl nao possui sinal proprio para jr; ele e identificado
// aqui por opcode == 0 e funct == 6'h08 (instr[5:0]).
//
// Saida pc_plus4: tambem deve ser usada pelo top-level (mips.v) como dado
// a ser gravado em $31 na instrucao jal (R[31] = PC + 4).
// ============================================================================

module next_pc (                   // Declaracao do modulo next_pc e da lista de portas
    input  wire [31:0] PC,         // PC atual (saida do modulo pc)
    input  wire [31:0] instr,      // Instrucao atual (saida da i_mem)
    input  wire [31:0] ReadData1,  // R[$rs] lido do regfile (alvo do jr)
    input  wire        Zero_flag,  // Flag da ULA (1 quando rs - rt == 0)

    // Sinais de controle vindos da ctrl
    input  wire        BranchEq,   // Instrucao e beq
    input  wire        BranchNE,   // Instrucao e bne
    input  wire        Jump,       // Instrucao e j ou jal

    output wire [31:0] pc_plus4,   // PC + 4 (tambem usado como dado do jal)
    output wire [31:0] nextPC      // Proximo PC (entrada do modulo pc)
);                                 // Fim da lista de portas

    // ------------------------------------------------------------------------
    // Campos da instrucao
    // ------------------------------------------------------------------------
    wire [5:0]  opcode  = instr[31:26];  // Opcode: identifica o tipo da instrucao
    wire [5:0]  funct   = instr[5:0];    // Funct: diferencia as Tipo-R (jr = 0x08)
    wire [15:0] imm     = instr[15:0];   // Imediato do desvio (tipo I)
    wire [25:0] address = instr[25:0];   // Endereco do salto (tipo J)

    // ------------------------------------------------------------------------
    // PC + 4: proxima instrucao sequencial
    // ------------------------------------------------------------------------
    assign pc_plus4 = PC + 32'd4;        // Cada instrucao ocupa 4 bytes

    // ------------------------------------------------------------------------
    // Alvo do desvio: PC + 4 + (SignExt(imm) << 2)
    // O imediato do desvio SEMPRE e estendido com sinal (offset em palavras).
    // ------------------------------------------------------------------------
    wire [31:0] imm_ext       = {{16{imm[15]}}, imm};     // Replica o bit de sinal 16x (extensao com sinal)
    wire [31:0] branch_offset = imm_ext << 2;             // Palavras -> bytes (multiplica por 4)
    wire [31:0] branch_target = pc_plus4 + branch_offset; // Endereco de destino do desvio

    // ------------------------------------------------------------------------
    // Alvo do salto pseudo-absoluto: {(PC+4)[31:28], address, 2'b00}
    // ------------------------------------------------------------------------
    wire [31:0] jump_target = {pc_plus4[31:28], address, 2'b00}; // 4 bits altos + 26 bits + 00

    // ------------------------------------------------------------------------
    // Decisao: desvio tomado? (beq usa Zero_flag = 1, bne usa Zero_flag = 0)
    // ------------------------------------------------------------------------
    wire branch_taken = (BranchEq & Zero_flag) | (BranchNE & ~Zero_flag); // 1 = desvio condicional tomado

    // jr: opcode 0 (Tipo-R) com funct 0x08
    wire is_jr = (opcode == 6'b000000) && (funct == 6'b001000);           // 1 = instrucao e jr

    // ------------------------------------------------------------------------
    // MUX final do proximo PC (prioridade: jr > j/jal > desvio > PC+4)
    // ------------------------------------------------------------------------
    assign nextPC = is_jr        ? ReadData1     :   // jr: PC = R[$rs]
                    Jump         ? jump_target   :   // j / jal: endereco pseudo-absoluto
                    branch_taken ? branch_target :   // beq / bne tomado
                                   pc_plus4;         // caso contrario: sequencial

endmodule                          // Fim do modulo next_pc