name: "🔵 Fase del Roadmap"
description: "Crear una tarea basada en una fase del roadmap oficial"
title: "Fase X — {Nombre de la fase}"
labels: ["roadmap", "development"]
assignees: []

body:

- type: textarea
  id: description
  attributes:
  label: "🎯 Objetivo de la fase"
  description: "Describe lo que debe lograrse en esta fase según /docs/roadmap.md"
  placeholder: "Implementar el reloj circular base…"
  validations:
  required: true

- type: textarea
  id: scope
  attributes:
  label: "📁 Archivos afectados"
  description: "Lista de archivos nuevos o existentes que deben crearse o modificarse"
  placeholder: "lib/widgets/timer_display.dart"
  validations:
  required: true

- type: textarea
  id: steps
  attributes:
  label: "⚙️ Pasos técnicos"
  description: "Describe cada paso necesario de forma explícita"
  placeholder: "- Crear CustomPainter...\n- Añadir AnimationController..."
  validations:
  required: true

- type: textarea
  id: acceptance
  attributes:
  label: "✔ Criterios de aceptación"
  description: "Condiciones exactas para considerar esta fase completada"
  placeholder: "- Debe animar a 60fps...\n- Debe ser responsive..."
  validations:
  required: true

- type: textarea
  id: references
  attributes:
  label: "📚 Referencias"
  description: "Specs, roadmap u otros documentos relevantes"
  placeholder: "/docs/specs.md – sección 10.4\n/docs/roadmap.md – fase 3"
