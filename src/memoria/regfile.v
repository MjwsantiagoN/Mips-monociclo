// ============================================================================
// Grupo: BJLM (Brenno, Joao, Leticia, Marcos)
// Atividade: Projeto 02 - 2VA (Implementacao de MIPS Monociclo em Verilog)
// Disciplina: Arquitetura e Organizacao de Computadores
// Semestre letivo: 2026.2
// Arquivo: src/memoria/regfile.v
// Descricao: Banco de 32 registradores de 32 bits: 2 leituras assincronas, 1 escrita sincrona, $0 fixo em 0 e Reset assincrono.
// ============================================================================

// regfile.v - Banco de registradores do MIPS (32 x 32 bits)
//  - Leitura assincrona (2 portas)
//  - Escrita sincrona na borda de subida de Clock
//  - Registrador 0 sempre zero (escritas ignoradas)
//  - Reset assincrono ativo em 1, com prioridade sobre escrita

module regfile (
    input         Clock,
    input         Reset,       // assincrono, ativo em 1
    input         RegWrite,    // habilita escrita
    input  [4:0]  ReadAddr1,
    input  [4:0]  ReadAddr2,
    input  [4:0]  WriteAddr,
    input  [31:0] WriteData,
    output [31:0] ReadData1,
    output [31:0] ReadData2
);
    reg [31:0] regs [0:31];
    integer i;

    // Leitura assincrona: $0 retorna sempre zero
    assign ReadData1 = (ReadAddr1 == 5'd0) ? 32'h00000000 : regs[ReadAddr1];
    assign ReadData2 = (ReadAddr2 == 5'd0) ? 32'h00000000 : regs[ReadAddr2];

    // Reset assincrono (prioridade) e escrita sincrona
    always @(posedge Clock or posedge Reset) begin
        if (Reset) begin
            for (i = 0; i < 32; i = i + 1)
                regs[i] <= 32'h00000000;
        end else if (RegWrite && WriteAddr != 5'd0) begin
            regs[WriteAddr] <= WriteData;   // endereco 0 ignorado
        end
        // RegWrite = 0: conteudo preservado
    end
endmodule
