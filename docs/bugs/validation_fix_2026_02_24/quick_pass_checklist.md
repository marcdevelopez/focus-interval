# Lista de verificación rápida - Corrección de validación 2026-02-24

Alcance: flujos de cancelación de la cola de late-start, auto-apertura de Pre-Run, auto-apertura de Run Mode, etiquetas de Groups Hub, actualizaciones en vivo de la programación, alineación de las cajas de estado y logout sin pantalla negra.

## Preparación

1. Usa Account Mode con dos dispositivos (macOS como owner, Android como mirror). Asegúrate de que no haya un grupo activo y de que ambos dispositivos tengan Groups Hub abierto.
2. Crea dos grupos planificados con notice=1 min, 1 tarea cada uno, 15 min cada uno:
   - G1 inicia en now+1 min.
   - G2 inicia en (hora de fin de G1 + 2 minutos).
     Ejemplo: si G1 inicia a las 10:01 y termina a las 10:16, configura el inicio de G2 a las 10:18
     Estos son los documentos de taskRunGroups de cada grupo planificado:
     G1:
     actualStartTime
null
(null)


canceledReason
null
(null)


createdAt
"2026-02-24T18:32:07.167541"
(string)


dataVersion
1
(number)


id
"d4938022-f5d9-45ea-a9e5-691e8a49179c"
(string)


integrityMode
"shared"
(string)


lateStartAnchorAt
24 de febrero de 2026 a las 6:54:27 p.m. UTC+1
(timestamp)


lateStartOwnerDeviceId
"macOS-13b84c9b-5215-4c26-972c-970f2a7e13d6"
(string)


lateStartOwnerHeartbeatAt
24 de febrero de 2026 a las 6:59:07 p.m. UTC+1
(timestamp)


lateStartQueueId
"43816858-4b39-4991-977b-34093c578e6f"
(string)


lateStartQueueOrder
0
(number)


noticeMinutes
1
(number)


noticeSentAt
null
(null)


noticeSentByDeviceId
null
(null)


ownerUid
"JKCwF7OCyBdplbpqwZLaJUhgIBH3"
(string)


postponedAfterGroupId
null
(null)


scheduledByDeviceId
"macOS-13b84c9b-5215-4c26-972c-970f2a7e13d6"
(string)


scheduledStartTime
"2026-02-24T18:35:00.000"
(string)


status
"scheduled"
(string)



tasks
(array)



0
(map)



finishTaskSound
(map)


type
"builtIn"
(string)


value
"default_chime_finish"
(string)


longBreakInterval
4
(number)


longBreakMinutes
14
(number)


name
"G1"
(string)


pomodoroMinutes
15
(number)


presetId
null
(null)


shortBreakMinutes
5
(number)


sourceTaskId
"101dd3d4-4b1f-4482-91f6-07f29ddd7c8c"
(string)



startBreakSound
(map)


type
"builtIn"
(string)


value
"default_chime_break"
(string)



startSound
(map)


type
"builtIn"
(string)


value
"default_chime"
(string)


totalPomodoros
1
(number)


theoreticalEndTime
"2026-02-24T18:50:00.000"
(string)


totalDurationSeconds
900
(number)


totalPomodoros
1
(number)


totalTasks
1
(number)


updatedAt
"2026-02-24T18:32:07.203773"

G2:
actualStartTime
null
(null)


canceledReason
null
(null)


createdAt
"2026-02-24T18:32:33.242345"
(string)


dataVersion
1
(number)


id
"02d2a79b-ed07-4760-aa47-2340aa072b11"
(string)


integrityMode
"shared"
(string)


lateStartAnchorAt
24 de febrero de 2026 a las 6:54:27 p.m. UTC+1
(timestamp)


lateStartOwnerDeviceId
"macOS-13b84c9b-5215-4c26-972c-970f2a7e13d6"
(string)


lateStartOwnerHeartbeatAt
24 de febrero de 2026 a las 7:00:07 p.m. UTC+1
(timestamp)


lateStartQueueId
"43816858-4b39-4991-977b-34093c578e6f"
(string)


lateStartQueueOrder
1
(number)


noticeMinutes
1
(number)


