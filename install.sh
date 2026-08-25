#!/usr/bin/env bash
# Instala los cuatro subagentes en ~/.claude/agents/ y añade el bloque de
# enrutado a ~/.claude/CLAUDE.md. Idempotente: se puede volver a ejecutar.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DESTINO="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
MARCA="<!-- BEGIN: enrutado-subagentes -->"
CLAUDE_MD="$DESTINO/CLAUDE.md"

mkdir -p "$DESTINO/agents"

for agente in "$DIR"/agents/*.md; do
  cp "$agente" "$DESTINO/agents/"
  echo "  instalado   $DESTINO/agents/$(basename "$agente")"
done

if [ -f "$CLAUDE_MD" ] && grep -qF "$MARCA" "$CLAUDE_MD"; then
  echo "  ya estaba   bloque de enrutado en $CLAUDE_MD (sin cambios)"
  exit 0
fi

if [ -f "$CLAUDE_MD" ]; then
  cp "$CLAUDE_MD" "$CLAUDE_MD.bak"
  echo "  copia de    $CLAUDE_MD -> $CLAUDE_MD.bak"
  printf '\n' >> "$CLAUDE_MD"
fi

cat "$DIR/bloque-enrutado.md" >> "$CLAUDE_MD"
echo "  añadido     bloque de enrutado en $CLAUDE_MD"
echo
echo "Listo. Abre Claude Code y comprueba con /agents."
