#!/usr/bin/env bash
# Publica (ou atualiza) o mod no Steam Workshop via steamcmd (macOS/Linux).
# COMANDO UNICO de publicacao: roda o export-workshop.sh, gera steam/build.vdf
# e chama o steamcmd. Senha e Steam Guard sao pedidos pelo proprio steamcmd.
#
# O ID do Workshop e lido de steam/workshop.item. Com ID 0, o script aborta
# por seguranca, salvo quando --new-item e informado explicitamente.
#
# Uso:   ./upload-workshop.sh                          (login salvo, ou pergunta)
#        ./upload-workshop.sh LOGIN_STEAM [opcoes]
#        ./upload-workshop.sh --save-login LOGIN_STEAM (grava o login e sai)
#        ./upload-workshop.sh --set-id ID              (grava o PublishedFileId)
set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
APPID="394360"   # Hearts of Iron IV
TITLE="Non Lag AI"
ITEMFILE="$REPO/steam/workshop.item"
USERFILE="$REPO/steam/steamuser"
NEWITEM=0
BUILD="$HOME/Documents/Paradox Interactive/Hearts of Iron IV/mod/non-lag-ai-build"
STEAMCMD=""
STEAM_USER=""
SKIP_EXPORT=0
VISIBILITY="2"   # 0=publico, 1=amigos, 2=oculto (padrao seguro)

usage() {
  cat <<'USG'
Uso: ./upload-workshop.sh [login_steam] [opcoes]
Opcoes:
  --save-login LOGIN  grava o login em steam/steamuser (gitignored) e sai
  --visibility N      0=publico, 1=amigos, 2=oculto (padrao)
  --skip-export       usa a build ja existente (pula export-workshop.sh)
  --steamcmd CAMINHO  caminho do steamcmd (auto-detecta se omitido)
  --new-item          permite criar um NOVO item (apenas primeira publicacao)
  --set-id ID         nao faz upload: grava o PublishedFileId em steam/workshop.item e sai
  -h | --help         esta ajuda
Exemplos:
  ./upload-workshop.sh --save-login meu_login   # uma unica vez
  ./upload-workshop.sh                          # atualiza o item registrado
  ./upload-workshop.sh meu_login --visibility 2
  ./upload-workshop.sh --set-id 1234567890
USG
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --set-id)
      [[ "${2:-}" =~ ^[0-9]+$ ]] || { echo "Erro: --set-id deve ser numerico." >&2; exit 1; }
      mkdir -p "$(dirname "$ITEMFILE")"
      printf 'publishedfileid=%s\n' "$2" > "$ITEMFILE"
      echo "PublishedFileId gravado em steam/workshop.item: $2"
      echo "URL: https://steamcommunity.com/sharedfiles/filedetails/?id=$2"
      exit 0 ;;
    --save-login)
      [[ -n "${2:-}" ]] || { echo "Erro: --save-login exige o login." >&2; exit 1; }
      mkdir -p "$REPO/steam"
      printf '%s\n' "$2" > "$USERFILE"; chmod 600 "$USERFILE"
      echo "Login salvo em $USERFILE (gitignored). Agora basta: ./upload-workshop.sh"
      exit 0 ;;
    --skip-export) SKIP_EXPORT=1; shift ;;
    --new-item) NEWITEM=1; shift ;;
    --visibility) VISIBILITY="${2:-}"; shift 2 ;;
    --steamcmd) STEAMCMD="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    -*)
      echo "Opcao desconhecida: $1" >&2; usage >&2; exit 1 ;;
    *)
      if [[ -z "$STEAM_USER" ]]; then STEAM_USER="$1"; shift; else echo "Argumento extra: $1" >&2; exit 1; fi ;;
  esac
done

[[ "$VISIBILITY" =~ ^[012]$ ]] || { echo "Erro: --visibility deve ser 0, 1 ou 2." >&2; exit 1; }

# --- 1) PublishedFileId registrado (o upload sempre atualiza ESSE item) ---
ID="0"
if [[ -f "$ITEMFILE" ]]; then
  ID="$(sed -n 's/.*publishedfileid=\([0-9][0-9]*\).*/\1/p' "$ITEMFILE" | head -1)"