noticeSentAt
null
(null)


noticeSentByDeviceId
null
(null)


ownerUid
"JKCwF7OCyBdplbpqwZLaJUhgIBH3"
(string)


postponedAfterGroupId
null
(null)


scheduledByDeviceId
"macOS-13b84c9b-5215-4c26-972c-970f2a7e13d6"
(string)


scheduledStartTime
"2026-02-24T18:51:00.000"
(string)


status
"scheduled"
(string)



tasks
(array)



0
(map)



finishTaskSound
(map)


type
"builtIn"
(string)


value
"default_chime_finish"
(string)


longBreakInterval
4
(number)


longBreakMinutes
14
(number)


name
"G2"
(string)


pomodoroMinutes
15
(number)


presetId
null
(null)


shortBreakMinutes
5
(number)


sourceTaskId
"3cb1fdf4-d55f-4988-b357-fe13451995e7"
(string)



startBreakSound
(map)


type
"builtIn"
(string)


value
"default_chime_break"
(string)



startSound
(map)


type
"builtIn"
(string)


value
"default_chime"
(string)


totalPomodoros
1
(number)


theoreticalEndTime
"2026-02-24T19:06:00.000"
(string)


totalDurationSeconds
900
(number)


totalPomodoros
1
(number)


totalTasks
1
(number)


updatedAt
"2026-02-24T18:32:33.288754"


3. Cierra ambas apps. Espera hasta que pasen ambas horas de inicio.
4. Abre macOS primero, luego Android: ok, aprox a las 18:55

Esperado: Resolve overlaps se abre en ambos dispositivos: ok, se abren y muestran el Resolve overlaps (imagen 01)

## Flujo de pasada única

1. En el owner (macOS), deselecciona todos los grupos y pulsa Continue.

Esperado: Esto se comporta exactamente como Cancel all. Los grupos se cancelan, el mirror muestra un modal "Owner resolved" con OK, y ambos vuelven a Groups Hub sin pantalla negra.
no ocurrio asi excatamente, deseleccione los dos grupos del Resolve overlaps y pulse conmtinue, y apareció:
Cancel all groups?
No groups are selected. Continue will
cancel all listed groups. You can re-plan
them from Groups Hub.
Keep Cancel all

y pulsé cancell all (imagen 02)

como se puede observar en la imagen 03, el modal aparece en vez de en el mirror, en el owner que canceló los grupos, y en el mirror (dispositivo de la derecha, android) no aparece ningun modal. y ademas de eso en el mirror termina habilitando seguir con el Resolve overlaps como se fuese owner en ese momento. no se resolvio nada de este bug, nada, y ademas en el owner (macos) al pulsar el ok del modal Owner resolved, no desaparece el modal, sino que hay que pulsar fuera del modal para que desaparezca.

firebase en ese momento:
 G2:
 actualStartTime: ทน//
canceledReason: "missedSchedule"
createdAt: "2026-02-24T18:32:33.242345"
dataVersion: 1
id: "02d2a79b-ed07-4760-aa47-2340aa072b11"
integrityMode: "shared"
lateStartAnchorAt: null
lateStartClaimRequestId: null
lateStartClaimRequestedAt: null
lateStartClaimRequestedByDeviceId: null
lateStartOwnerDeviceld: null
lateStartOwnerHeartbeatAt: null
lateStartQueueld: null
lateStartQueueOrder: null
noticeMinutes: 1
noticeSentAt: null
noticeSentByDeviceId: null
ownerUid: "JKCwF7OCyBdplbpqwZLaJUhgIBH3"
postponedAfterGroupId: null
scheduledByDeviceld: "macOS-13b84c9b-5215-4c26-972c- 970f2a7e13d6"
scheduledStartTime: "2026-02-24T18:51:00.000"
status: "canceled"
tasks
finishTaskSound
type: "builtin"
value: "default _chime_finish"
LongBreakInterval: 4
LongBreakMinutes: 14
name: "G2"
pomodoroMinutes: 15
presetid: null
shortBreakMinutes: 5
sourcelaskid: "3cb1fdf4-d55f-4988-b357-
fe13451995e7"
- startBreakSound
type: "builtin"
value: "default_chime_break"
• startSound
type: "builtin"
value: "default_chime"
totalPomodoros: 1
theoreticalEndTime: "2026-02-24T19:06:00.000"
totalDurationSeconds: 900
totalPomodoros: 1
totalTasks: 1
updatedAt: "2026-02-24T19:01:24.872590"

