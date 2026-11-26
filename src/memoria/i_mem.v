// ============================================================================
// Grupo: BJLM (Brenno, Joao, Leticia, Marcos)
// Atividade: Projeto 02 - 2VA (Implementacao de MIPS Monociclo em Verilog)
// Disciplina: Arquitetura e Organizacao de Computadores
// Semestre letivo: 2026.2
// Arquivo: src/memoria/i_mem.v
// Descricao: Memoria de instrucoes (ROM assincrona, DEPTH palavras) carregada do arquivo texto instruction.list via $readmemb.
// ============================================================================

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
    // Posicoes nao programadas ficam em 0 (nop: sll $0,$0,0), e nao em X;
    // assim o PC continua valido se o programa terminar alem da ultima linha.
    integer i;
    initial begin
        for (i = 0; i < DEPTH; i = i + 1)
            mem[i] = 32'h00000000;
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
