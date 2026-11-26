// ============================================================================
// Grupo: BJLM (Brenno, Joao, Leticia, Marcos)
// Atividade: Projeto 02 - 2VA (Implementacao de MIPS Monociclo em Verilog)
// Disciplina: Arquitetura e Organizacao de Computadores
// Semestre letivo: 2026.2
// Arquivo: src/pc/pc.v
// Descricao: Contador de Programa (PC). Registrador de 32 bits sincrono que
//            guarda o endereco (em bytes) da instrucao atual. A cada borda de
//            subida do clock, o PC recebe o valor calculado em nextPC (PC+4,
//            endereco de desvio, de salto ou de jr, escolhido pelo modulo
//            next_pc). A saida PC endereca a memoria de instrucao (i_mem).
//
// Sinais (conforme enunciado):
//   clock  (entrada, 1 bit)  - atualiza o PC na borda de subida
//   nextPC (entrada, 32 bit) - valor a ser escrito no PC
//   PC     (saida,   32 bit) - valor armazenado no PC
// ============================================================================

module pc (                        // Declaracao do modulo pc e da lista de portas
    input  wire        clock,      // Atualiza o PC na borda de subida
    input  wire [31:0] nextPC,     // Proximo valor do PC (vem do modulo next_pc)
    output reg  [31:0] PC          // Endereco da instrucao atual (vai para i_mem)
);                                 // Fim da lista de portas

    // Valor inicial: a execucao comeca no endereco 0 (primeira linha do
    // instruction.list). Sem isso o PC comecaria em 'x' na simulacao e
    // nunca se recuperaria, pois nextPC = PC + 4 tambem seria 'x'.
    initial begin                  // Bloco executado uma unica vez, no inicio da simulacao
        PC = 32'h00000000;         // Endereco 0 = primeira instrucao do programa
    end                            // Fim do bloco initial

    // Registrador sincrono: um novo PC a cada ciclo de clock
    always @(posedge clock) begin  // Dispara somente na borda de subida do clock
        PC <= nextPC;              // Guarda o proximo endereco (atribuicao nao-bloqueante)
    end                            // Fim do bloco always

endmodule                          // Fim do modulo pc