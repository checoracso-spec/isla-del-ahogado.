# Marea y Ceniza — estado actual

## Verificación del checkpoint

- Godot 4.7.1.
- Rejilla isométrica 128×64; `scripts/mapa/iso.gd` no se ha modificado.
- API pública de `scripts/autoload/almacen.gd` intacta.
- 24 escenas `prueba_*.tscn` ejecutadas en headless.
- 631 comprobaciones instrumentadas en verde; persistencia A/B, viaje global y
  profundidad
  arrancan sin errores reales.
- La escena principal `res://escenas/mundo.tscn` arranca sin `SCRIPT ERROR`,
  `Parse Error`, `Invalid call` ni `Invalid access`.

## Sistemas funcionales presentes

- Inventario base, mochila independiente y cofres persistentes.
- Logística de `Almacen`, cuellos de botella y sustituciones de emergencia.
- Crafteo manual con cola guardable, abastecimiento explícito desde almacén y
  recetas data-driven.
- Mercado, taberna, horarios de estaciones y medidor de motín.
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
  carga plana. Las rutas asignan automáticamente el barco compatible y el
  estado se guarda entre procesos; combate naval y abordaje siguen fuera de
  alcance.
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
procesos. El sistema todavía no implementa reproducción, producción diaria,
manadas grandes ni comportamiento social.

## Autoloads registrados

`Reloj`, `BaseDeDatos`, `Plantel`, `Almacen`, `RastreoCarga`, `Motin`,
`Controles`, `GlobalColors`, `Guardado`, `Entidades`, `Assets`, `Bolsa`,
`CraftingManager`, `MercadoManager`, `TabernaManager`, `Ubicacion`,
`Contenedores`, `Interiores`, `RecursosMundo`, `CultivosMundo`,
`AnimalesMundo`, `DioramasExternos`, `FlotaMundo`, `MapaGlobal` y `MuelleManager`.

## Límites conocidos

- Las zonas globales todavía son provisionales: no cargan escenas artísticas
  propias ni chunks descargables. La flota valida el tipo de barco y su puerto,
  pero todavía no implementa carga real de mercancías, tripulación persistente
  ni capacidad de flota avanzada.
- La fauna visible está limitada por ahora a la población mínima de prueba;
  todavía no hay reproducción, producción diaria, domesticación ni manadas
  dinámicas.
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
- `pendiente` — flota data-driven mínima vinculada a las rutas globales.

## Reglas de continuidad

1. No tocar `iso.gd` sin una razón técnica excepcional.
2. No cambiar la API pública de `Almacen`.
3. No mezclar `Bolsa` con `Almacen`.
4. Guardar datos planos, nunca referencias a nodos.
5. Ejecutar las 24 suites y buscar errores reales después de cada bloque.
