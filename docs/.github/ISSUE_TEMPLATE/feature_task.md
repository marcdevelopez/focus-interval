name: "🟢 Nueva Funcionalidad"
description: "Crear una nueva funcionalidad para la aplicación"
title: "Feature: {Funcionalidad}"
labels: ["feature"]
assignees: []

body:

- type: textarea
  id: summary
  attributes:
  label: "🎯 Resumen"
  placeholder: "¿Qué funcionalidad quieres implementar?"
  validations:
  required: true
- type: textarea
  id: details
  attributes:
  label: "📌 Detalles"
  placeholder: "Describe cómo debe funcionar..."
  validations:
  required: true

- type: textarea
  id: files
  attributes:
  label: "📁 Archivos afectados"
  placeholder: "lib/... etc"
