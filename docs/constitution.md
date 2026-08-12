# Constitución

Principios no negociables de este proyecto. Todo lo demás —convenciones, stack,
arquitectura, herramientas— es negociable y puede cambiar sin ceremonia. Esto no.

Cada artículo tiene un ID citable (`C1`, `C2`, …). Cuando un review rechaza algo,
debe citar el artículo violado. Cuando un artículo estorba, se enmienda (ver
[Enmiendas](#enmiendas)) — no se ignora en silencio.

---

## C1 — El repositorio es el sistema

Todo estado que importe vive en disco y versionado: specs, decisiones, progreso,
requisitos, criterios de aceptación. El historial de chat es volátil por diseño y
no es fuente de verdad de nada.

**Por qué:** un agente pierde contexto. Un archivo no. Si el trabajo sobrevive
solo mientras dure la sesión, no existe.

## C2 — Nada se implementa sin spec aprobada

Ninguna línea de código de producto se escribe antes de que exista una spec con
requisitos, diseño y tareas, y antes de que un humano la haya aprobado
explícitamente. La aprobación se registra en `state/features/<slug>.json`.

**Excepciones** (no requieren spec): archivos del harness (`docs/`, `specs/`,
`.claude/`, `state/`, `progress/`), configuración de tooling, y correcciones
triviales que no cambian comportamiento observable.

**Por qué:** el costo de escribir la spec es menor que el costo de descubrir a
mitad de la implementación que el problema estaba mal entendido.

## C3 — Sin test, el requisito no está hecho

Todo requisito tiene un ID (`R1`, `R2`, …) y al menos un test que lo verifica y
lo menciona por ID. "Está andando" no es evidencia; un test verde que referencia
el requisito, sí.

**Por qué:** es la única forma de responder "¿esto está terminado?" sin releer
todo el código.

## C4 — La verificación es ejecutable

`./verify.sh` es la única definición de "verde". Si algo importa lo suficiente
para exigirlo, tiene que fallar ahí. Una regla que solo está escrita en prosa es
una sugerencia y se va a ignorar en la iteración 40.

**Por qué:** enforcement fuera del contexto del modelo. El modelo olvida; un
exit code no.

## C5 — Quien implementa no aprueba

El review lo hace un contexto fresco, que no participó de la implementación y no
vio cómo se llegó ahí. Solo ve el diff, la spec y `verify.sh`.

**Por qué:** el mismo contexto que escribió el código ya se convenció de que
está bien. No puede encontrar lo que no vio la primera vez.

## C6 — Un cambio, un propósito

Un cambio hace una cosa. No se mezcla refactor con feature, ni cambio de formato
con cambio de lógica, ni migración con bugfix. Si el diff necesita dos
explicaciones, son dos cambios.

**Por qué:** un diff con un solo propósito se revisa de verdad. Uno con tres se
aprueba por cansancio.

## C7 — Simple antes que general

No se abstrae antes del tercer caso concreto. No se agrega una capa, un genérico,
un flag de configuración o un punto de extensión "para cuando lo necesitemos".
Se agrega cuando se necesita.

**Por qué:** la abstracción prematura es más cara de sacar que de no poner.

## C8 — No se inventan contratos

APIs, tipos, tablas, columnas, eventos, endpoints, variables de entorno y flags
se verifican en el código antes de usarse. Si no se pudo verificar, se dice
explícitamente en vez de asumir.

**Por qué:** es el modo de falla más común y más caro de un agente: código que
compila contra una API que no existe.

## C9 — Los secretos no entran al repo

Nunca: credenciales, tokens, claves privadas, connection strings reales, ni
datos personales reales en código, tests, fixtures, seeds, logs o documentación.
Config sensible por variable de entorno, con `.env.example` documentando las
claves sin los valores.

**Por qué:** un secreto commiteado está comprometido para siempre, incluso si se
borra en el commit siguiente.

## C10 — Nada de datos mock persistentes

No se dejan datos de prueba, usuarios ficticios, clubes de ejemplo ni reservas
sembradas en el estado por defecto de la aplicación. Los fixtures viven en tests
y se limpian. Si hace falta un seed para desarrollo, va en un script explícito y
separado que nunca corre por defecto.

**Por qué:** los datos mock que sobreviven se vuelven indistinguibles de los
reales y contaminan toda decisión posterior.

## C11 — Fallar ruidoso

En procesos que importan no se swallowea el error. Si algo falla, se sabe: error
propagado o log con contexto suficiente para diagnosticar. Nada de `catch {}`
vacío ni de valores por defecto que esconden una falla.

**Por qué:** una falla silenciosa se descubre semanas después, con los datos ya
corruptos.

## C12 — La spec es la fuente de verdad

Si el código divergió de la spec, hay un bug: o se arregla el código, o se
enmienda la spec explicando por qué. Nunca se deja la divergencia sin resolver.

**Por qué:** una spec desactualizada es peor que no tener spec, porque miente
con autoridad.

## C13 — Se reporta lo que pasó

Si un test falla, se dice, con el output. Si un paso se salteó, se dice. Si algo
no se pudo verificar, se dice. No se declara nada terminado sin haber corrido la
verificación.

**Por qué:** un reporte optimista destruye la única cosa que hace útil al
harness, que es poder confiar en su estado.

---

## Enmiendas

Cualquier artículo se puede cambiar, agregar o borrar. Requisitos:

1. Un commit dedicado que toque solo este archivo.
2. El mensaje explica **qué dolor concreto** motivó el cambio. No enmiendas
   preventivas: hace falta un caso real donde el artículo estorbó o faltó.
3. Si el artículo tenía enforcement en `verify.sh` o en un hook, se actualiza en
   el mismo commit.

Log de enmiendas:

| Fecha | Artículo | Cambio | Motivo |
|---|---|---|---|
| 2026-08-12 | C1–C13 | Versión inicial | Arranque del proyecto |