G1:
actualStartTime: null
canceledReason: "missedSchedule"
createdAt: "2026-02-24T18:32:07.167541"
dataVersion: 1
id: "d4938022-f5d9-45ea-a9e5-691e8a49179c"
integrityMode: "shared"
lateStartAnchorAt: null
lateStartClaimRequestId: null
lateStartClaimRequestedAt: null
lateStartClaimRequestedByDeviceId: null
lateStartOwnerDeviceId: null
lateStartOwnerHeartbeatAt: null
lateStartQueueld: null
lateStartQueueOrder: null
noticeMinutes: 1
noticeSentAt: null
noticeSentByDeviceId: null
ownerVid: "JKCwF7OCyBdplbpqwZLaJUhgIBH3"
postponedAfterGroupId: null
scheduledByDeviceId: "macOS-13b84c9b-5215-4c26-972c-
970f2a7e13d6"
scheduledStartTime: "2026-02-24T18:35:00.000"
status: "canceled"
tasks
"
- finishTaskSound
type: "builtin"
value: "default_chime_finish"
LongBreakInterval: 4
LongBreakMinutes: 14
"
name: "G1"
pomodoroMinutes: 15
presetId: null
shortBreakMinutes: 5
sourceTaskId: "101dd3d4-4b1f-4482-91f6-
07f29ddd7c8c"
startBreakSound
type: "builtin"
value: "default_chime_break"
startSound
type: "builtin"
value: "default _chime"
totalPomodoros: 1
theoreticalEndTime: "2026-02-24T18:50:00.000"
totalDurationSeconds: 900
totalPomodoros: 1
totalTasks: 1
updatedAt: "2026-02-24T19:01:24.872590"

2. Crea un nuevo grupo planificado (G3) con notice=1 min y hora de inicio now+1 min. Cierra ambas apps y espera hasta que pase la hora de inicio:
este es el scheduled:
actualStartTime
null
(null)


canceledReason
null
(null)


createdAt
"2026-02-24T19:29:39.715563"
(string)


dataVersion
1
(number)


id
"48778026-521e-4e70-8fab-b3cec9717dc8"
(string)


integrityMode
"shared"
(string)


lateStartAnchorAt
null
(null)


lateStartClaimRequestId
null
(null)


lateStartClaimRequestedAt
null
(null)


lateStartClaimRequestedByDeviceId
null
(null)


lateStartOwnerDeviceId
null
(null)


lateStartOwnerHeartbeatAt
null
(null)


lateStartQueueId
null
(null)


lateStartQueueOrder
null
(null)


noticeMinutes
1
(number)


noticeSentAt
null
(null)


noticeSentByDeviceId
null
(null)


ownerUid
"JKCwF7OCyBdplbpqwZLaJUhgIBH3"
(string)


postponedAfterGroupId
null
(null)


scheduledByDeviceId
"android-1e86bcdc-2aaf-442d-836c-b2edeae065cf"
(string)


scheduledStartTime
"2026-02-24T19:32:00.000"
(string)


status
"scheduled"
(string)



tasks
(array)



0
(map)



finishTaskSound
(map)


type
"builtIn"
(string)


value
"default_chime_finish"
(string)


longBreakInterval
4
(number)


longBreakMinutes
14
(number)


name
"G3"
(string)


pomodoroMinutes
15
(number)


presetId
null
(null)


shortBreakMinutes
5
(number)


sourceTaskId
"210528dc-9da1-4b38-936a-ad426b669892"
(string)



startBreakSound
(map)


type
"builtIn"
(string)


value
"default_chime_break"
(string)



startSound
(map)


type
"builtIn"
(string)


value
"default_chime"
(string)


totalPomodoros
1
(number)


theoreticalEndTime
"2026-02-24T19:47:00.000"
(string)


totalDurationSeconds
900
(number)


