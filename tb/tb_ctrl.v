// ============================================================================
// Grupo: BJLM (Brenno, Joao, Leticia, Marcos)
// Atividade: Projeto 02 - 2VA (Implementacao de MIPS Monociclo em Verilog)
// Disciplina: Arquitetura e Organizacao de Computadores
// Semestre letivo: 2026.2
// Arquivo: tb/tb_ctrl.v
// Descricao: Testbench automatizado (self-checking) para validar o modulo
//            ctrl (Unidade de Controle Principal), verificando todas as
//            instrucoes Tipo-R, Tipo-I e Tipo-J do subconjunto ISA e o
//            comportamento seguro para opcodes nao mapeados.
//
// Como rodar localmente (Icarus Verilog):
//   iverilog -Wall -o sim_ctrl.vvp src/ctrl/ctrl.v tb/tb_ctrl.v
//   vvp sim_ctrl.vvp
// ============================================================================

module tb_ctrl;

    // Entrada estimulada pelo testbench
    reg  [5:0] opcode;

    // Saidas observadas da Unidade de Controle
    wire       RegDst;
    wire       ALUSrc;
    wire       MemtoReg;
    wire       RegWrite;
    wire       MemRead;
    wire       MemWrite;
    wire       BranchEq;
    wire       BranchNE;
    wire       Jump;
    wire       Jal;
    wire       SignExt;
    wire [3:0] ALUOp;

    // Contadores de resultados dos testes
    integer total_tests;
    integer passed_tests;
    integer failed_tests;

    // Instanciacao do modulo sob teste (DUT)
    ctrl dut_ctrl (
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

    // Tarefa auxiliar para aplicar um opcode e validar todas as saidas
    task check_case;
        input [8*20-1:0] test_name;
        input [5:0]      t_opcode;
        input [14:0]     expected; // {RegDst, ALUSrc, MemtoReg, RegWrite, MemRead, MemWrite, BranchEq, BranchNE, Jump, Jal, SignExt, ALUOp[3:0]}
        reg   [14:0]     actual;
        begin
            opcode = t_opcode;
            #1; // Aguarda propagacao combinacional

            actual = {RegDst, ALUSrc, MemtoReg, RegWrite, MemRead, MemWrite,
                      BranchEq, BranchNE, Jump, Jal, SignExt, ALUOp};
            total_tests = total_tests + 1;

            // Usa '===' para rejeitar bits indefinidos ('x' ou 'z')
            if (actual === expected) begin
                passed_tests = passed_tests + 1;
                $display("[PASS] %-18s (op=%b) | RegDst=%b ALUSrc=%b MemtoReg=%b RegWrite=%b MemR=%b MemW=%b BEQ=%b BNE=%b Jmp=%b Jal=%b SExt=%b ALUOp=%b",
                         test_name, opcode, RegDst, ALUSrc, MemtoReg, RegWrite,
                         MemRead, MemWrite, BranchEq, BranchNE, Jump, Jal, SignExt, ALUOp);
            end else begin
                failed_tests = failed_tests + 1;
                $display("[FAIL] %-18s (op=%b) | Esperado=%b Obtido=%b",
                         test_name, opcode, expected, actual);
            end
        end
    endtask

    initial begin
        total_tests  = 0;
        passed_tests = 0;
        failed_tests = 0;

        $dumpfile("ctrl.vcd");
        $dumpvars(0, tb_ctrl);

        $display("====================================================================");
        $display("  TESTBENCH UNIDADE DE CONTROLE PRINCIPAL (ctrl) - MIPS MONOCICLO   ");
        $display("====================================================================");

        // Ordem do vetor esperado (15 bits):
        // {RegDst, ALUSrc, MemtoReg, RegWrite, MemRead, MemWrite, BranchEq, BranchNE, Jump, Jal, SignExt, ALUOp[3:0]}

        // 1. Tipo-R (15 instrucoes compartilham opcode 000000)
        check_case("Tipo-R (funct)",   6'b000000, 15'b1_0_0_1_0_0_0_0_0_0_0_0010);

        // 2. Acesso a memoria (lw / sw)
        check_case("I: lw",            6'b100011, 15'b0_1_1_1_1_0_0_0_0_0_1_0000);
        check_case("I: sw",            6'b101011, 15'b0_1_0_0_0_1_0_0_0_0_1_0000);

        // 3. Desvios condicionais (beq / bne)
        check_case("I: beq",           6'b000100, 15'b0_0_0_0_0_0_1_0_0_0_1_0001);
        check_case("I: bne",           6'b000101, 15'b0_0_0_0_0_0_0_1_0_0_1_0001);

        // 4. Tipo-I com extensao de sinal (addi / slti / sltiu)
        check_case("I: addi",          6'b001000, 15'b0_1_0_1_0_0_0_0_0_0_1_0000);
        check_case("I: slti",          6'b001010, 15'b0_1_0_1_0_0_0_0_0_0_1_0110);
        check_case("I: sltiu",         6'b001011, 15'b0_1_0_1_0_0_0_0_0_0_1_0111);

        // 5. Tipo-I logicas / lui com extensao com zeros (andi / ori / xori / lui)
        check_case("I: andi",          6'b001100, 15'b0_1_0_1_0_0_0_0_0_0_0_0011);
        check_case("I: ori",           6'b001101, 15'b0_1_0_1_0_0_0_0_0_0_0_0100);
        check_case("I: xori",          6'b001110, 15'b0_1_0_1_0_0_0_0_0_0_0_0101);
        check_case("I: lui",           6'b001111, 15'b0_1_0_1_0_0_0_0_0_0_0_1000);

        // 6. Saltos incondicionais (j / jal)
        check_case("J: j",             6'b000010, 15'b0_0_0_0_0_0_0_0_1_0_0_1111);
        check_case("J: jal",           6'b000011, 15'b0_0_0_1_0_0_0_0_1_1_0_1111);

        // 7. Seguranca: opcode invalido nao escreve nem desvia e deixa ULA ociosa
        check_case("SAFE: invalida",   6'b111111, 15'b0_0_0_0_0_0_0_0_0_0_0_1111);

        $display("====================================================================");
        $display(" RESUMO: %0d/%0d testes passaram | %0d falhas",
                 passed_tests, total_tests, failed_tests);
        $display("====================================================================");

        if (failed_tests > 0) begin
            $fatal(1, "Falha na verificacao da unidade de controle!");
        end

        $finish;
    end

endmodule
