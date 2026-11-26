// ============================================================================
// Grupo: BJLM (Brenno, Joao, Leticia, Marcos)
// Atividade: Projeto 02 - 2VA (Implementacao de MIPS Monociclo em Verilog)
// Disciplina: Arquitetura e Organizacao de Computadores
// Semestre letivo: 2026.2
// Arquivo: tb/tb_i_mem.v
// Descricao: Testbench da i_mem: leitura de instrucoes, DEPTH parametrizavel, arquivos diferentes e enderecos invalidos.
// ============================================================================

`timescale 1ns/1ps

module tb_i_mem;
    reg [31:0] address = 0;
    wire [31:0] out_default, out_16, out_file2;
    integer errors = 0;

    // Os arquivos de tb/dados/ sao lidos a partir da raiz do projeto, entao rode o simulador no
    // diretorio raiz do projeto.
    i_mem #(.DEPTH(256), .INIT_FILE("tb/dados/instruction.list"))  u0(address, out_default);
    i_mem #(.DEPTH(16),  .INIT_FILE("tb/dados/instruction.list"))  u1(address, out_16);
    i_mem #(.DEPTH(16),  .INIT_FILE("tb/dados/instruction2.list")) u2(address, out_file2);

    task chk(input [31:0] got, input [31:0] expected, input [511:0] name);
    begin
        if (got !== expected) begin
            errors = errors + 1;
            $display("FALHOU %0s: obtido=%h esperado=%h", name, got, expected);
        end else
            $display("OK      %0s (%h)", name, got);
    end
    endtask

    task chk_x(input [31:0] got, input [511:0] name);
    begin
        if (^got !== 1'bx) begin
            errors = errors + 1;
            $display("FALHOU %0s: obtido=%h esperado=valor desconhecido (X)", name, got);
        end else
            $display("OK      %0s (X)", name);
    end
    endtask

    initial begin
        // instruction.list: uma instrucao de 32 bits por linha.
        // O PC avanca de 4 em 4 bytes.
        address = 0;  #1;
        chk(out_default, 32'h20080005, "instruction.list, instrucao 1, endereco 0");

        address = 4;  #1;
        chk(out_default, 32'h2009000A, "instruction.list, instrucao 2, endereco 4");

        address = 8;  #1;
        chk(out_default, 32'h01095020, "instruction.list, instrucao 3, endereco 8");

        address = 12; #1;
        chk(out_default, 32'hAC0A0000, "instruction.list, instrucao 4, endereco 12");

        // Outro arquivo de inicializacao, na primeira instrucao.
        address = 0; #1;
        chk(out_file2, 32'hDEADBEEF, "instruction2.list, instrucao 1");

        // DEPTH=16: indice 15 corresponde ao endereco em bytes 60.
        address = 60; #1;
        chk(out_16, 32'h0800000F, "DEPTH=16, ultima instrucao no endereco 60");
        chk(out_file2, 32'h99999999, "instruction2.list, ultima instrucao");

        // Endereco desalinhado deve produzir X.
        address = 2; #1;
        chk_x(out_default, "endereco desalinhado");

        // DEPTH=16: endereco 64 corresponde ao indice 16, fora dos limites.
        address = 64; #1;
        chk_x(out_16, "endereco fora dos limites de DEPTH=16");

        $display("=== tb_i_mem: %0d erro(s) ===", errors);
        $finish;
    end
endmodule
