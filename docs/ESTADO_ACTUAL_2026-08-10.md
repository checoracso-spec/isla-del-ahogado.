# Marea y Ceniza — estado actual

## Verificación del checkpoint

- Godot 4.7.1.
- Rejilla isométrica 128×64; `scripts/mapa/iso.gd` no se ha modificado.
- API pública de `scripts/autoload/almacen.gd` intacta.
- 27 escenas `prueba_*.tscn` ejecutadas en headless.
- 750 comprobaciones instrumentadas en verde; persistencia A/B, viaje global y
  profundidad
  arrancan sin errores reales.
- La escena principal `res://escenas/mundo.tscn` arranca sin `SCRIPT ERROR`,
  `Parse Error`, `Invalid call` ni `Invalid access`.

## Sistemas funcionales presentes

- Inventario base, mochila independiente y cofres persistentes.
- Logística de `Almacen`, cuellos de botella y sustituciones de emergencia.
- Crafteo manual con cola guardable, abastecimiento explícito desde almacén y
  recetas data-driven.
- Mercado con precio por oferta y demanda persistente, taberna, horarios de
  estaciones y medidor de motín.
- `EventosMundo` data-driven y guardable. Ya declara tormenta costera, bloqueo
  de la Corona y marea de naufragios; el bloqueo afecta precios de acero y
  pólvora, y los eventos pueden elevar el riesgo mostrado por el mapa global
  sin conocer nodos.
- Fuentes de recursos data-driven: naufragio, manglar, veta de azufre y
  semillero. Se agotan, regeneran, guardan su identidad y entregan lotes
  completos sin sobrepasar la capacidad del inventario.
- Parcelas de cítricos, caña y tabaco. Sembrar, crecer, cosechar y persistir;
  la cosecha no se ofrece si la mochila no puede recibirla completa.
- Recolección automática opcional de la grúa del muelle. La red se instala
  con tablones y doblones, respeta el horario y sustituye sólo la receta vieja
  de rastrillar la marea después de activarse.
- Rastreo visible en el HUD de fuentes y cultivos, con dirección relativa al
  jugador y estado de cada parcela.
- Interiores explorables, plantas, puertas, cofres y guardado entre procesos.
- Mapa global data-driven con destinos, rutas, viajes y estado guardable.
  El muelle abre un panel de rutas; al llegar, `Mundo` activa una `ZonaRemota`
  provisional, mueve al jugador y adapta la cámara. El embarque de la zona
  permite regresar por una ruta data-driven. Todavía no carga escenas artísticas
  propias para cada destino.
- `BarcoData` y `FlotaMundo` ya representan tres instancias iniciales con IDs
  estables, puerto, destino, estado, salud, armadura, cañones, provisiones y
  bodega basada en `Inventario`. Las rutas asignan automáticamente el barco
  compatible y el estado se guarda entre procesos; combate naval y abordaje
  siguen fuera de alcance.
- Los viajes globales reservan las provisiones necesarias antes de zarpar y
  rechazan la salida cuando la nave no puede cubrir la duración de la ruta;
  una prueba negativa confirma que la nave permanece atracada.
- La isla esta formalizada como `ZonaExterior` y comparte el contrato de
  `Zona` con interiores y zonas remotas; el adaptador es propiedad del mundo
  y se libera con el resto de la escena.
- La prueba A/B de persistencia recupera también un viaje global en curso,
  incluyendo ruta, origen y destino; ahora termina con 37/37 comprobaciones.
- La prueba A/B adicional llega a `isla_ceniza`, cierra el proceso y reconstruye
  la `ZonaRemota` correcta al cargar; son 9/9 comprobaciones nuevas.
- Capas visuales, arte desacoplado mediante `Assets`, paleta maestra y kit de
  placeholders.
- `Actor` como base del jugador y ahora también de `Pirata`; la tripulación
  usa la misma transitabilidad y huella común, sin atravesar casillas
  bloqueadas.

## Fauna