totalPomodoros
1
(number)


totalTasks
1
(number)


updatedAt
"2026-02-24T19:29:39.780705"


 Abre macOS primero, luego Android.

Esperado: Resolve overlaps se abre en ambos dispositivos para G3.

abro macos a las 19:33:30, y como no hay mas grupos planificados y es unico sin solapamiento se abre normalmente en timer run.
el checklist esta mal hecho y coomo solo se crea un grupo planificado, se abre simplemente a la hora que se abre la app en macos y se ejecuta directamente el timer run del grupo ya que no hay conflicto con ningun otro grupo por delante de él.


4. Crea dos nuevos grupos planificados con notice=1 min:
   - G4 
   - G5 start at end of G4 +1 min

Esperado: En las cards de Groups Hub, la fila Scheduled muestra la hora de inicio de la ejecución, y una fila Pre-Run separada muestra "Pre-Run X min starts at HH:MM" cuando aplica el notice.
ok, lo hizo

5. Mantén un dispositivo en Groups Hub y otro en Task List. Espera el pre-run de G4.

Esperado: Pre-Run se abre automáticamente en ambos dispositivos sin rebote a Groups Hub y sin navegación duplicada.

ok funciono, se abrio timer run mode del grupo al terminar el pre-run.

sin embargo, 
cuando ya estaba en timer run runnig despues de terminar el pre-run, este era el group hub del grupo que estaba en pre-run:
G4
Status: scheduled
Scheduled: 19:42
Pre-Run: 1 min starts at 19:41
Ends: 19:57
Tasks: 1
Total time: 15m

 cuando le quedan en el timer: 14:41 y son las 19:42:20 (es decir a los 20 segundos de comenzar), estando planeado para comenzar el grupo G5 (siguiente grupo planificado) a las 19:58, con pre-run a las 19:57 (pero el running actual segun hora actual y timer restante, da exacto las 19:57 y un segundo  (no presioné en ningun momento el boton de pausa)), de modo que se abre el modal:
 Scheduling conflict
A scheduled group is about to start while
this group is still active.
G5
Scheduled: 19:58-20:13
Pre-Run: 19:57
End current group
Postpone scheduled
Cancel scheduled

lo que da una idea de que el modal se abre de forma erronea por la proximidad que puede dar solape, del actual grupo running y el siguiente grupo planificado de forma esxacta el mismo minuto de fin del running con el comienzo del pre-run del grupo planificado. de modo que o se busca solucion a este caso extremo (cualquier latencia o dato de hora actual o de conteo del timer que no sea totalmente exacto da lugar a conflicto, de modo que creo que la solucion mas segura es dejar un margen de un minuto para estos casos, o bien se avise al usuario o si se crean colas de grupos en conflicto que se creeen con esa separacion para evitar este problema o directamente tambien al planificar que no se deje que coincida el mismo minuto de fin de grupo con el comienzo del siguiente grupo o pre-run en su caso).
se cancelo G5.

7. En Run Mode para G4, pausa el tiempo suficiente para que llegue la hora de pre-run de G5:

Para probar esto tube que volver a re-plan group el G5 cancelado, como el actual running tiene como ends (dato obtenido de groups hub) 20:20, pulse Schedule by start time en groupss hub para re-plan G5 a las 20:22 y asegurar que no hubiera problemas, esta diferencia de 2 minutos la puse para evitar el problema comenrado antes por proximidad de final de running y pre-run del siguiente grupo planificado. de modo que quedó asi G5 en groups hub, a las 20:09:

Scheduled
G5
Status: scheduled
Scheduled: 20:22
Pre-Run: 1 min starts at 20:21
Ends: 20:37
Tasks: 1
Total time: 15m
 
G4 tenia esto en groups hub a las 20:09:32:
Running / Paused
G4
Status: running
Ends: 20:20
Tasks: 1
Total time: 15m

