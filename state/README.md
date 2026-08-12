# state/

Estado de las features, en disco y versionado (C1). Es la fuente de verdad de
"qué está pasando" en el repo.

```
state/
  _template.json          plantilla
  features/
    <slug>.json           un archivo por feature
```

## Un archivo por feature

Deliberado: con varios devs, un único `features.json` sería un conflicto de merge
en cada rama. Con un archivo por feature, dos personas trabajando en features
distintas nunca chocan. Si chocan, es porque las dos tocaron **la misma** feature
— y ahí el conflicto es información útil, no ruido.

## Formato

```json
{
  "slug": "reserva-de-cancha",
  "title": "Reserva de cancha",
  "state": "proposed",
  "owner": null,
  "created": "2026-08-12",
  "approval": null,
  "history": [
    { "date": "2026-08-12", "state": "proposed", "by": "tpiraino", "note": "propuesta inicial" }
  ]
}
```

| Campo | Regla |
|---|---|
| `slug` | kebab-case; **igual** al nombre del archivo y al directorio en `specs/` |
| `title` | una línea, legible |
| `state` | uno de: `proposed`, `spec_draft`, `spec_approved`, `in_progress`, `in_review`, `done`, `archived` |
| `owner` | quién la está llevando. `null` mientras nadie la tomó |
| `approval` | `{ "by": "<humano>", "at": "AAAA-MM-DD" }`. Obligatorio desde `spec_approved` en adelante |
| `history` | append-only. Una entrada por transición de estado, con motivo si fue rechazo o descarte |

## Invariantes que enforcea `verify.sh`

1. `state` está en el conjunto permitido.
2. `slug` coincide con el nombre del archivo.
3. Desde `spec_approved` en adelante, `approval` está completo — **el gate humano
   no se puede saltear** (C2).
4. **Un solo `in_progress` por `owner`.** Un dev, una feature en vuelo. Varios
   devs pueden tener una cada uno.
5. Desde `spec_approved` en adelante, existe `specs/<slug>/` con los tres
   archivos.
6. `history` no se reescribe: solo se agregan entradas.

## Lo que no se hace

No se edita `approval` a mano para habilitar la implementación. El gate existe
porque un humano tiene que leer la spec (C2). Si te encontrás tentado de
editarlo, lo que querés es que alguien apruebe la spec.
