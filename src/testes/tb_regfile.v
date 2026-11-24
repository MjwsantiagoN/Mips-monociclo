`timescale 1ns/1ps
module tb_regfile;
    reg Clock=0, Reset=0, RegWrite=0;
    reg [4:0] ra1=0, ra2=0, wa=0;
    reg [31:0] wd=0;
    wire [31:0] rd1, rd2;
    integer errors=0, checks=0, k, bad;

    regfile dut(Clock,Reset,RegWrite,ra1,ra2,wa,wd,rd1,rd2);
    always #10 Clock = ~Clock;   // borda de subida em 10, 30, 50 ns...

    task check(input [31:0] got, input [31:0] exp, input [511:0] name);
    begin
        checks = checks + 1;
        if (got !== exp) begin errors=errors+1;
            $display("FALHOU  %0s: obtido=%h esperado=%h", name, got, exp); end
        else $display("OK      %0s", name);
    end endtask

    // Varre os 32 registradores pela porta 1; todos devem ser zero,
    // exceto os indices skip1 e skip2 (use 0 para nao ignorar nenhum extra)
    task check_all_zero_except(input [4:0] skip1, input [4:0] skip2, input [511:0] name);
    begin
        bad = 0;
        for (k=0; k<32; k=k+1) begin
            ra1 = k; #1;
            if (k != skip1 && k != skip2 && rd1 !== 32'h0) bad = bad + 1;
        end
        check(bad, 0, name);
    end endtask

    initial begin
        // Preenche alguns registradores
        @(negedge Clock); RegWrite=1; wa=5;  wd=32'h55;       @(negedge Clock);
        wa=1; wd=32'h11; @(negedge Clock); wa=31; wd=32'h1F;  @(negedge Clock);
        RegWrite=0; ra1=5; #1 check(rd1,32'h55,"pre-reset: $5 escrito");

        // T1: reset assincrono entre bordas (ativado 4 ns apos o negedge)
        #4 Reset=1; #1;
        check_all_zero_except(0,0,"T1 reset assincrono zera os 32 registradores");
        @(negedge Clock); Reset=0;

        // T2/T3: escrever 1 e 31, ler simultaneamente
        RegWrite=1; wa=1; wd=32'hAAAA0001; @(negedge Clock);
        wa=31; wd=32'hBBBB001F; @(negedge Clock); RegWrite=0;
        ra1=1; ra2=31; #1;
        check(rd1,32'hAAAA0001,"T2/T3 porta1 = $1");
        check(rd2,32'hBBBB001F,"T2/T3 porta2 = $31");
        check_all_zero_except(1,31,"T2 demais registradores permanecem zero");

        // T4: alterar enderecos de leitura entre bordas
        ra1=31; ra2=1; #1;
        check(rd1,32'hBBBB001F,"T4 porta1 acompanha endereco");
        check(rd2,32'hAAAA0001,"T4 porta2 acompanha endereco");

        // T5: mesmo registrador nas duas portas
        ra1=31; ra2=31; #1 check(rd1,rd2,"T5 portas com o mesmo valor");

        // T6: RegWrite=0 preserva
        @(negedge Clock); wa=1; wd=32'hFFFFFFFF; RegWrite=0; @(negedge Clock);
        ra1=1; #1 check(rd1,32'hAAAA0001,"T6 RegWrite=0 preserva o valor");

        // T7: escrita no registrador 0
        RegWrite=1; wa=0; wd=32'h12345678; @(negedge Clock);
        ra1=0; #1 check(rd1,0,"T7 $0 continua zero");

        // T8: leitura durante escrita
        wa=7; wd=32'hC0DE0007; ra1=7; RegWrite=1; #1;
        check(rd1,0,"T8 antes da borda: valor antigo");
        @(posedge Clock); #2 check(rd1,32'hC0DE0007,"T8 apos a borda: valor novo");

        // T9: Reset=1 e RegWrite=1 durante a borda de subida
        @(negedge Clock); Reset=1; RegWrite=1; wa=9; wd=32'h99;
        @(posedge Clock); #2;
        check_all_zero_except(0,0,"T9 reset+write: banco permanece zerado");
        Reset=0; RegWrite=0;

        $display("=== regfile: %0d verificacoes, %0d erro(s) ===", checks, errors);
        $finish;
    end
endmodule
