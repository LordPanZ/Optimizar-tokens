# Optimización de tokens

Cuatro subagentes para Claude Code y una skill de enrutado, pensados para que el
contexto principal deje de llenarse de ruido.

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

La quinta pieza es la skill `enrutado`, que lleva la tabla de decisión y las
siete reglas de delegación.

## Dónde funciona

| | Funciona | Cómo |
| --- | --- | --- |
| **Claude Code** | Sí | Plugin, o instalación manual en `~/.claude/` |
| **Cowork** | Sí | Plugin, desde el navegador de plugins de la app de escritorio |
| **Chat (claude.ai)** | **No** | No hay subagentes ni sistema de archivos en Chat |

En Chat esto no aplica, y tampoco tendría mucho sentido: lo que aquí se ahorra
—barridos de repo, suites de tests, lecturas masivas— es trabajo que Chat no
hace.

Una diferencia entre las dos vías que sí funcionan: instalado a mano, el bloque
de enrutado va en `CLAUDE.md` y está **siempre activo**. Como plugin, un
componente no puede inyectar contexto permanente, así que el enrutado viaja como
skill que Claude carga cuando la juzga pertinente. El resto del trabajo lo hacen
las `description` de los agentes, que es el mecanismo nativo de enrutado.

## Instalación

### Opción A: plugin (Claude Code y Cowork)

En Claude Code:

```shell
/plugin marketplace add LordPanZ/Optimizar-tokens
/plugin install optimizar-tokens@optimizar-tokens
```

En Cowork, o si `/plugin` no está disponible en tu entorno, usa el navegador de
plugins de la app de escritorio de Claude.

Para sesiones cloud, declararlo en el `.claude/settings.json` del proyecto:

```json
{
  "extraKnownMarketplaces": {
    "optimizar-tokens": {
      "source": { "source": "github", "repo": "LordPanZ/Optimizar-tokens" }
    }
  },
  "enabledPlugins": {
    "optimizar-tokens@optimizar-tokens": true
  }
}
```

### Opción B: instalación manual (solo Claude Code, solo esta máquina)

```bash
git clone https://github.com/LordPanZ/Optimizar-tokens.git
cd Optimizar-tokens
bash install.sh
```

Copia los cuatro agentes a `~/.claude/agents/` y añade el bloque de enrutado al
final de `~/.claude/CLAUDE.md`, con copia de seguridad en `.bak` si el archivo ya
existía. Es idempotente: se puede volver a ejecutar sin duplicar nada.

`~/.claude/` es por usuario y máquina, no viaja con tu cuenta. Si trabajas en
varias máquinas o quieres esto en Cowork, usa el plugin.

Comprueba que están cargados con `/agents`, o con `claude plugin details
optimizar-tokens`.

## Cómo se usa

Claude delega solo, guiándose por la `description` de cada agente. También
puedes pedirlo a mano:

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

## Qué cuesta y qué ahorra

El plugin no es gratis. Medido con `claude plugin details`:

```
Always-on:   ~509 tok   añadidos a cada sesión
Por delegación: ~710-790 tok cada vez que se invoca un agente
```

Esos ~509 tokens se pagan siempre, aunque no delegues nada. Y cada delegación
cuesta su prompt de sistema más lo que tengas que explicarle al agente, que
arranca en frío y no hereda la conversación.

Así que compensa cuando lo delegado habría costado **más que eso** en el
contexto principal, que es el caso en cuanto hay volumen: un archivo de 400
líneas leído entero ya supera con creces una delegación, y una suite de tests no
tiene comparación. No compensa en cambios pequeños sobre archivos que ya están
en el contexto — la regla 7 del enrutado está precisamente para eso.

Y no convierte cada petición en una delegación: el enrutado es criterio, no un
mecanismo que intercepte nada.

## Dos cosas que conviene saber

**Un subagente arranca en frío.** No hereda la conversación. Si no le dices la
ruta, el nombre del módulo o el formato que esperas, te devolverá algo que no
encaja y habrás pagado dos veces.

**El formato de salida es la mitad del ahorro.** Los cuatro agentes llevan
límites explícitos en su prompt —cuántas líneas puede citar el explorador,
cuántos fallos lista el verificador— porque sin ellos un modelo tiende a
devolver todo lo que ha visto, y entonces el ruido entra igual, solo que por otra
puerta.

## Estructura

```
.claude-plugin/marketplace.json        catálogo: el repo es su propio marketplace
plugins/optimizar-tokens/
  .claude-plugin/plugin.json           manifiesto del plugin
  agents/
    explorador.md                      búsqueda y lectura
    verificador.md                     tests, devuelve solo fallos
    ejecutor.md                        cambios mecánicos ya decididos
    arquitecto.md                      planifica en solo lectura
  skills/enrutado/SKILL.md             tabla de decisión y reglas de delegación
install.sh                             instalación manual en ~/.claude/
```

El texto del enrutado vive **una sola vez**, en `SKILL.md`. `install.sh` deriva
de ahí el bloque de `CLAUDE.md` quitándole el frontmatter, así que no hay dos
copias que se puedan desincronizar.

Cada agente es un Markdown con frontmatter (`name`, `description`, `tools`,
`model`) y un prompt de sistema debajo. Edítalos a tu gusto: los límites de
líneas y los formatos de respuesta son el punto donde más se nota tocar.
