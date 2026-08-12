# Specs

Una carpeta por feature: `specs/<slug>/`, con tres archivos. El slug es
kebab-case y coincide exactamente con el de `state/features/<slug>.json`.

```
specs/
  _template/
    requirements.md
    design.md
    tasks.md
  reserva-de-cancha/
    requirements.md
    design.md
    tasks.md
```

Para empezar una spec: copiá `_template/` a `specs/<slug>/` y completá en orden
—requirements, después design, después tasks. No empieces `design.md` con
`requirements.md` a medias.

---

## `requirements.md` — el qué

Requisitos numerados `R1`, `R2`, … en **notación EARS**. Los IDs son permanentes:
si un requisito se elimina, su número no se reutiliza (queda como `~~R4~~
eliminado en <change>`), porque hay tests y commits que lo referencian.

### EARS — las cinco formas

| Forma | Plantilla | Cuándo |
|---|---|---|
| Ubicua | El sistema **deberá** `<respuesta>` | siempre válido, sin condición |
| Dirigida por evento | **Cuando** `<disparador>`, el sistema **deberá** `<respuesta>` | reacción a algo que pasa |
| Dirigida por estado | **Mientras** `<estado>`, el sistema **deberá** `<respuesta>` | vale durante un estado |
| Opcional | **Donde** `<feature presente>`, el sistema **deberá** `<respuesta>` | depende de una capacidad opcional |
| No deseada | **Si** `<condición no deseada>`, **entonces** el sistema **deberá** `<respuesta>` | manejo de error |

Ejemplos:

```
R1  Cuando un usuario autenticado solicita una reserva para un horario libre,
    el sistema deberá crear la reserva y devolver su identificador.

R2  Si el horario solicitado ya tiene una reserva activa, entonces el sistema
    deberá rechazar la solicitud con un error de conflicto y no crear reserva.

R3  Mientras una reserva está en estado pendiente de pago, el sistema deberá
    bloquear el horario para otras solicitudes.
```

### Reglas

- **Un requisito, una obligación.** Si tiene un "y" que une dos
  comportamientos verificables por separado, son dos requisitos.
- **Verificable.** Si no se te ocurre el test, el requisito está mal escrito.
  "El sistema deberá ser rápido" no es un requisito; "deberá responder en menos
  de 300 ms al percentil 95" sí.
- **Sin tecnología.** Nada de tablas, endpoints, librerías ni nombres de clases.
  Eso es `design.md`.
- **Ambigüedad explícita.** Lo que admita dos lecturas se marca
  `[AMBIGUO: <pregunta concreta>]` y se pregunta. No se resuelve adivinando.

### Criterios de aceptación

Además de los requisitos, la spec cierra con los casos de borde que **no** son
requisitos nuevos pero sí hay que probar: entradas vacías, límites, concurrencia,
autorización. Cada uno se cuelga del requisito que lo cubre (`R2.a`, `R2.b`).

---

## `design.md` — el cómo, y el por qué de ese cómo

Lo importante de este archivo no es el diseño elegido: es el **descarte**. Un
diseño sin alternativas descartadas no se puede evaluar ni revisitar.

Secciones:

1. **Enfoque** — qué se va a hacer, en prosa, en menos de una página.
2. **Alternativas descartadas** — al menos una, con el motivo del descarte. Si
   genuinamente no había alternativa, decilo y explicá por qué.
3. **Contratos** — endpoints, formas de datos, tablas, eventos. Todo lo que se
   referencia y ya existe se verifica en el código antes de escribirlo acá (C8).
4. **Impacto** — qué se toca de lo que ya existe: migraciones, breaking changes,
   comportamiento visible para el usuario.
5. **Riesgos** — qué puede salir mal y cómo se detecta si sale mal.

---

## `tasks.md` — el plan de ejecución

Checklist. Cada tarea:

- Es chica: una sesión de trabajo o menos.
- Referencia los requisitos que cubre: `(R1, R2)`.
- Es verificable al terminar: se sabe si está hecha o no.
- Va en orden de dependencia. Test antes de implementación (C3).

```markdown
- [ ] T1 — Test: crear reserva en horario libre devuelve id (R1)
- [ ] T2 — Test: reserva en horario ocupado devuelve conflicto (R2)
- [ ] T3 — Migración: tabla `reservas` con constraint de unicidad (R1, R2)
- [ ] T4 — Servicio `ReservasService.crear` (R1, R2)
```

Los tildes se actualizan a medida que se completan, en el mismo commit que el
trabajo. `tasks.md` es el estado de progreso real, no una intención.

---

## Trazabilidad

`verify.sh` chequea que para toda feature en `in_progress`, `in_review` o `done`,
cada requisito `R#` de su `requirements.md` esté mencionado en al menos un
archivo de test. La mención es literal: el string `R3` en el nombre del test o en
un comentario adyacente.

```typescript
describe('ReservasService', () => {
  it('R1 — crea la reserva y devuelve su identificador', async () => { ... });
  it('R2 — rechaza con conflicto si el horario está ocupado', async () => { ... });
});
```

Si un requisito no tiene test, `verify.sh` falla. Eso es C3 con exit code.
