# Optimización de tokens

Cuatro subagentes para Claude Code y un bloque de enrutado, pensados para que
el contexto principal deje de llenarse de ruido.

La idea es sencilla: **cada subagente tiene su propia ventana de contexto**. Si
un agente barato lee treinta archivos y devuelve seis líneas, esas treinta
lecturas nunca entran en la conversación principal. Lo caro no suele ser
razonar: es acarrear.

## Los cuatro agentes

| Agente | Modelo | Herramientas | Para qué |
| --- | --- | --- | --- |
| `explorador` | haiku | Read, Grep, Glob | Buscar y leer. Devuelve `archivo:línea` y un resumen, nunca el archivo. |
| `verificador` | haiku | Bash, Read, Grep | Tests, lint y typecheck. Devuelve **solo los fallos**. |
| `ejecutor` | sonnet | Read, Edit, Write, Grep, Glob, Bash | Cambios mecánicos ya decididos. No diseña. |
| `arquitecto` | opus | Read, Grep, Glob | Planifica en solo lectura. Devuelve un plan, no código. |

El reparto de modelos es deliberado: lo que consume mucho y decide poco va a
haiku; lo que decide mucho y consume poco va a opus. Sonnet queda en medio,
aplicando lo que ya está decidido.

## Instalación

```bash
git clone https://github.com/LordPanZ/Optimizar-tokens.git
cd Optimizar-tokens
bash install.sh
```

El script copia los cuatro `.md` a `~/.claude/agents/` y añade el bloque de
enrutado al final de `~/.claude/CLAUDE.md` (hace copia de seguridad en `.bak` si
el archivo ya existía). Se puede volver a ejecutar sin duplicar nada.

Para instalarlo solo en un proyecto en vez de en todo tu usuario, copia
`agents/` a `.claude/agents/` dentro del proyecto y pega `bloque-enrutado.md` en
su `CLAUDE.md`.

Comprueba que están cargados con `/agents` dentro de Claude Code.

## Cómo se usa

Con el bloque de enrutado en `CLAUDE.md`, Claude delega solo. También puedes
pedirlo a mano:

```
Usa el explorador para localizar dónde se valida el email en el registro.
Pásale el arquitecto y que me devuelva un plan para migrar a Zod.
```

Un flujo completo, con el reparto que busca este repo:

1. **`arquitecto`** lee el terreno y devuelve el plan. Caro, pero una vez.
2. **`ejecutor`** aplica los pasos del plan. Ni relee ni redecide.
3. **`verificador`** corre los tests y devuelve los tres que fallan.
4. **`ejecutor`** arregla esos tres.

El contexto principal ha visto un plan, una lista de archivos tocados y tres
fallos. No ha visto ni un archivo entero ni una salida de test.

## Qué ahorra y qué no

Ahorra cuando la tarea genera **mucho texto intermedio que no hace falta
conservar**: búsquedas amplias, suites de tests, cambios repetitivos en muchos
archivos, exploración de código desconocido.

No ahorra —y probablemente cueste más— en cambios pequeños sobre archivos que ya
están en el contexto. Arrancar un subagente tiene su propio coste fijo: se le
manda su prompt de sistema y hay que explicarle desde cero lo que la
conversación principal ya sabe. La regla 7 del bloque de enrutado está
precisamente para eso.

## Dos cosas que conviene saber

**Un subagente arranca en frío.** No hereda la conversación. Si no le dices la
ruta, el nombre del módulo o el formato que esperas, te devolverá algo que no
encaja y habrás pagado dos veces.

**El formato de salida es la mitad del ahorro.** Los cuatro agentes llevan
límites explícitos en su prompt —cuántas líneas puede citar el explorador,
cuántos fallos lista el verificador— porque sin ellos un modelo tiende a
devolver todo lo que ha visto, y entonces el ruido entra igual, solo que por
otra puerta.

## Estructura

```
agents/
  explorador.md      búsqueda y lectura
  verificador.md     tests, devuelve solo fallos
  ejecutor.md        cambios mecánicos ya decididos
  arquitecto.md      planifica en solo lectura
bloque-enrutado.md   lo que se añade a ~/.claude/CLAUDE.md
install.sh           instalador idempotente
```

Cada agente es un Markdown con frontmatter (`name`, `description`, `tools`,
`model`) y un prompt de sistema debajo. Edítalos a tu gusto: los límites de
líneas y los formatos de respuesta son el punto donde más se nota tocar.
