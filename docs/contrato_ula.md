# Contrato de Integração — Módulos `ula` e `ula_ctrl` (Grupo BJLM)

Este guia resume exatamente o que a **Pessoa 2 (`ctrl.v`)**, a **Pessoa 3 (`PC`)** e a **Pessoa 4 (`mips.v` - Marcos)** precisam conectar para integrar os módulos `src/ula.v` e `src/ula_ctrl.v` sem conflitos.

---

## 1. Interfaces dos Módulos (Págs. 10–11 do PDF)

### `ula` (`src/ula.v`)
| Porta | Direção | Largura | Descrição |
| :--- | :--- | :--- | :--- |
| `In1` | `input` | `[31:0]` | `ReadData1` (`$rs`) ou `{27'b0, instr[10:6]}` (`shamt`) para `sll`/`srl`/`sra` |
| `In2` | `input` | `[31:0]` | `ReadData2` (`$rt`) ou imediato estendido (MUX controlado por `ALUSrc`) |
| `OP` | `input` | `[3:0]` | Saída de controle vinda diretamente de `ula_ctrl` |
| `result` | `output` | `[31:0]` | Resultado de 32 bits (vai para `d_mem.Address` e MUX de `WriteData`) |
| `Zero_flag` | `output` | `1 bit` | `1` quando `result == 0` (`0` caso contrário) |

### `ula_ctrl` (`src/ula_ctrl.v`)
| Porta | Direção | Largura | Descrição |
| :--- | :--- | :--- | :--- |
| `ALUOp` | `input` | `[3:0]` | Código de operação base gerado por `ctrl.v` |
| `funct` | `input` | `[5:0]` | `Instruction[5:0]` |
| `OP` | `output` | `[3:0]` | Código de operação enviado para `ula.OP` |

---

## 2. Tabela `ALUOp[3:0]` para o módulo `ctrl.v` (Pessoa 2)

Como o projeto possui várias instruções Tipo-I com operações distintas (`addi`, `andi`, `ori`, `xori`, `slti`, `sltiu`, `lui`, `beq`, `bne`, `lw`, `sw`), `ALUOp` utiliza **4 bits**:

| `ALUOp [3:0]` | Instruções que devem gerar este `ALUOp` |
| :--- | :--- |
| `4'b0000` | `lw`, `sw`, `addi` |
| `4'b0001` | `beq`, `bne` |
| `4'b0010` | Todas as instruções Tipo-R (`opcode == 6'b000000`) |
| `4'b0011` | `andi` *(atenção: estender imediato com zeros)* |
| `4'b0100` | `ori` *(atenção: estender imediato com zeros)* |
| `4'b0101` | `xori` *(atenção: estender imediato com zeros)* |
| `4'b0110` | `slti` *(estender imediato com sinal)* |
| `4'b0111` | `sltiu` *(estender imediato com sinal, comparação unsigned)* |
| `4'b1000` | `lui` *(usar `ALUSrc = 1` para enviar o imediato em `In2`)* |
| `4'b1111` | `j`, `jal` *(ULA ociosa, `RegWrite` ou salto tratados fora da ULA)* |

---

## 3. Pontos de Atenção no Top-Level (`mips.v` - Marcos)

1. **Shifts por `shamt` (`sll`, `srl`, `sra`):**
   - A ULA assume que o fator de deslocamento entra em `In1[4:0]` e o registrador a deslocar (`$rt` = `ReadData2`) entra em `In2`.
   - Portanto, basta colocar um MUX 2:1 antes de `ula.In1` (ou usar um sinal auxiliar / detecção de Tipo-R com `funct` in `{0x00, 0x02, 0x03}`):
     ```verilog
     assign ula_in1 = (is_shamt_shift) ? {27'b0, instr[10:6]} : ReadData1;
     ```
   - Para `sllv`, `srlv`, `srav`, `is_shamt_shift` fica em `0`, passando `ReadData1` (`$rs`) normalmente para `In1` (e a ULA usa `In1[4:0]`).
2. **Desvios (`beq` vs `bne` - Pessoa 3):**
   - Ambos usam `ALUOp = 4'b0001` (subtração `In1 - In2`).
   - `beq` desvia quando `(BranchEq & Zero_flag)`.
   - `bne` desvia quando `(BranchNE & ~Zero_flag)`.

---

## 4. Como Rodar os Testes da ULA Localmente

Com o **Icarus Verilog** instalado:

```powershell
iverilog -Wall -o sim_ula.vvp src/ula.v src/ula_ctrl.v tb/tb_ula.v
vvp sim_ula.vvp
```