pausé el running G4 (imagen 04), a las 20:09:49, cuando el timer del running mostraba en timer run mode: 11:06. 
saltó el modal de conflicto (imagen 05) a las 20:09:56 (de modo que fueron 6 o 7 segundos de pausa hasta que saltó el modal), y si sumamos la hora en que se pausó el running + lo mostrado en timer al pausar + la duracion de la pausa hasta que saltó el modal de conflicto, nos dá: las 20:21:02 (quizá 01 ya que el redondeo puede haber sumado algo), es correcto y funciona perfecto el momento de mostrar el modal.
De modo que esta parte en este casom concreto, ok.

8. Elige Postpone.

Esperado: El owner muestra una confirmación. El Groups Hub del mirror actualiza el inicio y fin programados en vivo, sin esperar a reanudar:

Lo que ocurrio en la prueba de validación fue:
Se pulsó Postpone scheduled a las 20:10:08 (imagen 05), y mostró (imagen 07) el snackbar con:
Scheduled start moved to 20:23 (pre-run at
20:22).
y en groups hub quedo planificado de nuevo pero la hora de scheduled no era correcta, ya que en el snackbar se mostraba que era a las 20:23 la nueva hora:
Scheduled
G5
Status: scheduled
Scheduled: 20:22
Ends: 20:37
Tasks: 1
Total time: 15m
Notice: 1 min

al pulsar el item el summary group del grupo G5 muestra lo mismo, 20:22.

9. Reanuda el grupo en ejecución.

Esperado: Las cajas de estado (Pomodoro range y End of group) coinciden con el rango de tiempo de la fila de la tarea actual y la tarjeta de ejecución en Groups Hub.

Esto ocurrió al pulsar resume (imagen 08):
la caja de estado no coincide el comienzo de pomodoro con el rango de tiempo de la fila de la tarea actual, ya que la caja de estado del actual fase (pomodoro) 20:06-20:21, con el rango de tiempo de la fila de la tarea actual (20:05-20:21), parece que ahora la caja de estado mueve el start la misma duracion que es movida para el end (1 minuto) y eso no es correcto, el start, lo que queda en el pasado, no se debe de modificar, ni en caja de estados ni en rango de tiempo de la fila de la tarea (ni en groups hub).
Ademas en groups hub parece que no se atrasó el comienzo del grupo postpuesto a 20:23 ya que sigue apareciendo que comienza a las 20:22.

Antes lo cual vuelvo a pulsar pausa en el running para ver qué ocurre (imagen 09):
la hora de esta pausa fue 20:10:59, el pomodoro del timer iba por 10:50.
a las 20:11:14 se actualizó lo mostrado en groups hub del grupo G5 planificado:
Scheduled
G5
Status: scheduled
Scheduled: 20:23
Ends: 20:38
Tasks: 1
Total time: 15ml
Notice: 1 min

el tiempo de pausa fue hasta esta actualizacion en groups hub: 15 segundos.
el timer marcaba 10:50 al pausar el running.
si sumamos nos da un final de grupo running desde el momento de la actualizacion del groups hub a las: 20:22:04, de modo que parece que como esa era la hora del pre-run y aun sigue pausado y se solapa el end del running G4 con el start del G5 planificado, como ya está implementado y reflejado en specs, se retrasa de forma automatica el grupo planificado que se replanificó en postpose detras del running, y funciona correctamente, ya que no salta el modal de conflicto y se actualiza para evitar el solapamiento. lo unico que quiza haya que mejorar aqui es que para que no haya problemas a la hora de terminar el pre-run y haya conflicto o cosas raras al comeinzo del start del grupo que acaba su pre-run, que haya una diferencia mantenida de 1 minutos siempre entre el End de un grupo y el start (scheduled) del siguiente grupo, y luego se sume la duracion del pre-run notice fijado, que en este caso seria ese minuto mas el notice seteado en ajustes al planificar el grupo que en este caso era de 1 min, darian 2 minutos de diferencia en este caso entre el end y el start del scheduled que le sigue en proximidad en groups hub. lo entiendes? eso habria que avisarlo en algun lugar conveniente al usuario para que sepa el motivo de ese minuto extra de separacin, para evitar solapes y conflicto por latencias o inexactitudes del momento, y asi creo que evitariamos el problema del comienzo del start parado cuando solo hay un minuto de diferencia y da conflicto cuando no deberia de dar. si cres que el motivo del bug es otro comentamelo, pero desde mi vision fuera del codigo, creo que esto solucionaria algun bug de los mostrados en este reporte.
por lo comentado en este puneto era el motivo de que no se mostrara el modal, porque ya esta en specs y creo que tambien implementado este "arrastre" de tiempo en al grupo re-planificado tras solucionar un conflicto con postpone, rectificame si me equivoco.

