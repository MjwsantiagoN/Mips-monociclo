// ============================================================
// d_mem.v - Memoria RAM de dados (palavras de 32 bits)
// Projeto 02 - Arquitetura e Organizacao de Computadores
//
// - Leitura assincrona controlada por MemRead.
// - Escrita sincrona na borda de subida de Clock, controlada
//   por MemWrite.
// - Address utiliza endereco em bytes; cada palavra ocupa 4 bytes.
// - Enderecos devem ser alinhados em 4 bytes.
// - Quando MemRead = 0, ReadData fica em alta impedancia (Z).
// ============================================================

module d_mem #(
    parameter DEPTH = 256
)(
    input         Clock,
    input  [31:0] Address,
    input  [31:0] WriteData,
    input         MemWrite,
    input         MemRead,
    output [31:0] ReadData
);

    reg [31:0] mem [0:DEPTH-1];

    // Converte o endereco em bytes para indice de palavra.
    // Address[1:0] deve ser 2'b00 para acesso alinhado.
    wire [29:0] index = Address[31:2];

    // Verifica se o endereco esta alinhado e dentro da memoria.
    wire address_valid = (Address[1:0] == 2'b00) &&
                         (index < DEPTH);

    // Leitura assincrona:
    // - MemRead = 0: barramento em alta impedancia, conforme enunciado.
    // - Endereco invalido: X para evidenciar erro durante a simulacao.
    assign ReadData = !MemRead       ? 32'bz :
                      !address_valid ? 32'bx :
                                       mem[index];

    // Escrita sincrona na borda de subida do clock.
    // Escritas em enderecos invalidos sao ignoradas.
    always @(posedge Clock) begin
        if (MemWrite && address_valid) begin
            mem[index] <= WriteData;
        end
    end

endmodule
