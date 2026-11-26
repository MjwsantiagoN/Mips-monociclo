// ============================================================================
// Grupo: BJLM (Brenno, Joao, Leticia, Marcos)
// Atividade: Projeto 02 - 2VA (Implementacao de MIPS Monociclo em Verilog)
// Disciplina: Arquitetura e Organizacao de Computadores
// Semestre letivo: 2026.2
// Arquivo: tb/tb_next_pc.v
// Descricao: Testbench self-checking do modulo next_pc (logica de desvios e
//            saltos). Cobre PC+4, beq/bne tomado e nao tomado (offset positivo
//            e negativo), j, jal (pc_plus4 para $31), jr e a prioridade entre
//            as fontes do proximo PC.
//
// Como rodar localmente (Icarus Verilog):
//   iverilog -Wall -o sim_next_pc.vvp src/pc/next_pc.v tb/tb_next_pc.v
//   vvp sim_next_pc.vvp
// ============================================================================

module tb_next_pc;                     // Testbench nao tem portas: ele gera os estimulos

    // ------------------------------------------------------------------------
    // Sinais de entrada do DUT (controlados pelo testbench)
    // ------------------------------------------------------------------------
    reg  [31:0] PC, instr, ReadData1;  // PC atual, instrucao atual e R[$rs]
    reg         Zero_flag;             // Flag Zero vinda da ULA
    reg         BranchEq, BranchNE;    // Sinais de controle de desvio (beq / bne)
    reg         Jump;                  // Sinal de controle de salto (j / jal)

    // ------------------------------------------------------------------------
    // Sinais de saida do DUT (observados pelo testbench)
    // ------------------------------------------------------------------------
    wire [31:0] pc_plus4;              // PC + 4
    wire [31:0] nextPC;                // Proximo PC escolhido

    // ------------------------------------------------------------------------
    // Contadores de resultado
    // ------------------------------------------------------------------------
    integer total_tests;               // Quantidade total de verificacoes feitas
    integer failed_tests;              // Quantidade de verificacoes que falharam

    // Instancia o modulo sob teste ligando cada porta ao sinal de mesmo nome
    next_pc dut (
        .PC(PC), .instr(instr), .ReadData1(ReadData1), .Zero_flag(Zero_flag),  // Entradas de dados
        .BranchEq(BranchEq), .BranchNE(BranchNE), .Jump(Jump),                 // Entradas de controle
        .pc_plus4(pc_plus4), .nextPC(nextPC)                                   // Saidas
    );                                 // Fim da instanciacao

    // ------------------------------------------------------------------------
    // Tarefa auxiliar: aplica um estimulo e confere nextPC
    // ------------------------------------------------------------------------
    task run(
        input [31:0]  pc_v,            // Valor do PC atual
        input [31:0]  instr_v,         // Instrucao atual
        input [31:0]  rs_v,            // Valor de R[$rs] (ReadData1)
        input         zero_v,          // Valor de Zero_flag
        input         beq_v,           // Valor de BranchEq
        input         bne_v,           // Valor de BranchNE
        input         jmp_v,           // Valor de Jump
        input [31:0]  esperado,        // nextPC que deve ser produzido
        input [255:0] nome             // Texto descritivo do teste
    );                                 // Fim da lista de argumentos da tarefa
        begin                          // Inicio do corpo da tarefa
            // Aplica todos os estimulos nas entradas do DUT
            PC = pc_v; instr = instr_v; ReadData1 = rs_v; Zero_flag = zero_v;
            BranchEq = beq_v; BranchNE = bne_v; Jump = jmp_v;
            #1;                                             // Espera a logica combinacional estabilizar
            total_tests = total_tests + 1;                  // Conta mais uma verificacao
            if (nextPC === esperado)                        // '===' tambem compara x/z (comparacao exata)
                $display("[PASS] %0s: nextPC = 0x%08h", nome, nextPC);   // Passou: mostra o valor
            else begin                                      // Caso contrario, o teste falhou
                failed_tests = failed_tests + 1;            // Conta a falha
                $display("[FAIL] %0s: nextPC = 0x%08h (esperado 0x%08h)", nome, nextPC, esperado); // Obtido x esperado
            end                                             // Fim do ramo de falha
        end                                                 // Fim do corpo da tarefa
    endtask                                                 // Fim da tarefa run

    // ------------------------------------------------------------------------
    // Instrucoes de exemplo (campos: opcode | rs | rt | imm / address / funct)
    // ------------------------------------------------------------------------
    localparam [31:0] ADD_INSTR  = 32'b000000_01000_01001_01010_00000_100000; // add $t2,$t0,$t1 (Tipo-R, funct 0x20)
    localparam [31:0] BEQ_P3     = {6'b000100, 5'd8, 5'd9, 16'd3};            // beq $t0,$t1 com offset +3
    localparam [31:0] BEQ_M2     = {6'b000100, 5'd8, 5'd9, 16'hFFFE};         // beq $t0,$t1 com offset -2
    localparam [31:0] BNE_P3     = {6'b000101, 5'd8, 5'd9, 16'd3};            // bne $t0,$t1 com offset +3
    localparam [31:0] BNE_M1     = {6'b000101, 5'd8, 5'd9, 16'hFFFF};         // bne $t0,$t1 com offset -1
    localparam [31:0] J_0x100    = {6'b000010, 26'h0000040};                  // j 0x100 (address = 0x40, x4 = 0x100)
    localparam [31:0] JAL_0x200  = {6'b000011, 26'h0000080};                  // jal 0x200 (address = 0x80, x4 = 0x200)
    localparam [31:0] JR_T0      = {6'b000000, 5'd8, 15'd0, 6'b001000};       // jr $t0 (funct 0x08)
    localparam [31:0] J_HIGH     = {6'b000010, 26'h0000010};                  // j com address 0x10 (usado em PCs de outra regiao)

    // ------------------------------------------------------------------------
    // Sequencia de testes
    // ------------------------------------------------------------------------
    initial begin                      // Bloco executado uma unica vez, no inicio da simulacao
        total_tests = 0;               // Zera o contador de verificacoes
        failed_tests = 0;              // Zera o contador de falhas

        // ---- Fluxo sequencial ------------------------------------------------
        run(32'h0, ADD_INSTR, 32'h0, 1'b0, 1'b0, 1'b0, 1'b0, 32'h4,   "tipo-R: PC+4");                     // Sem desvio: PC+4
        run(32'h8, ADD_INSTR, 32'h0, 1'b1, 1'b0, 1'b0, 1'b0, 32'hC,   "Zero_flag sem Branch nao desvia");  // Zero alto, mas Branch = 0

        // ---- beq -------------------------------------------------------------
        // alvo = PC+4 + (3<<2) = 0x10+4+12 = 0x20
        run(32'h10, BEQ_P3, 32'h0, 1'b1, 1'b1, 1'b0, 1'b0, 32'h20,    "beq tomado (+3)");     // Iguais (Zero = 1): desvia
        run(32'h10, BEQ_P3, 32'h0, 1'b0, 1'b1, 1'b0, 1'b0, 32'h14,    "beq nao tomado");      // Diferentes (Zero = 0): segue em PC+4
        // alvo = 0x20+4 + (-2<<2) = 0x24 - 8 = 0x1C
        run(32'h20, BEQ_M2, 32'h0, 1'b1, 1'b1, 1'b0, 1'b0, 32'h1C,    "beq tomado (-2)");     // Offset negativo: desvia para tras

        // ---- bne -------------------------------------------------------------
        run(32'h10, BNE_P3, 32'h0, 1'b0, 1'b0, 1'b1, 1'b0, 32'h20,    "bne tomado (+3)");     // Diferentes (Zero = 0): desvia
        run(32'h10, BNE_P3, 32'h0, 1'b1, 1'b0, 1'b1, 1'b0, 32'h14,    "bne nao tomado");      // Iguais (Zero = 1): segue em PC+4
        // alvo = 0x30+4 + (-1<<2) = 0x30 (laco para si mesmo)
        run(32'h30, BNE_M1, 32'h0, 1'b0, 1'b0, 1'b1, 1'b0, 32'h30,    "bne tomado (-1, laco)"); // Desvia para a propria instrucao

        // ---- j / jal ---------------------------------------------------------
        run(32'h0,  J_0x100,   32'h0, 1'b0, 1'b0, 1'b0, 1'b1, 32'h100, "j 0x100");     // Salto simples
        run(32'h20, JAL_0x200, 32'h0, 1'b0, 1'b0, 1'b0, 1'b1, 32'h200, "jal 0x200");   // Salto com link
        // pc_plus4 e o valor a ser gravado em $31 no jal
        total_tests = total_tests + 1;                      // Conta esta verificacao manual
        if (pc_plus4 === 32'h24) $display("[PASS] jal: pc_plus4 = 0x%08h (link em $31)", pc_plus4); // 0x20 + 4 = 0x24
        else begin                                          // Caso contrario, o teste falhou
            failed_tests = failed_tests + 1;                // Conta a falha
            $display("[FAIL] jal: pc_plus4 = 0x%08h (esperado 0x00000024)", pc_plus4); // Mostra obtido x esperado
        end                                                 // Fim do ramo de falha
        // 4 bits superiores vem de PC+4: 0x1000_0000 + 0x40 = 0x1000_0040
        run(32'h1000_0000, J_HIGH, 32'h0, 1'b0, 1'b0, 1'b0, 1'b1, 32'h1000_0040, "j usa 4 bits altos de PC+4");
        // Borda de regiao: PC = 0x0FFF_FFFC -> PC+4 = 0x1000_0000 (regiao 0x1...)
        run(32'h0FFF_FFFC, J_HIGH, 32'h0, 1'b0, 1'b0, 1'b0, 1'b1, 32'h1000_0040, "j na fronteira de regiao");

        // ---- jr --------------------------------------------------------------
        run(32'h40, JR_T0, 32'h0000_0080, 1'b0, 1'b0, 1'b0, 1'b0, 32'h80, "jr $t0 (R[rs] = 0x80)"); // PC recebe R[$rs]

        // ---- Prioridades / robustez -----------------------------------------
        // Desvio tomado nao deve ser afetado pelo ReadData1
        run(32'h10, BEQ_P3, 32'hDEAD_BEEF, 1'b1, 1'b1, 1'b0, 1'b0, 32'h20, "beq ignora ReadData1");
        // add com funct != 0x08 nao e jr, mesmo com ReadData1 arbitrario
        run(32'h0, ADD_INSTR, 32'h0000_0080, 1'b0, 1'b0, 1'b0, 1'b0, 32'h4, "add nao e confundido com jr");
        // jr tem prioridade mesmo que Zero_flag alto
        run(32'h40, JR_T0, 32'h0000_0080, 1'b1, 1'b0, 1'b0, 1'b0, 32'h80, "jr com Zero_flag alto");

        // Resumo final da simulacao
        $display("----------------------------------------");                         // Linha separadora
        $display("tb_next_pc: %0d testes, %0d falhas", total_tests, failed_tests);   // Mostra totais
        if (failed_tests == 0) $display("RESULTADO: TODOS OS TESTES PASSARAM");        // Nenhuma falha
        else                   $display("RESULTADO: HA FALHAS");                       // Pelo menos uma falha
        $finish;                       // Encerra a simulacao
    end                                // Fim do bloco initial

endmodule                              // Fim do testbench tb_next_pc