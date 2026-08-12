# Diseño — <feature>

- **Slug:** `<slug>`
- **Requisitos:** `requirements.md`

## Enfoque

Qué se va a hacer, en prosa. Menos de una página. Si no cabe, el alcance es
demasiado grande y hay que partir la feature.

## Alternativas descartadas

Al menos una. Sin esto el diseño no se puede evaluar ni revisitar.

### <alternativa>

Qué era, y por qué no. El motivo tiene que ser concreto — "más complejo" no es un
motivo, "requiere una tabla extra y un job de sincronización para ganar algo que
todavía no necesitamos (C7)" sí.

## Contratos

Todo lo que se referencia y ya existe se verifica en el código antes de
escribirlo acá (C8). Marcá con ✅ lo verificado y con ⚠️ lo que no se pudo
verificar.

### Datos

Tablas, columnas, tipos, constraints, índices. Migraciones necesarias.

### API

Endpoints: método, path, request, response, códigos de error.

### Eventos / jobs

Si aplica: qué se emite, quién consume, idempotencia, retries, timeouts.

## Impacto

- **Migraciones:** …
- **Breaking changes:** …
- **Comportamiento visible:** qué cambia para el usuario final.
- **Módulos que se tocan:** …

## Riesgos

Qué puede salir mal, y **cómo se detecta** si sale mal. Un riesgo sin forma de
detectarlo es un riesgo que vas a descubrir por el reclamo de un usuario (C11).

| Riesgo | Detección | Mitigación |
|---|---|---|
| | | |
