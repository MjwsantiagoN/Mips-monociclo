#!/usr/bin/env bash
# ============================================================================
# Grupo: BJLM (Brenno, Joao, Leticia, Marcos)
# Atividade: Projeto 02 - 2VA | Disciplina: Arquitetura e Organizacao de
# Computadores | Semestre letivo: 2026.2
# Arquivo: run_tests.sh
# Descricao: Roda todos os testbenches com o
#            Icarus Verilog. Execute na raiz do projeto: ./run_tests.sh
# ============================================================================
set -u
OUT=$(mktemp -d)
fail=0
run() {  # run <nome> <arquivos...>
  local n=$1; shift
  iverilog -g2012 -o "$OUT/$n" "$@" 2>/dev/null || { echo "[ERRO ] $n: falha ao compilar"; fail=1; return; }
  if vvp "$OUT/$n" 2>&1 | grep -Eq "FALHOU|FALHA|FAIL|[1-9][0-9]* falhas|[1-9][0-9]* erro\(s\)|[1-9][0-9]* ERRO"; then
    echo "[FALHA] $n"; fail=1
  else echo "[ ok  ] $n"; fi
}
run ula      src/ula/ula.v src/ula/ula_ctrl.v tb/tb_ula.v
run ctrl     src/ctrl/ctrl.v tb/tb_ctrl.v
run regfile  src/memoria/regfile.v tb/tb_regfile.v
run i_mem    src/memoria/i_mem.v tb/tb_i_mem.v
run d_mem    src/memoria/d_mem.v tb/tb_d_mem.v
run pc       src/pc/pc.v tb/tb_pc.v
run next_pc  src/pc/next_pc.v tb/tb_next_pc.v
run mips     src/mips.v src/pc/pc.v src/pc/next_pc.v src/ctrl/ctrl.v src/ula/ula.v src/ula/ula_ctrl.v \
             src/memoria/i_mem.v src/memoria/d_mem.v src/memoria/regfile.v tb/tb_mips.v
rm -rf "$OUT"
exit $fail
