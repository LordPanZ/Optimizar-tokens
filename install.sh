#!/usr/bin/env bash
# Instalación manual para Claude Code: copia los cuatro subagentes a
# ~/.claude/agents/ y añade el bloque de enrutado a ~/.claude/CLAUDE.md.
# Idempotente: se puede volver a ejecutar.
#
# Si lo quieres en Cowork, o compartido entre máquinas, instala el plugin
# en vez de usar este script (ver README).
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN="$DIR/plugins/optimizar-tokens"
DESTINO="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
MARCA="<!-- BEGIN: enrutado-subagentes -->"
CLAUDE_MD="$DESTINO/CLAUDE.md"

mkdir -p "$DESTINO/agents"

for agente in "$PLUGIN"/agents/*.md; do
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

# El texto del enrutado vive una sola vez, en la skill del plugin: aquí se
# reutiliza quitándole el frontmatter YAML.
{
  echo "$MARCA"
  awk 'BEGIN{n=0} /^---$/ && n<2 {n++; next} n>=2 {print}' \
    "$PLUGIN/skills/enrutado/SKILL.md"
  echo "<!-- END: enrutado-subagentes -->"
} >> "$CLAUDE_MD"

echo "  añadido     bloque de enrutado en $CLAUDE_MD"
echo
echo "Listo. Abre Claude Code y comprueba con /agents."
