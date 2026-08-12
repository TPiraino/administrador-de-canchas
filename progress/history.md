# Historial

Append-only. Una entrada por feature completada (`done`) o descartada
(`archived`). Lo más reciente arriba.

El propósito es poder responder "¿por qué esto está así?" sin arqueología de
git. Cada entrada es corta: qué se hizo, qué salió distinto de lo planeado, y qué
se aprendió que valga para la próxima.

## Formato

```markdown
## AAAA-MM-DD — <slug> (done | archived)

- **Requisitos:** R1–R7
- **Owner:** <usuario>
- **Spec:** specs/<slug>/

Qué se hizo, en dos o tres líneas.

**Desvíos de la spec:** qué se enmendó durante la implementación y por qué.
Si no hubo, decirlo — que no hubo desvíos también es información.

**Aprendizajes:** lo que cambiaría en la próxima. Si algo del harness estorbó,
va acá y se convierte en enmienda.
```

---

_Sin entradas todavía._
