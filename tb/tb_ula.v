// ============================================================================
// Grupo: BJLM (Brenno, Joao, Leticia, Marcos)
// Atividade: Projeto 02 - 2VA (Implementacao de MIPS Monociclo em Verilog)
// Disciplina: Arquitetura e Organizacao de Computadores
// Semestre letivo: 2026.2
// Arquivo: tb/tb_ula.v
// Descricao: Testbench automatizado (self-checking) para validar os modulos
//            ula_ctrl e ula integrados em conjunto, cobrindo todas as
//            instrucoes Tipo-R, Tipo-I e Tipo-J do subconjunto ISA e casos
//            criticos de borda (sinal, shifts, overflow e Zero_flag).
// ============================================================================

module tb_ula;

    // Entradas estimuladas pelo testbench
    reg  [3:0]  ALUOp;
    reg  [5:0]  funct;
    reg  [31:0] In1;
    reg  [31:0] In2;

    // Fio intermediario e saidas observadas da ULA
    wire [3:0]  OP;
    wire [31:0] result;
    wire        Zero_flag;

    // Contadores de resultados dos testes
    integer total_tests;
    integer passed_tests;
    integer failed_tests;

    // Codigos de ALUOp (devem espelhar ula_ctrl.v)
    localparam [3:0]
        ALUOP_ADD   = 4'b0000,
        ALUOP_SUB   = 4'b0001,
        ALUOP_RTYPE = 4'b0010,
        ALUOP_AND   = 4'b0011,
        ALUOP_OR    = 4'b0100,
        ALUOP_XOR   = 4'b0101,
        ALUOP_SLT   = 4'b0110,
        ALUOP_SLTU  = 4'b0111,
        ALUOP_LUI   = 4'b1000,
        ALUOP_IDLE  = 4'b1111;

    // Codigos funct Tipo-R (ISA MIPS)
    localparam [5:0]
        FUNCT_SLL  = 6'b000000,
        FUNCT_SRL  = 6'b000010,
        FUNCT_SRA  = 6'b000011,
        FUNCT_SLLV = 6'b000100,
        FUNCT_SRLV = 6'b000110,
        FUNCT_SRAV = 6'b000111,
        FUNCT_JR   = 6'b001000,
        FUNCT_ADD  = 6'b100000,
        FUNCT_SUB  = 6'b100010,
        FUNCT_AND  = 6'b100100,
        FUNCT_OR   = 6'b100101,
        FUNCT_XOR  = 6'b100110,
        FUNCT_NOR  = 6'b100111,
        FUNCT_SLT  = 6'b101010,
        FUNCT_SLTU = 6'b101011;

    // Instanciacao da Unidade de Controle da ULA
    ula_ctrl dut_ctrl (
        .ALUOp (ALUOp),
        .funct (funct),
        .OP    (OP)
    );

    // Instanciacao da ULA conectada a saida OP de ula_ctrl
    ula dut_ula (
        .In1       (In1),
        .In2       (In2),
        .OP        (OP),
        .result    (result),
        .Zero_flag (Zero_flag)
    );

    // Tarefa auxiliar para aplicar estimulos e validar saida + Zero_flag
    task check_case;
        input [8*24-1:0] test_name;
        input [3:0]      t_aluop;
        input [5:0]      t_funct;
        input [31:0]     t_in1;
        input [31:0]     t_in2;
        input [31:0]     exp_result;
        input            exp_zero;
        begin
            ALUOp = t_aluop;
            funct = t_funct;
            In1   = t_in1;
            In2   = t_in2;
            #10; // Aguarda propagacao combinacional

            total_tests = total_tests + 1;
            if (result === exp_result && Zero_flag === exp_zero) begin
                passed_tests = passed_tests + 1;
                $display("[PASS] %0s | OP=%b | result=0x%08h | Zero=%b",
                         test_name, OP, result, Zero_flag);
            end else begin
                failed_tests = failed_tests + 1;
                $display("[FAIL] %0s | OP=%b | obtido=(0x%08h, Z=%b) | esperado=(0x%08h, Z=%b)",
                         test_name, OP, result, Zero_flag, exp_result, exp_zero);
            end
        end
    endtask

    initial begin
        // Gera arquivo de formas de onda para visualizacao opcional no GTKWave
        $dumpfile("sim_ula.vcd");
        $dumpvars(0, tb_ula);

        total_tests  = 0;
        passed_tests = 0;
        failed_tests = 0;

        $display("====================================================================");
        $display(" INICIO DOS TESTES - ULA + ULA_CTRL (GRUPO BJLM - MIPS MONOCICLO)");
        $display("====================================================================");

        // --------------------------------------------------------------------
        // 1. INSTRUCOES TIPO-R (ALUOp = ALUOP_RTYPE)
        // --------------------------------------------------------------------
        check_case("R.1  add",          ALUOP_RTYPE, FUNCT_ADD,  32'd15,         32'd27,         32'd42,         1'b0);
        check_case("R.1  add zero",     ALUOP_RTYPE, FUNCT_ADD,  32'hFFFFFFFF,   32'd1,          32'h00000000,   1'b1);
        check_case("R.2  sub",          ALUOP_RTYPE, FUNCT_SUB,  32'd50,         32'd18,         32'd32,         1'b0);
        check_case("R.2  sub zero",     ALUOP_RTYPE, FUNCT_SUB,  32'd99,         32'd99,         32'd0,          1'b1);
        check_case("R.3  and",          ALUOP_RTYPE, FUNCT_AND,  32'hFF00FF00,   32'h0F0F0F0F,   32'h0F000F00,   1'b0);
        check_case("R.4  or",           ALUOP_RTYPE, FUNCT_OR,   32'hF0000000,   32'h0000000F,   32'hF000000F,   1'b0);
        check_case("R.5  xor",          ALUOP_RTYPE, FUNCT_XOR,  32'hAAAAAAAA,   32'hFFFFFFFF,   32'h55555555,   1'b0);
        check_case("R.5  xor zero",     ALUOP_RTYPE, FUNCT_XOR,  32'h12345678,   32'h12345678,   32'h00000000,   1'b1);
        check_case("R.6  nor",          ALUOP_RTYPE, FUNCT_NOR,  32'h0000FFFF,   32'h00000000,   32'hFFFF0000,   1'b0);

        // Comparacao com sinal vs sem sinal (caso critico: -1 vs +1)
        check_case("R.7  slt (-1 < 1)", ALUOP_RTYPE, FUNCT_SLT,  32'hFFFFFFFF,   32'd1,          32'd1,          1'b0);
        check_case("R.7  slt (1 < -1)", ALUOP_RTYPE, FUNCT_SLT,  32'd1,          32'hFFFFFFFF,   32'd0,          1'b1);
        check_case("R.8  sltu (-1<1)",  ALUOP_RTYPE, FUNCT_SLTU, 32'hFFFFFFFF,   32'd1,          32'd0,          1'b1);
        check_case("R.8  sltu (1<-1)",  ALUOP_RTYPE, FUNCT_SLTU, 32'd1,          32'hFFFFFFFF,   32'd1,          1'b0);

        // Deslocamentos por shamt e por registrador (In1[4:0] = qtd, In2 = dado)
        check_case("R.9  sll (<<4)",    ALUOP_RTYPE, FUNCT_SLL,  32'd4,          32'h0000000F,   32'h000000F0,   1'b0);
        check_case("R.9  sll (<<0)",    ALUOP_RTYPE, FUNCT_SLL,  32'd0,          32'h12345678,   32'h12345678,   1'b0);
        check_case("R.10 srl (>>4)",    ALUOP_RTYPE, FUNCT_SRL,  32'd4,          32'h80000000,   32'h08000000,   1'b0);
        check_case("R.11 sra (>>>4)",   ALUOP_RTYPE, FUNCT_SRA,  32'd4,          32'h80000000,   32'hF8000000,   1'b0);
        check_case("R.11 sra pos",      ALUOP_RTYPE, FUNCT_SRA,  32'd4,          32'h40000000,   32'h04000000,   1'b0);
        check_case("R.12 sllv (mod32)", ALUOP_RTYPE, FUNCT_SLLV, 32'd33,         32'h00000003,   32'h00000006,   1'b0);
        check_case("R.13 srlv (>>8)",   ALUOP_RTYPE, FUNCT_SRLV, 32'd8,          32'hF0000000,   32'h00F00000,   1'b0);
        check_case("R.14 srav (>>>8)",  ALUOP_RTYPE, FUNCT_SRAV, 32'd8,          32'hF0000000,   32'hFFF00000,   1'b0);
        check_case("R.15 jr (idle)",    ALUOP_RTYPE, FUNCT_JR,   32'h00400020,   32'd0,          32'h00000000,   1'b1);

        // --------------------------------------------------------------------
        // 2. INSTRUCOES TIPO-I e TIPO-J
        // --------------------------------------------------------------------
        check_case("I.1  addi",         ALUOP_ADD,   6'b000000,  32'd100,        32'hFFFFFFFC,   32'd96,         1'b0);
        check_case("I.2  andi",         ALUOP_AND,   6'b000000,  32'h1234ABCD,   32'h000000FF,   32'h000000CD,   1'b0);
        check_case("I.3  ori",          ALUOP_OR,    6'b000000,  32'h12340000,   32'h00005678,   32'h12345678,   1'b0);
        check_case("I.4  xori",         ALUOP_XOR,   6'b000000,  32'h0000FFFF,   32'h00000F0F,   32'h0000F0F0,   1'b0);
        check_case("I.5  beq (eq)",     ALUOP_SUB,   6'b000000,  32'd42,         32'd42,         32'd0,          1'b1);
        check_case("I.6  bne (neq)",    ALUOP_SUB,   6'b000000,  32'd42,         32'd10,         32'd32,         1'b0);
        check_case("I.7  slti (-5<-2)", ALUOP_SLT,   6'b000000,  32'hFFFFFFFB,   32'hFFFFFFFE,   32'd1,          1'b0);
        check_case("I.8  sltiu",        ALUOP_SLTU,  6'b000000,  32'd10,         32'hFFFFFFFF,   32'd1,          1'b0);
        check_case("I.9  lui",          ALUOP_LUI,   6'b000000,  32'd0,          32'h0000ABCD,   32'hABCD0000,   1'b0);
        check_case("I.10 lw addr",      ALUOP_ADD,   6'b000000,  32'h10010000,   32'd16,         32'h10010010,   1'b0);
        check_case("I.11 sw addr",      ALUOP_ADD,   6'b000000,  32'h10010000,   32'd24,         32'h10010018,   1'b0);
        check_case("J.1/2 j/jal idle",  ALUOP_IDLE,  6'b000000,  32'd123,        32'd456,        32'd0,          1'b1);

        // --------------------------------------------------------------------
        // 3. CASOS DE SEGURANCA (ENTRADAS NAO MAPEADAS)
        // --------------------------------------------------------------------
        check_case("SAFE funct inv",    ALUOP_RTYPE, 6'b111111,  32'd10,         32'd20,         32'd0,          1'b1);
        check_case("SAFE aluop inv",    4'b1011,     6'b000000,  32'd10,         32'd20,         32'd0,          1'b1);

        $display("====================================================================");
        $display(" RESUMO: %0d/%0d testes passaram | %0d falhas",
                 passed_tests, total_tests, failed_tests);
        $display("====================================================================");

        if (failed_tests > 0) begin
            $fatal(1, "Falha na verificacao da ULA!");
        end

        $finish;
    end

endmodule
