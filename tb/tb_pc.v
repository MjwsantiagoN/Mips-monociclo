// ============================================================================
// Grupo: BJLM (Brenno, Joao, Leticia, Marcos)
// Atividade: Projeto 02 - 2VA (Implementacao de MIPS Monociclo em Verilog)
// Disciplina: Arquitetura e Organizacao de Computadores
// Semestre letivo: 2026.2
// Arquivo: tb/tb_pc.v
// Descricao: Testbench self-checking do modulo pc (Contador de Programa).
//            Verifica valor inicial, atualizacao apenas na borda de subida
//            do clock e carga de enderecos arbitrarios (desvio/salto).
//
// Como rodar localmente (Icarus Verilog):
//   iverilog -Wall -o sim_pc.vvp src/pc/pc.v tb/tb_pc.v
//   vvp sim_pc.vvp
// ============================================================================

module tb_pc;                          // Testbench nao tem portas: ele gera os estimulos

    // ------------------------------------------------------------------------
    // Sinais ligados ao modulo sob teste (DUT)
    // ------------------------------------------------------------------------
    reg         clock;                 // Clock gerado manualmente pelo testbench
    reg  [31:0] nextPC;                // Proximo PC fornecido ao DUT (estimulo)
    wire [31:0] PC;                    // Saida do DUT (valor atual do PC)

    // ------------------------------------------------------------------------
    // Contadores de resultado
    // ------------------------------------------------------------------------
    integer total_tests;               // Quantidade total de verificacoes feitas
    integer failed_tests;              // Quantidade de verificacoes que falharam

    // Instancia o modulo sob teste ligando cada porta ao sinal de mesmo nome
    pc dut (.clock(clock), .nextPC(nextPC), .PC(PC));

    // ------------------------------------------------------------------------
    // Tarefa auxiliar: compara a saida do PC com o valor esperado
    // ------------------------------------------------------------------------
    task check(input [31:0] esperado, input [255:0] nome);  // esperado = valor correto; nome = texto do teste
        begin                                               // Inicio do corpo da tarefa
            total_tests = total_tests + 1;                  // Conta mais uma verificacao
            if (PC === esperado)                            // '===' tambem compara x/z (comparacao exata)
                $display("[PASS] %0s: PC = 0x%08h", nome, PC);   // Passou: mostra o valor
            else begin                                      // Caso contrario, o teste falhou
                failed_tests = failed_tests + 1;            // Conta a falha
                $display("[FAIL] %0s: PC = 0x%08h (esperado 0x%08h)", nome, PC, esperado); // Mostra obtido x esperado
            end                                             // Fim do ramo de falha
        end                                                 // Fim do corpo da tarefa
    endtask                                                 // Fim da tarefa check

    // ------------------------------------------------------------------------
    // Sequencia de testes
    // ------------------------------------------------------------------------
    initial begin                      // Bloco executado uma unica vez, no inicio da simulacao
        total_tests = 0;               // Zera o contador de verificacoes
        failed_tests = 0;              // Zera o contador de falhas
        clock  = 1'b0;                 // Clock comeca em nivel baixo
        nextPC = 32'h00000004;         // Primeiro valor a ser carregado no PC

        // 1) Valor inicial deve ser 0, antes de qualquer borda de subida
        #1 check(32'h00000000, "valor inicial");            // Espera 1 unidade de tempo e confere

        // 2) Mudar nextPC sem clock NAO deve alterar o PC
        #4 check(32'h00000000, "sem clock, PC nao muda");   // Passa tempo sem subir o clock

        // 3) Borda de subida carrega nextPC
        clock = 1'b1; #1;              // Sobe o clock e espera 1 unidade de tempo
        check(32'h00000004, "borda de subida carrega 0x4"); // PC deve ter recebido 0x4

        // 4) Borda de descida NAO deve alterar o PC
        nextPC = 32'h00000008;         // Muda o proximo PC, mas o clock ainda nao sobe
        clock = 1'b0; #1;              // Desce o clock
        check(32'h00000004, "borda de descida nao altera"); // PC continua em 0x4

        // 5) Nova borda de subida
        clock = 1'b1; #1;              // Sobe o clock: agora o PC deve receber 0x8
        check(32'h00000008, "segunda borda carrega 0x8");   // Confere o novo valor

        // 6) Endereco alto arbitrario (ex.: alvo de salto)
        clock = 1'b0; nextPC = 32'h0040_00A0; #1;   // Desce o clock e prepara o novo endereco
        clock = 1'b1; #1;                           // Sobe o clock: carrega o endereco
        check(32'h004000A0, "carga de endereco de salto");  // Confere o endereco alto

        // 7) Endereco menor (desvio para tras)
        clock = 1'b0; nextPC = 32'h00000010; #1;    // Desce o clock e prepara endereco menor
        clock = 1'b1; #1;                           // Sobe o clock: carrega o endereco
        check(32'h00000010, "desvio para tras");    // Confere o endereco menor

        // Resumo final da simulacao
        $display("----------------------------------------");                    // Linha separadora
        $display("tb_pc: %0d testes, %0d falhas", total_tests, failed_tests);    // Mostra totais
        if (failed_tests == 0) $display("RESULTADO: TODOS OS TESTES PASSARAM");   // Nenhuma falha
        else                   $display("RESULTADO: HA FALHAS");                  // Pelo menos uma falha
        $finish;                       // Encerra a simulacao
    end                                // Fim do bloco initial

endmodule                              // Fim do testbench tb_pc