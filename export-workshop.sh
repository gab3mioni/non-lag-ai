#!/usr/bin/env bash
# Gera uma copia limpa do mod, pronta para upload no Steam Workshop (macOS/Linux).
# Espelho Unix do export-workshop.ps1.
#
# Copia apenas o conteudo do mod (common/, events/, gfx/, history/, interface/,
# localisation/, descriptor.mod, Thumbnail.png) para uma pasta de build,
# excluindo .git, docs/, tests/, .github/, steam/ e arquivos de repositorio.
# Tambem cria o arquivo .mod de registro no Paradox Launcher apontando para a build.
#
# Uso:   ./export-workshop.sh [-o caminho/da/build]
set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
OUT=""

usage() {
  cat <<'USG'
Uso: ./export-workshop.sh [-o destino]
  -o, --out   Destino da build. Padrao:
              ~/Documents/Paradox Interactive/Hearts of Iron IV/mod/non-lag-ai-build
USG
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -o|--out) OUT="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Argumento desconhecido: $1" >&2; usage >&2; exit 1 ;;
  esac
done

[[ -d "$REPO/.git" ]] || echo "Aviso: '$REPO' nao parece um clone do repositorio (sem .git)." >&2

if [[ -z "$OUT" ]]; then
  OUT="$HOME/Documents/Paradox Interactive/Hearts of Iron IV/mod/non-lag-ai-build"
fi

# Guarda de seguranca: a build nunca pode ficar dentro do repositorio
case "$OUT" in
  "$REPO"|"$REPO"/*) echo "Erro: destino nao pode ficar dentro do repositorio: $OUT" >&2; exit 1 ;;
esac

# Valida pastas obrigatorias antes de copiar
for d in common events gfx history interface localisation; do
  [[ -d "$REPO/$d" ]] || { echo "Erro: pasta obrigatoria ausente no repositorio: $d" >&2; exit 1; }
done

mkdir -p "$OUT"

rsync -a --delete \
  --exclude '.git/' --exclude 'docs/' --exclude 'tests/' --exclude '.github/' --exclude 'steam/' \
  --exclude '__pycache__/' --exclude '*.md' --exclude '*.ps1' --exclude '*.sh' --exclude '*.py' \
  --exclude '.gitignore' --exclude '.DS_Store' \
  "$REPO/" "$OUT/"

[[ -f "$OUT/descriptor.mod" ]] || { echo "Erro: descriptor.mod nao foi copiado para a build." >&2; exit 1; }

# .mod externo para o Paradox Launcher enxergar a build (upload manual via GUI)
name="$(sed -n 's/^name="\([^"]*\)".*/\1/p' "$REPO/descriptor.mod" | head -1)"
version="$(sed -n 's/^version="\([^"]*\)".*/\1/p' "$REPO/descriptor.mod" | head -1)"
supported="$(sed -n 's/^supported_version="\([^"]*\)".*/\1/p' "$REPO/descriptor.mod" | head -1)"
[[ -n "$name" ]] || { echo "Erro: name ausente no descriptor.mod" >&2; exit 1; }
version="${version:-0.0.0}"

MODFILE="$(dirname "$OUT")/non-lag-ai-build.mod"
{
  printf 'version="%s"\n' "$version"
  printf 'tags={\n\t"Balance"\n\t"Gameplay"\n\t"Fixes"\n}\n'
  printf 'name="%s [build]"\n' "$name"
  printf 'supported_version="%s"\n' "${supported:-*}"
  printf 'path="%s"\n' "$OUT"
} > "$MODFILE"

echo "=== Build do Workshop gerada ==="
echo "Conteudo : $OUT"
echo "Launcher : $MODFILE"
echo
echo "Proximos passos:"
echo "  Upload automatico:  ./upload-workshop.sh SEU_LOGIN_STEAM"
echo "  Upload manual:      HOI4 > Launcher > Mods > Upload a mod > '$name [build]'"