`Animal` ya es una entidad viva basada en `Actor`: conserva hábitat,
velocidad, radio de deambular, ciclo nocturno, identidad y estado plano en
`AnimalesMundo`. La isla instancia ahora una población mínima data-driven
desde `BaseDeDatos`: cerdo salvaje, cabra de montaña y loro vigía. Cada entidad
usa la transitabilidad común, aparece con identidad estable y se incluye en el
guardado; la suite A/B verifica que el cerdo conserva su posición entre
procesos. El gato de barco ya se genera en el puerto y neutraliza la
contramedida declarada por las ratas. Los animales domésticos ya pueden
procesar producción diaria desde datos, con rollback si falta alimento o
capacidad; reproducción, manadas grandes y comportamiento social siguen
pendientes.

## Autoloads registrados

`Reloj`, `BaseDeDatos`, `Plantel`, `Almacen`, `RastreoCarga`, `Motin`,
`Controles`, `GlobalColors`, `Guardado`, `Entidades`, `Assets`, `Bolsa`,
`CraftingManager`, `MercadoManager`, `TabernaManager`, `Ubicacion`,
`Contenedores`, `Interiores`, `RecursosMundo`, `CultivosMundo`,
`AnimalesMundo`, `NpcsMundo`, `DioramasExternos`, `FlotaMundo`, `MapaGlobal` y
`MuelleManager`, `EventosMundo`.

## Límites conocidos

- Las zonas globales todavía son provisionales: no cargan escenas artísticas
  propias ni chunks descargables. La flota valida el tipo de barco y su puerto,
  y la bodega ya admite mercancías mediante el contenedor base, pero todavía
  no implementa tripulación persistente ni capacidad de flota avanzada.
- La fauna visible está limitada por ahora a la población mínima de prueba;
  todavía no hay reproducción, domesticación ni manadas dinámicas.
- No hay combate naval, economía dinámica completa ni NPCs con inventario y
  relaciones avanzadas.
- El arte definitivo sólo está integrado en una parte de los edificios; los
  placeholders técnicos siguen siendo válidos para probar capas y pivotes.

## Últimos checkpoints

- `dc60125` — la instalación de la red del muelle respeta el horario.
- `dc65dae` — capacidad validada antes de recolectar y cosechar.
- `c0f8c31` — rastreo de recursos y cultivos visible en el HUD.
- `0567889` — la tripulación reutiliza `Actor` y la transitabilidad.

## Ultimos checkpoints adicionales

- `31dc933` — formalizacion de la isla como `ZonaExterior`.
- `0206419` — persistencia de viajes globales entre procesos.
- `97d35b4` — entidades animales guardables basadas en `Actor`.
- `9684618` — población mínima de fauna data-driven y posición del cerdo
  verificada entre procesos.
- `e030b18` — transición jugable entre isla y zonas globales provisionales.
- `6df3249` — persistencia entre procesos de la zona global activa.
- `99c8c9a` — flota data-driven mínima vinculada a las rutas globales.
- `1f5d1af` — bodega de barcos basada en `Inventario`, con carga y guardado.

## Reglas de continuidad

1. No tocar `iso.gd` sin una razón técnica excepcional.
2. No cambiar la API pública de `Almacen`.
3. No mezclar `Bolsa` con `Almacen`.
4. Guardar datos planos, nunca referencias a nodos.

## Rutinas de tripulacion incorporadas

`PersonajeData` puede declarar `puesto` y `casa` por separado. `Pirata` conserva
ambos destinos y usa `trabajo` durante los tramos `trabajar`; las llamadas
antiguas a `montar()` siguen funcionando y usan la casa como destino laboral
por compatibilidad. Barbanegra ya demuestra el caso real: vive en la cabana
del capitan y trabaja en la herreria.

El bloque se verifico con 27 suites y 750 comprobaciones, incluido el arranque
de `mundo.tscn`, sin modificar `iso.gd` ni la API publica de `Almacen`.

## Contenido remoto incorporado en este checkpoint