fi
ID="${ID:-0}"
if [[ "$ID" == "0" && $NEWITEM -eq 0 ]]; then
  echo "Erro: nenhum PublishedFileId registrado em steam/workshop.item." >&2
  echo "Para atualizar o item ja publicado, grave o ID:" >&2
  echo "  ./upload-workshop.sh --set-id O_ID_DO_ITEM" >&2
  echo "Para criar um item NOVO (primeira publicacao), use --new-item." >&2
  exit 1
fi

# --- 2) Build limpa ---
if [[ $SKIP_EXPORT -eq 0 ]]; then
  "$REPO/export-workshop.sh"
fi
[[ -f "$BUILD/descriptor.mod" ]] || { echo "Erro: build nao encontrada em: $BUILD" >&2; echo "Rode ./export-workshop.sh primeiro (ou sem --skip-export)." >&2; exit 1; }

# --- 3) Localizar steamcmd ---
if [[ -z "$STEAMCMD" ]]; then
  for c in "$(command -v steamcmd 2>/dev/null || true)" "$HOME/steamcmd/steamcmd.sh" /opt/homebrew/bin/steamcmd /usr/local/bin/steamcmd; do
    if [[ -n "$c" && -x "$c" ]]; then STEAMCMD="$c"; break; fi
  done
fi
if [[ -z "$STEAMCMD" ]]; then
  echo "Erro: steamcmd nao encontrado." >&2
  echo "Instale com: brew install steamcmd" >&2
  echo "Ou informe o caminho com --steamcmd CAMINHO." >&2
  exit 1
fi

# --- 4) Versao para o changenote ---
version="$(sed -n 's/^version="\([^"]*\)".*/\1/p' "$BUILD/descriptor.mod" | head -1)"
version="${version:-0.0.0}"

# --- 5) Gerar VDF ---
mkdir -p "$REPO/steam"
VDF="$REPO/steam/build.vdf"
cat > "$VDF" <<EOF
"workshopitem"
{
	"appid"				"$APPID"
	"publishedfileid"	"$ID"
	"contentfolder"		"$BUILD"
	"previewfile"		"$REPO/Thumbnail.png"
	"title"				"$TITLE"
	"visibility"		"$VISIBILITY"
	"changenote"		"v$version"
}
EOF

if [[ "$ID" == "0" ]]; then
  echo ">> Aviso: --new-item: um NOVO item sera criado no Workshop (publishedfileid=0)."
else
  echo ">> Atualizando o item registrado $ID (v$version)."
  echo "   URL: https://steamcommunity.com/sharedfiles/filedetails/?id=$ID"
fi

# --- 6) Login + publish (senha e Steam Guard pedidos pelo steamcmd) ---
if [[ -z "$STEAM_USER" ]] && [[ -f "$USERFILE" ]]; then
  STEAM_USER="$(head -1 "$USERFILE" | tr -d '[:space:]')"
  [[ -n "$STEAM_USER" ]] && echo "Usando login salvo em steam/steamuser: $STEAM_USER"
fi
if [[ -z "$STEAM_USER" ]]; then
  printf 'Login da Steam: '
  read -r STEAM_USER
fi
echo "Iniciando steamcmd (pedira senha e, se necessario, codigo do Steam Guard)..."
set +e
"$STEAMCMD" +login "$STEAM_USER" +workshop_build_item "$VDF" +quit
rc=$?
set -e

echo
if [[ $rc -ne 0 ]]; then
  echo "Aviso: steamcmd encerrou com codigo $rc - confira o log acima." >&2
  exit $rc
fi

# --- 7) Reconciliar o ID real (o steamcmd pode criar um item novo) ---
NEWID="$(sed -n 's/.*"publishedfileid"[[:space:]]*"\([0-9][0-9]*\)".*/\1/p' "$VDF" | head -1)"
NEWID="${NEWID%%$'\r'}"
if [[ -n "$NEWID" && "$NEWID" != "$ID" ]]; then
  printf 'publishedfileid=%s\n' "$NEWID" > "$ITEMFILE"
  ID="$NEWID"
  echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
  echo "!! ATENCAO: o Workshop passou a usar o item $NEWID (novo ID)."
  echo "!! steam/workshop.item foi atualizado automaticamente para ele."
  echo "!! URL: https://steamcommunity.com/sharedfiles/filedetails/?id=$NEWID"
  echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
fi

echo "=== Upload concluido ==="
if [[ "$ID" != "0" ]]; then
  echo "PublishedFileId: $ID"
  echo "URL: https://steamcommunity.com/sharedfiles/filedetails/?id=$ID"
fi
exit 0
