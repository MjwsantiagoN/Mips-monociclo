# Mips-monociclo (Grupo BJLM)

Projeto 02 - 2VA - Arquitetura e Organização de Computadores (UFRPE 2026.2).
MIPS monociclo em Verilog com as 28 instruções do enunciado (R.1–R.15, I.1–I.11, J.1–J.2).

## Estrutura
| Caminho | Conteúdo |
| :--- | :--- |
| `src/mips.v` | Top-level: `clock`, `reset` → `pc_out`, `ula_out`, `dmem_out` |
| `src/pc/pc.v`, `src/pc/next_pc.v` | Contador de programa e lógica do próximo PC (PC+4, beq/bne, j/jal, jr) |
| `src/memoria/i_mem.v`, `d_mem.v`, `regfile.v` | Memórias e banco de registradores |
| `src/ctrl/ctrl.v`, `src/ula/ula_ctrl.v`, `src/ula/ula.v` | Controle principal, controle da ULA e ULA |
| `tb/` | Testbenches self-checking (um por módulo, e `tb_mips.v` do processador completo) |
| `tb/dados/` | Listas de instruções usadas só pelos testbenches (`tb_i_mem`, `tb_mips`) |
| `instruction.list` | Programa do professor, carregado pela `i_mem` (binário oficial) |

## Como rodar
Sempre a partir da **raiz do projeto** (a `i_mem` lê `instruction.list` do diretório atual).

Tudo de uma vez (Icarus Verilog):
```bash
./run_tests.sh
```
Só o processador:
```bash
iverilog -g2012 -o sim_mips.vvp src/mips.v src/pc/*.v src/ctrl/ctrl.v src/ula/*.v src/memoria/*.v tb/tb_mips.v
vvp sim_mips.vvp   # o tb_mips.v roda o programa próprio (tb/dados/teste_completo.list)
```
ModelSim/Quartus: mude para a raiz do projeto (`File → Change Directory`) e use
`vlog -sv src/mips.v src/pc/*.v src/ctrl/ctrl.v src/ula/*.v src/memoria/*.v tb/tb_mips.v`,
`vsim work.tb_mips`, `add wave -r sim:/tb_mips/dut/*`, `run 2 us`. O `mips` carrega o `instruction.list` da raiz (programa do professor) por padrão; o `tb_mips.v` troca o `INIT_FILE` para o programa próprio.

## Integração (o que o `mips.v` resolve)
- **jr:** detectado por `opcode = 0` e `funct = 0x08`; bloqueia `RegWrite`; o `next_pc` carrega `R[$rs]`.
- **jal:** o sinal `Jal` força o destino `$31` e grava `PC+4`.
- **sll/srl/sra:** `shamt` entra em `In1` da ULA (MUX por `funct` 0x00/0x02/0x03).
- **Imediato:** `SignExt` escolhe extensão com sinal ou com zeros (`andi`/`ori`/`xori`/`lui`).
- **Reset:** o `pc` não tem reset (conforme enunciado); enquanto `reset = 1`, o `nextPC` é forçado a 0.
- **Próximo PC:** prioridade `jr` > `j/jal` > desvio tomado > `PC+4`. Sem delay slot.
- **ROM:** posições não programadas da `i_mem` ficam em 0 (nop), não em `X`. O programa do professor termina com `j exit` para o endereço 256, logo depois da última instrução.

