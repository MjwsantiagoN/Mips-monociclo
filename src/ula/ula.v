// ============================================================================
// Grupo: BJLM (Brenno, Joao, Leticia, Marcos)
// Atividade: Projeto 02 - 2VA (Implementacao de MIPS Monociclo em Verilog)
// Disciplina: Arquitetura e Organizacao de Computadores
// Semestre letivo: 2026.2
// Arquivo: src/ula/ula.v
// Descricao: Modulo da Unidade Logica e Aritmetica (ULA) combinacional de
//            32 bits do nucleo MIPS monociclo. Executa operacoes aritmeticas,
//            logicas, comparacoes com/sem sinal, deslocamentos e LUI conforme
//            o sinal de controle OP (4 bits) recebido de ula_ctrl.
// ============================================================================

module ula (
    input  wire [31:0] In1,       // Operando 1 ($rs ou shamt estendido nos shifts)
    input  wire [31:0] In2,       // Operando 2 ($rt ou imediato estendido)
    input  wire [3:0]  OP,        // Codigo da operacao fornecido pelo modulo ula_ctrl
    output reg  [31:0] result,    // Resultado da operacao de 32 bits
    output wire        Zero_flag  // Flag em nivel alto (1) quando result == 0
);

    // Definicao dos codigos de operacao de 4 bits (alinhados aos slides da
    // disciplina para AND/OR/ADD/SUB/SLT/NOR e expandidos para o restante da ISA)
    localparam [3:0]
        OP_AND  = 4'b0000, // AND bit a bit (and, andi)
        OP_OR   = 4'b0001, // OR bit a bit (or, ori)
        OP_ADD  = 4'b0010, // Soma de 32 bits (add, addi, lw, sw)
        OP_XOR  = 4'b0011, // XOR bit a bit (xor, xori)
        OP_SLL  = 4'b0100, // Shift logico para esquerda (sll, sllv)
        OP_SRL  = 4'b0101, // Shift logico para direita (srl, srlv)
        OP_SUB  = 4'b0110, // Subtracao de 32 bits (sub, beq, bne)
        OP_SLT  = 4'b0111, // Set on Less Than com sinal (slt, slti)
        OP_SLTU = 4'b1000, // Set on Less Than sem sinal (sltu, sltiu)
        OP_SRA  = 4'b1001, // Shift aritmetico para direita (sra, srav)
        OP_LUI  = 4'b1010, // Load Upper Immediate (lui)
        OP_NOR  = 4'b1100, // NOR bit a bit (nor)
        OP_NOP  = 4'b1111; // Operacao neutra (j, jal, jr ou estado inativo)

    // Bloco combinacional principal: executa a operacao selecionada por OP
    always @(*) begin
        // Inicializacao padrao para evitar inferencia de latches na sintese
        result = 32'b0;

        case (OP)
            // Operacoes logicas bit a bit
            OP_AND:  result = In1 & In2;
            OP_OR:   result = In1 | In2;
            OP_XOR:  result = In1 ^ In2;
            OP_NOR:  result = ~(In1 | In2);

            // Operacoes aritmeticas basicas
            OP_ADD:  result = In1 + In2;
            OP_SUB:  result = In1 - In2;

            // Comparacoes: slt trata operandos em complemento a 2; sltu sem sinal
            OP_SLT:  result = ($signed(In1) < $signed(In2)) ? 32'd1 : 32'd0;
            OP_SLTU: result = (In1 < In2) ? 32'd1 : 32'd0;

            // Deslocamentos: In2 contem o dado ($rt) e In1[4:0] o fator (0..31)
            // O operador >>> sobre operando $signed preserva o bit de sinal
            OP_SLL:  result = In2 << In1[4:0];
            OP_SRL:  result = In2 >> In1[4:0];
            OP_SRA:  result = $signed(In2) >>> In1[4:0];

            // LUI: desloca os 16 bits inferiores de In2 para a metade superior
            OP_LUI:  result = {In2[15:0], 16'b0};

            // Operacao neutra ou codigo nao mapeado
            OP_NOP:  result = 32'b0;
            default: result = 32'b0;
        endcase
    end

    // Saida continua da flag Zero: utilizada pelos desvios condicionais (beq/bne)
    assign Zero_flag = (result == 32'b0);

endmodule