volvi a reanudar a las 20:11:28 (imagen 11):
el timer marcaba 10:50 de pomodoro, y la caja de estado se actualizó a:
Pomodoro 1 of 1
20:07-20:22
End of group
20:22

lo cual es incorrecto ya que está arrastrando el comienzo con el final del pomodoro, cosa totalmente incorrecta lo cual es un nuevo bug y de regresión ya que esto creo recordar que ya funcionaba bien en implementaciones pasadas. sin embargo el item de tarea actual sigue correcto:
G4 20:05-20:22
Y el ends de running se actualiza (aunque se deberia de actualizar en tiempo real, no solo cuando se pulsa resume, esto tambien es un bug y se debe de solucionar).
scheduled parece que funciona correctamente:
Scheduled
G5
Status: scheduled
Scheduled: 20:23
Ends: 20:38
Tasks: 1
Total time: 15m
Notice: 1 min

al llegar al final del timer running actual (imagen 12), cuando iba el running por: 00:07, hora actual 20:22:14 y el scheduled estaba asi planeado:
Scheduled
G5
Status: scheduled
Scheduled: 20:23
Ends: 20:38
Tasks: 1
Total time: 15m
Notice: 1 min

cambió en el mirror (el mirror estaba en groups hub), el botón del scheduled G5 a "Open Pre-Run". lo cual indica 1ue como llegó la hora del pre-run y aún estaba ejecutandose el running del grupo actual, comenzó el pre-run del siguiente, es decir, en vez de haber saltado un modal avisando del conflicto, como se ha implementado que no se abre de nuevo conflcito en los re-planificados por postpose, (y G5 cumple esta situacion), se comenzó el pre-run pero sin mostrarse en el timer ya que el timer estaba ocupado por el grupo running acrtual (G4), y no se muestra pre-run ni en mirror ni en owner, pero esta circunstancia es incorrecta, y posiblemente debida a la conbinación de no volver a mostrar modal de conflicto en postposed, y ademas por no dejar ese minuto extra entre el fin de actual grupo running u otro grupo planeado y el comienzo de siguientes grupos planeados. quiza esto explique la situación, y aunque se deberia de mantener el hecho de arrastrar el tiempo de comienzo de los grupos postposed, no se deberia de permitir que el minuto de end coincida con el mismo minuto de: start de otro grupo mas su duracion de pre-run, es decir que el pre-run, dure 0 (es decir que no haya) o dura lo que dure que no coincida ese mismo minuto con el mismo que el fin del anterior grupo en tiempo. comprendes?
En esta situacion lo que hice fue:
lo que ocurrió solo es pura anecdota para eviotar futuros bugs, ya que son situaciones que no deben de darse pero las reporto para que se vea como actua el actual sistema ahora:
pulsé "open pre-run" en el scheduled G5 cuando aun quedaban 2 segundos del grupo running (imagen 13):
Eso lo hice en mirror android, y abrió el pre-run por donde denería de ir, es decir 54 segundos (imagen 14), sin embargo, si sumamos 54 a 10:22:19, nos da mas de las 20:23:00, que es el tiempo de comienzo del grupo, de modo que no es exacto el comeinzo de grupo, es inconsistente y lo mas seguro es que rompa la ejecucion del pre-run o algo similar, una razon mas para evitar esta situcion en la ejecucion de la app.
cuando el grupo running G4 termina muestra pantalla de final de grupo correcto, son las 20:22:20 (imagen 15), y entonces cuando quedan en el pre-run simultaneo en mirror 52 segundos y es aun las 22:22:21, el timer de mirror pasa a pantalla de ready (15:00) con boton de start deshabilitado y aun con el icono en appbar de pre-run (imagen 16), esto ocurre en farcción de segundo, pasa a Loading group... en mirror y muestra tambien el modal de:
Tasks group
completed
Total tasks: 1
Total pomodoros: 1
Total time: 15m
OK

