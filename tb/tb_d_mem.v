// ============================================================================
// Grupo: BJLM (Brenno, Joao, Leticia, Marcos)
// Atividade: Projeto 02 - 2VA (Implementacao de MIPS Monociclo em Verilog)
// Disciplina: Arquitetura e Organizacao de Computadores
// Semestre letivo: 2026.2
// Arquivo: tb/tb_d_mem.v
// Descricao: Testbench da d_mem: leitura/escrita, MemRead em Z, escrita sincrona, DEPTH parametrizavel e enderecos invalidos.
// ============================================================================

`timescale 1ns/1ps

module tb_d_mem;
    reg Clock = 0;
    reg MemWrite = 0, MemRead = 0;
    reg [31:0] Address = 0, WriteData = 0;
    reg [31:0] a16 = 0;

    wire [31:0] ReadData, rd16;
    integer errors = 0;

    d_mem dut(Clock, Address, WriteData, MemWrite, MemRead, ReadData);
    d_mem #(.DEPTH(16)) d16(Clock, a16, WriteData, MemWrite, MemRead, rd16);

    always #10 Clock = ~Clock;

    task chk(input [31:0] got, input [31:0] expected, input [511:0] name);
    begin
        if (got !== expected) begin
            errors = errors + 1;
            $display("FALHOU %0s: obtido=%h esperado=%h", name, got, expected);
        end else
            $display("OK      %0s (%h)", name, got);
    end
    endtask

    task chk_z(input [31:0] got, input [511:0] name);
    begin
        if (got !== 32'bz) begin
            errors = errors + 1;
            $display("FALHOU %0s: obtido=%h esperado=zzzzzzzz", name, got);
        end else
            $display("OK      %0s (alta impedancia)", name);
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
        // Escreve nas palavras 0 e 1 usando enderecos em bytes.
        @(negedge Clock);
        MemWrite = 1; Address = 0; WriteData = 32'h11111111;
        @(negedge Clock);
        Address = 4; WriteData = 32'h22222222;
        @(negedge Clock);
        MemWrite = 0; MemRead = 1;

        Address = 0; #1;
        chk(ReadData, 32'h11111111, "leitura da palavra no endereco 0");
        Address = 4; #1;
        chk(ReadData, 32'h22222222, "leitura da palavra no endereco 4");

        // Leitura deve ser assincrona, sem aguardar outro clock.
        WriteData = 32'hDEAD0000; #1;
        chk(ReadData, 32'h22222222, "WriteData sem MemWrite nao altera memoria");

        // MemRead desabilitado deve colocar a saida em alta impedancia.
        MemRead = 0; #1;
        chk_z(ReadData, "MemRead=0 coloca ReadData em Z");
        MemRead = 1; #1;
        chk(ReadData, 32'h22222222, "MemRead=1 restaura leitura");

        // Escrita sincronizada: valor antigo antes e novo depois da borda.
        @(negedge Clock);
        Address = 0; MemWrite = 1; WriteData = 32'h77777777;
        #1;
        chk(ReadData, 32'h11111111, "antes da borda de escrita");
        @(posedge Clock); #2;
        chk(ReadData, 32'h77777777, "depois da borda de escrita");

        // DEPTH=16: ultima palavra fica no endereco 15*4 = 60.
        // (Address = 1024 evita que a instancia principal grave junto, pois
        //  MemWrite e WriteData sao compartilhados entre as duas instancias)
        @(negedge Clock);
        MemWrite = 0; Address = 1024; a16 = 60; MemWrite = 1;
        WriteData = 32'hFEEDC0DE;
        @(posedge Clock); #1;
        MemWrite = 0; MemRead = 1; #1;
        chk(rd16, 32'hFEEDC0DE, "DEPTH=16 ultima palavra no endereco 60");

        // Endereco desalinhado deve produzir X na leitura.
        Address = 2; #1;
        chk_x(ReadData, "endereco desalinhado");

        // Endereco 1024 corresponde ao indice 256, fora da memoria padrao.
        Address = 1024; #1;
        chk_x(ReadData, "endereco fora dos limites");

        // Escrita em endereco invalido deve ser ignorada.
        @(negedge Clock);
        Address = 1024; MemWrite = 1; WriteData = 32'hBAD0BAD0;
        @(posedge Clock); #1;
        MemWrite = 0;
        Address = 0; #1;
        chk(ReadData, 32'h77777777, "escrita invalida nao altera palavra valida");

        $display("=== tb_d_mem: %0d erro(s) ===", errors);
        $finish;
    end
endmodule
