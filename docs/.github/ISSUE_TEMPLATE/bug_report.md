name: "🐞 Bug Report"
description: "Reportar un error encontrado en el sistema"
title: "Bug: {Descripción breve}"
labels: ["bug"]
assignees: []

body:

- type: input
  id: environment
  attributes:
  label: "🖥 Entorno"
  placeholder: "macOS / Windows / Linux"

- type: textarea
  id: what-happened
  attributes:
  label: "❌ ¿Qué ocurrió?"
  placeholder: "Describe el error…"
  required: true

- type: textarea
  id: expected
  attributes:
  label: "✔ ¿Qué esperabas que ocurriera?"
  placeholder: "Describe el comportamiento correcto…"

- type: textarea
  id: steps
  attributes:
  label: "🧪 Pasos para reproducir"
  placeholder: "1… 2… 3…"
