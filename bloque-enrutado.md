<!-- BEGIN: enrutado-subagentes -->
## Enrutado de subagentes (optimización de tokens)

Antes de ponerte a trabajar, decide **quién** hace la tarea. Delegar mantiene el
ruido —archivos completos, salidas de test, barridos de `grep`— fuera de este
contexto: el subagente trabaja en el suyo y aquí solo vuelve su conclusión.

| Si la tarea es… | Delega en | Modelo |
| --- | --- | --- |
| Localizar algo, leer, entender cómo funciona X, barrer muchos archivos | `explorador` | haiku |
| Ejecutar tests, lint o typecheck y saber qué falla | `verificador` | haiku |
| Aplicar un cambio ya decidido: renombrar, migrar una API, repetir un patrón en N archivos | `ejecutor` | sonnet |
| Diseñar un cambio grande, comparar enfoques, decidir arquitectura | `arquitecto` | opus |
| Editar uno o dos archivos que ya tienes leídos, o responder una duda puntual | nadie: hazlo tú | — |

### Reglas

1. **No leas para buscar.** Si no sabes dónde está algo, es del `explorador`.
   Nunca hagas `Read` de un archivo entero para comprobar una línea.
2. **No corras la suite entera aquí.** Los tests los pasa el `verificador`, que
   devuelve solo los fallos.
3. **Planificar y ejecutar son dos pasos.** El `arquitecto` devuelve el plan; el
   `ejecutor` lo aplica. Nunca el mismo agente.
4. **Delega en paralelo** cuando las tareas sean independientes: varias llamadas
   a subagentes en un mismo turno.
5. **Encarga resultados, no procesos.** Pide "dime en qué archivo y línea se
   valida el email", no "busca 'email' en el repo".
6. **Un subagente arranca en frío.** Dale en el prompt todo lo que necesite:
   ruta base, qué buscar, en qué formato responder. No hereda esta conversación.
7. **No delegues lo trivial.** Arrancar un subagente cuesta; para un cambio de
   dos líneas en un archivo que ya tienes abierto, sale más caro que hacerlo.
<!-- END: enrutado-subagentes -->
