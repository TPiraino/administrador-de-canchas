# Tareas — <feature>

- **Slug:** `<slug>`
- **Diseño:** `design.md`

Orden de dependencia. Test antes de implementación (C3). Cada tarea referencia
los requisitos que cubre. Los tildes se actualizan en el mismo commit que el
trabajo — este archivo es el progreso real, no una intención.

## Tareas

- [ ] T1 — Test: <caso> (R1)
- [ ] T2 — Test: <caso de error> (R3)
- [ ] T3 — Migración: <qué> (R1)
- [ ] T4 — Implementación: <qué> (R1, R3)
- [ ] T5 — …

## Cierre

- [ ] Todos los requisitos `R#` referenciados en al menos un test
- [ ] `./verify.sh` verde
- [ ] `progress/current.md` actualizado
- [ ] Review con contexto fresco aprobado (C5)
