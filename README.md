# Optimización de tokens

Cuatro subagentes para Claude Code y Cowork que mantienen el ruido —archivos
completos, salidas de test, barridos de `grep`— fuera del contexto principal.

Cada subagente tiene **su propia ventana de contexto**. Si un agente barato lee
noventa archivos y devuelve seis líneas, esas noventa lecturas nunca entran en
la conversación principal. Lo caro no suele ser razonar: es acarrear.

## Los cuatro agentes

| Agente | Modelo | Herramientas | Para qué |
| --- | --- | --- | --- |
| `explorador` | haiku | Read, Grep, Glob | Buscar y leer. Devuelve `archivo:línea` y un resumen, nunca el archivo. |
| `verificador` | haiku | Bash, Read, Grep | Tests, lint y typecheck. Devuelve **solo los fallos**. |
| `ejecutor` | sonnet | Read, Edit, Write, Grep, Glob, Bash | Cambios mecánicos ya decididos. No diseña. |
| `arquitecto` | opus | Read, Grep, Glob | Planifica en solo lectura. Devuelve un plan, no código. |

El reparto de modelos es deliberado: lo que consume mucho y decide poco va a
haiku; lo que decide mucho y consume poco va a opus.

## Enrutado automático

No hay que nombrar al agente. Un hook `UserPromptSubmit` inyecta en cada turno
una regla corta de delegación, y Claude decide solo a quién pasarle la tarea.

Esto hace falta porque **una skill no basta**: al empaquetar el enrutado solo
como skill, las pruebas mostraron que Claude nunca llegaba a cargarla (0
invocaciones en tres intentos) y se ponía a buscar él mismo. El hook sí entra
siempre, que es justo lo que se necesitaba.

La skill `enrutado` sigue en el plugin con la tabla completa y las siete reglas,
para cuando haga falta el detalle.

## Instalación

### Claude Code

```shell
/plugin marketplace add LordPanZ/Optimizar-tokens
/plugin install optimizar-tokens@optimizar-tokens
/reload-plugins
```

### Cowork

**Customize** → **Plugins** → **Add marketplace** → `LordPanZ/Optimizar-tokens`,
y luego **Browse plugins** → `optimizar-tokens` → **Install**.

### Instalación manual (solo Claude Code, solo esa máquina)

```bash
git clone https://github.com/LordPanZ/Optimizar-tokens.git
cd Optimizar-tokens
bash install.sh
```

Copia los agentes a `~/.claude/agents/` y añade el bloque de enrutado a
`~/.claude/CLAUDE.md` (con copia en `.bak`). Idempotente. No instala el hook: en
esta vía el enrutado va en `CLAUDE.md`, que ya es siempre activo.

Para comprobar que está: pregúntale *"¿qué subagentes tienes disponibles?"*.

## Qué ahorra, medido

Proyecto de prueba de 93 archivos, misma pregunta en todos los casos
("dónde se valida el correo"), con `claude -p` y contabilidad real de tokens:

| | Contexto principal | Salida | Coste |
| --- | --- | --- | --- |
| Sin el plugin (2 tomas) | 249.783 y 294.572 tok | ~1.400 tok | $0,113 y $0,123 |
| Con el plugin, delegando solo | **120.389 tok** | 1.113 tok | $0,126 |

**El contexto principal baja algo más de la mitad** (~272.000 → ~120.000). Ese
es el efecto real y consistente.

**En dinero, en cambio, no ahorra**: en una consulta corta salió un ~7% más
caro. El subagente quema sus propios tokens y eso compensa casi todo lo que se
ahorra arriba. Quien diga que esto abarata cada pregunta, no lo ha medido.

Entonces, ¿para qué sirve? Para que el contexto no se llene. Eso importa cuando
la sesión es larga —menos compactaciones, más rato útil antes de perder el
hilo— y cuando la tarea es tan grande que hacerla del tirón no cabría en la
ventana. En una pregunta suelta y corta, no notarás nada bueno.

## Cuándo NO compensa

- Cambios de una o dos líneas en archivos que ya están en el contexto. El hook
  lo dice explícitamente para que Claude no delegue por inercia.
- Sesiones cortas de una sola pregunta.
- Trabajo no relacionado con código: el `verificador` (tests) y el `ejecutor`
  (refactors) apenas se activarán en Cowork si haces trabajo documental.

El hook cuesta ~160 tokens por turno, siempre, delegues o no. Es el precio de
que sea automático.

## Estructura

```
.claude-plugin/marketplace.json        el repo es su propio marketplace
plugins/optimizar-tokens/
  .claude-plugin/plugin.json           manifiesto
  agents/                              los cuatro subagentes
  skills/enrutado/SKILL.md             tabla de decisión y las siete reglas
  hooks/hooks.json                     inyecta el enrutado en cada turno
install.sh                             instalación manual en ~/.claude/
```

El texto largo del enrutado vive una sola vez, en `SKILL.md`: `install.sh` deriva
de ahí el bloque de `CLAUDE.md` quitándole el frontmatter. El hook lleva aparte
una versión corta, porque se paga en cada turno.

Cada agente es un Markdown con frontmatter (`name`, `description`, `tools`,
`model`) y un prompt debajo. Los límites de líneas y los formatos de respuesta
son el punto donde más se nota tocar.