Los destinos globales ya pueden declarar `fuentes` y `cultivos` en
`BaseDeDatos.TABLA_DESTINOS`. `ZonaRemota.montar_contenido()` los instancia al
llegar, reutilizando `FuenteRecurso`, `ParcelaCultivo`, `RecursosMundo`,
`CultivosMundo` y `Entidades`; no existe un segundo sistema de recoleccion.

La configuracion actual es:

- `portobello`: restos de naufragio.
- `isla_ceniza`: veta de azufre, restos de naufragio y tabaco.
- `fortaleza_corona`: restos de naufragio.

El HUD muestra el rastreo de la zona activa. La prueba de viaje verifica el
contenido de Isla Ceniza y la prueba A/B recolecta una veta en el proceso A y
confirma su cantidad restante tras cargar en el proceso B. El checkpoint queda
en 26 suites y 675 comprobaciones, sin errores reales de Godot.

Checkpoint de roster: `c89f221` obtiene los personajes activos desde los campos
`puesto` de `PersonajeData`; `PUESTOS` queda solamente como respaldo para datos
antiguos.

## Persistencia de NPCs

### Inventario y necesidades personales

Cada `Pirata` tiene un `Inventario` personal independiente de `Almacen`, oro
propio y necesidades planas de hambre, energia y moral. `NpcsMundo` guarda
estos datos como diccionarios planos, junto con la posicion y la rutina; nunca
guarda referencias a nodos.

El inventario se obtiene con `Pirata.inventario()` y reutiliza la clase base
`Inventario`. No llama ni modifica la API publica de `Almacen`. La prueba A/B
de NPC confirma que Barbanegra conserva posicion, direccion, tarea, identidad,
inventario, oro y necesidades al cerrar y volver a cargar el juego.

El desgaste y la recuperacion automatica de necesidades salen de la tabla
`NecesidadData`. Ademas, `Pirata.consumir_item_personal()` aplica los campos
`comida` y `moral` de `ItemData` al inventario propio, sin tocar la logistica.
La rutina `Pirata.atender_necesidad_de_rutina()` ya selecciona el consumible
con mayor efecto cuando la tarea es `COMIENDO` o `A_LA_TABERNA`; si no hay
objetos, no inventa recursos ni toca `Almacen`.

`PersonajeData` tambien admite `inventario_inicial`, `oro_inicial` y
`necesidades_iniciales`. Barbanegra, Calico Jack y Dientes de Oro ya declaran
cargas iniciales de ejemplo; los datos se aplican al montar la entidad y los
guardados posteriores vuelven a ser la fuente de verdad.

`TabernaManager.servir_ronda_a()` ofrece una ronda a entidades con inventario
personal. La ruta consume una racion y un ron del NPC y recupera sus
necesidades, sin pasar por `Bolsa`, `Motin` ni `Almacen`. La ruta antigua de la
mochila del jugador sigue separada y cubierta por su prueba existente.

## Trabajadores activos y produccion

`NpcsMundo.trabajadores_activos()` cuenta los NPCs con `puesto_id` coincidente
y tarea `TRABAJANDO`. `EstacionTrabajo` puede activar
`usar_trabajadores_npc` para sustituir el numero estatico por ese conteo;
`Mundo` lo activa para sus estaciones. Asi un horario de NPC afecta la
produccion real: fuera de turno la estacion no progresa, y al volver al puesto
recupera su velocidad configurada por trabajadores. Las escenas de prueba que
crean estaciones aisladas conservan el comportamiento anterior mediante el
valor por defecto `false`.

## Automatizacion de cultivos

`CultivosMundo` ahora ofrece `sembrar_en_almacen()` y
`cosechar_en_almacen()` como rutas logísticas sobre el mismo estado de
parcelas. `RecolectorCultivo` reutiliza esas rutas: puede sembrar cuando hay
semillas, esperar la maduración del reloj y cosechar el lote completo cuando
hay capacidad. La prueba de cultivos cubre el ciclo automático y conserva la
siembra/cosecha manual existente.

