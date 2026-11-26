// ============================================================================
// Grupo: BJLM (Brenno, Joao, Leticia, Marcos)
// Atividade: Projeto 02 - 2VA (Implementacao de MIPS Monociclo em Verilog)
// Disciplina: Arquitetura e Organizacao de Computadores
// Semestre letivo: 2026.2
// Arquivo: tb/tb_mips.v
// Descricao: Testbench self-checking do nucleo MIPS completo. Executa o
//            programa de tb/dados/teste_completo.list
//            e confere registradores, memoria de dados e PC final.
// Uso (na raiz do projeto): ./run_tests.sh
// ============================================================================

`timescale 1ns/1ps

module tb_mips;

    reg         clock;
    reg         reset;
    wire [31:0] pc_out, ula_out, dmem_out;
    integer     errors;

    // Dispositivo sob teste
    mips #(.INIT_FILE("tb/dados/teste_completo.list")) dut (
        .clock    (clock),
        .reset    (reset),
        .pc_out   (pc_out),
        .ula_out  (ula_out),
        .dmem_out (dmem_out)
    );

    // Clock de 10 ns
    initial clock = 1'b0;
    always #5 clock = ~clock;

    // Confere o conteudo de um registrador
    task check_reg(input integer n, input [31:0] expected);
        begin
            if (dut.u_regfile.regs[n] !== expected) begin
                $display("[FALHA] $%0d = 0x%08h (esperado 0x%08h)", n, dut.u_regfile.regs[n], expected);
                errors = errors + 1;
            end else
                $display("[ ok  ] $%0d = 0x%08h", n, expected);
        end
    endtask

    // Confere uma palavra da memoria de dados (indice de palavra)
    task check_mem(input integer w, input [31:0] expected);
        begin
            if (dut.u_d_mem.mem[w] !== expected) begin
                $display("[FALHA] mem[%0d] = 0x%08h (esperado 0x%08h)", w, dut.u_d_mem.mem[w], expected);
                errors = errors + 1;
            end else
                $display("[ ok  ] mem[%0d] = 0x%08h", w, expected);
        end
    endtask

    initial begin
        errors = 0;
        reset  = 1'b1;
        #12 reset = 1'b0;           // solta o reset entre bordas de clock

        // Tempo de sobra: ~60 instrucoes executadas + laco infinito final
        #1500;

        $display("---- Verificando registradores ----");
        check_reg(0,  32'h00000000);   // $zero sempre 0
        check_reg(1,  32'd0);          // laco decrementou 3 -> 0
        check_reg(2,  32'd1);          // v0 = 1 (nenhum desvio errado)
        check_reg(3,  32'd42);         // v1 = 42 (executou func)
        check_reg(4,  32'd7);          // lw
        check_reg(5,  32'h12340000);   // lw
        check_reg(6,  32'd5);          // executado apos jal/jr
        check_reg(7,  32'd0);          // a3: addi pulado por j
        check_reg(8,  32'd10);
        check_reg(9,  32'hFFFFFFFD);
        check_reg(10, 32'd7);          // add
        check_reg(11, 32'd13);         // sub
        check_reg(12, 32'd8);          // and
        check_reg(13, 32'hFFFFFFFF);   // or
        check_reg(14, 32'hFFFFFFF7);   // xor
        check_reg(15, 32'd0);          // nor
        check_reg(16, 32'd1);          // slt
        check_reg(17, 32'd0);          // sltu
        check_reg(18, 32'd160);        // sll
        check_reg(19, 32'h0000000F);   // srl
        check_reg(20, 32'hFFFFFFFF);   // sra
        check_reg(21, 32'd3);
        check_reg(22, 32'd80);         // sllv
        check_reg(23, 32'h1FFFFFFF);   // srlv
        check_reg(24, 32'hFFFFFFFF);   // srav
        check_reg(25, 32'h000000FD);   // andi (zero-ext)
        check_reg(26, 32'h00008000);   // ori  (zero-ext)
        check_reg(27, 32'h00007FFF);   // xori
        check_reg(28, 32'd1);          // slti
        check_reg(29, 32'd1);          // sltiu
        check_reg(30, 32'h12340000);   // lui
        check_reg(31, 32'h00000094);   // jal: endereco de retorno (PC+4)

        $display("---- Verificando memoria de dados ----");
        check_mem(0, 32'd7);
        check_mem(1, 32'h12340000);

        $display("---- Verificando PC final (laco infinito 'fim') ----");
        if (pc_out !== 32'h000000AC) begin
            $display("[FALHA] PC = 0x%08h (esperado 0x000000AC)", pc_out);
            errors = errors + 1;
        end else
            $display("[ ok  ] PC = 0x%08h", pc_out);

        $display("====================================================");
        if (errors == 0) $display(" TODOS OS TESTES DO MIPS PASSARAM");
        else             $display(" %0d FALHA(S) NO MIPS", errors);
        $display("====================================================");
        if (errors != 0) $fatal(1, "Falha na verificacao do MIPS!");
        $finish;
    end

endmodule
