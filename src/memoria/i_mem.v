// ============================================================
// i_mem.v - Memoria ROM de instrucoes (leitura assincrona)
// Projeto 02 - Arquitetura e Organizacao de Computadores
//
// - DEPTH palavras de 32 bits.
// - Conteudo carregado de arquivo texto (.list), com uma instrucao
//   binaria de 32 bits por linha, usando $readmemb.
// - address recebe o endereco em bytes fornecido pelo PC.
// - Como cada instrucao ocupa 4 bytes, o indice e address >> 2.
// - Enderecos devem ser alinhados em 4 bytes.
// ============================================================

module i_mem #(
    parameter DEPTH     = 256,
    parameter INIT_FILE = "instruction.list"
)(
    input  [31:0] address,
    output [31:0] i_out
);

    reg [31:0] mem [0:DEPTH-1];

    // Carrega o arquivo: primeira linha -> posicao 0,
    // segunda linha -> posicao 1, e assim sucessivamente.
    initial begin
        $readmemb(INIT_FILE, mem);
    end

    // Converte o endereco em bytes para indice de palavra.
    wire [29:0] index = address[31:2];

    // A ROM so possui enderecos validos alinhados e dentro de DEPTH.
    wire address_valid = (address[1:0] == 2'b00) &&
                         (index < DEPTH);

    // Leitura combinacional/assincrona.
    // Endereco invalido gera X para facilitar a identificacao
    // de erros de enderecamento durante a simulacao.
    assign i_out = address_valid ? mem[index] : 32'bx;

endmodule