La automatización es opcional y data-driven: `CultivoData` puede declarar el
edificio, número de trabajadores y horario del automatizador. `Mundo` y
`ZonaRemota` sólo lo montan para cultivos que declaran esos campos; los demás
siguen siendo parcelas manuales. El estado guardado continúa siendo el de
`CultivosMundo`, por lo que no se serializan referencias a los componentes.
En la isla, además, el automatizador puede consultar `NpcsMundo` para detenerse
cuando no haya un trabajador real en el puesto declarado.

`NpcsMundo` registra las entidades vivas y guarda solo diccionarios planos:
posicion, direccion, destino, tarea y estado. Los piratas tienen identidades
estables; los marineros anonimos usan claves `marinero_0` a `marinero_9`.
La prueba A/B de NPC confirma que Barbanegra conserva su posicion exacta,
direccion, tarea e identidad al cerrar y volver a cargar el juego.

Checkpoint de rutinas: `b77a684` separa vivienda y puesto de trabajo para los
personajes que ya tienen esos datos declarados.

Checkpoint de dimensiones: `7b2d703` hace que el tamaÃ±o de cada zona remota
salga de `DestinoData`; `Mundo` ya no fija una rejilla Ãºnica para todos los
destinos.

Checkpoint de codigo: `bfc0949` valida tambiÃ©n que el jugador recolecta una
veta y siembra tabaco dentro de la zona remota usando las interacciones
existentes.

## Automatizacion de recoleccion del muelle

`RecolectorRecurso` conserva el modo estatico para escenas aisladas, pero puede
activar `usar_trabajadores_npc` para consultar `NpcsMundo.trabajadores_activos()`.
La red de arrastre del muelle usa este modo: si no hay estibadores activos, no
extrae restos; cuando un NPC vuelve a la tarea `TRABAJANDO`, la capacidad vuelve
a estar disponible. La prueba de recoleccion verifica tambien que esta decision
y su configuracion se serializan como datos planos.

El recolector del muelle declara ademas `horario_id = "muelle"`: queda detenido
durante la noche igual que el puesto de gestion y la estacion automatica vieja.

Checkpoint de recoleccion: `a1c81d6` conecta la red de arrastre del muelle con
los estibadores NPC activos y conserva el respaldo estatico.

## Fertilizacion de cultivos

`CultivoData` declara el fertilizante y el multiplicador de crecimiento por
cultivo. `CultivosMundo` permite fertilizar desde la mochila o desde `Almacen`,
consume una unidad, acorta el tiempo restante y guarda el indicador
`fertilizada`. La parcela ofrece la accion durante las etapas de crecimiento y
`RecolectorCultivo` puede ejecutar la misma accion de forma automatica antes de
la cosecha. La prueba de cultivos cubre consumo, aceleracion y persistencia.

El automatizador tambien puede gastar fertilizante desde `Almacen` antes de
cosechar; esa ruta queda cubierta por la prueba de cultivos en mundo.

La prueba de persistencia entre procesos tambien guarda una parcela fertilizada
en el proceso A y verifica el indicador `fertilizada` en el proceso B.

## Oferta dinamica del mercado

`MercadoManager` conserva el stock en un `Inventario` independiente, pero sus
precios ya consultan el indice de oferta respecto al stock objetivo inicial.
Las bandas de escasez y abundancia modifican compra y venta sin mezclar el
mercado con `Almacen`; la prueba de mercado verifica que vaciar el stock de ron
eleva su precio y que el stock sigue guardandose.

Las bodegas de `FlotaMundo` aplican ahora tanto volumen como peso, usando
`ItemData.peso` y `BarcoData.capacidad_peso`; los barcos de partidas antiguas
reciben ese campo desde su definicion al cargar.

Los viajes globales reservan ademas una provision por dia de ruta antes de
despachar. Si la nave no puede cubrir la duracion, conserva su estado de puerto
y el viaje no comienza; la reserva persiste junto con la instancia del barco.

La bitacora del mundo distingue ahora fertilizacion de siembra y cosecha, y la
prueba de cultivos comprueba el mensaje de esa accion.
5. Ejecutar las 26 suites y buscar errores reales después de cada bloque.