en este momento los dos dispositivos estan de esta manera (imagen 17), pero esperando a que se pulse el boton de ok del modal en ambos dispositivos owner y mirror. pulso ok en owner y se abre groups hub (imagen 19), donde aparece G4 como completed y G5 como scheduled con boton start now.
pulso despues el mismo boton de ok del final de grupo en el mirror, y tambien se abre groups hub, con misma informacion que en el owner. 
ahora en scheduled G5 aparece esto:
Scheduled
G5
Status: scheduled
Scheduled: 20:24
Pre-Run: 1 min starts at 20:23
Ends: 20:39
Tasks: 1
Total time: 15m

de modo que se ha postpuesto el comienzo para que el pre-run sea en el proximo minuto, esto seria correcto, si no fuera por el error anterior de coincidir pre-run y running del. anterior grupo al mismo tiempo (solapamiento) pero en este sentido lo que pasa a continuacion sería correcto por guardar esta diferencia para el comienzo correcto de pre-run y grupo planificado con postpone.

algo que se observa y que tambien es un bug (imagen 19), siendo las 20:22:39 ahora, es que mientras que en owner (macos en este caso concreto) se muestra:
Scheduled
G5
Status: scheduled
Scheduled: 20:24
Pre-Run: 1 min starts at 20:23
Ends: 20:39
Tasks: 1
Total time: 15m

en el mirror (android en este caso concreto), se muestra esto:
Scheduled
G5
Status: scheduled
Scheduled: 20:24
Ends: 20:39
Tasks: 1
Total time: 15m
Notice: 1 min

de modo que no se añade en mirror la linea Pre-Run: 1 min starts at 20:23, sino que se sigue mostrando Notice: 1 min. esto debe de ser coherente e igual en ambos, si no es asi en specs debe de detallarse e implementarse, que se muestre lo mismo en todos los dispositivos en el groups hub.

al llegar la hora del pre-run del grupo postoned planeado, se abre correctamente (ambos estaban abiertos en groups hub) la pantalla de timer en pre-run correcto y a la hora exacta. habilitandose enm mirror y owner el boton de cancel.

al terminar el pre-run, ambos pasan a pantalla de syncing session... un instante de centesima de segundo y abre correctamente el timer run mode del grupo G5.

sin embargo (imagen 20), se observa que aunque en running del groups hub se muestra correctamente el End en 20:39 ya que comenzo a las 20:24, en las cajas se muestra tambien bien en este comienzo de grupo, pero en el item de tarea actual que se muestra en el timer running, no es correcto y se muestra con un minuto menos:
G5 20:23-20:38
cosa que no se corrige ni solicitando owner y haciendo cambio de owner, en dicho item de tarea actual (el que se muestyra bajo el circulo del timer run) sigue mostrando el rango de tiempo con un minuto menos, en la caja de estado muestra:
Pomodoro 1 of 1
20:24-20:39
End of group
20:39
esta vez la caja de estado es correcta.

esto tambien es un bug que se ha de corregir.

al cancelar el grupo, en groups hub muestra en canceled el grupo G5 cancelado de forma correcta ya que muestra Ends: 20:39.

10. Mientras el grupo está en ejecución o pausado, abre Task List y cierra sesión.

Esperado: Sin pantalla negra. La app vuelve a login o a Task List de Local Mode.

Esto dio un problema, pero al cerrar la app y probarlo en web y en macos, y luego volver a abrir android, se soluciono, parece que en esta ultima implementacion se soluciono en parte, se informará en reporte o mas adelante dentro de este mismo reporte si vuelve a suceder.

Nota:
Aun en un caso se ha ido despues de terminar un grupo, en vez de a groups hub, a la pantalla de ready, con timer en la duracion del pomodoro de la tarea, y con boton de start abajo. esto no debe de suceder, se tiene que asegurar que nunca al terminar un grupo su ejecucion que quede en pantalla de ready, sino que vaya a groups hub. revisa cuidadosamente todas las posibles causas y solucionalo de forma definitiva, sin parches, sin de forma eficiente y de raiz, sin ocasionar mas bugs.
