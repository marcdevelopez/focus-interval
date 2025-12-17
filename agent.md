# 🧭 Guía del agente — Focus Interval

- Consulta `docs/roadmap.md` y `docs/dev_log.md` antes de tocar código para mantener contexto y consistencia.
- Antes de cada commit, revisa si el trabajo requiere actualizar alguno de esos dos archivos; si es necesario, modifícalos en ese mismo commit.
- Cuando edites `docs/dev_log.md` o `docs/roadmap.md`, usa siempre la fecha real del día de trabajo para mantener la trazabilidad temporal.
- Si completas una fase, márcalo en `docs/roadmap.md` (estado global y fase correspondiente) usando la fecha real, y ajusta la FASE ACTUAL si procede.
- Antes de pasar a la siguiente fase, revisa el roadmap: si hay fases previas sin marcar pero ya cumplidas, márcalas con fecha y alinea `docs/dev_log.md` y el estado global del roadmap.
- No hagas commit si hay errores/buils rotas o bugs conocidos sin resolver; confirma que el cambio funciona (al menos compila/analyzer) antes de comitear. Para trabajo incompleto, usa rama aparte o stash en vez de main.
