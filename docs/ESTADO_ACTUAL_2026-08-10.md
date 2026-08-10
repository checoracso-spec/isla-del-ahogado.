# Marea y Ceniza — estado actual

## Verificación del checkpoint

- Godot 4.7.1.
- Rejilla isométrica 128×64; `scripts/mapa/iso.gd` no se ha modificado.
- API pública de `scripts/autoload/almacen.gd` intacta.
- 19 escenas `prueba_*.tscn` ejecutadas en headless.
- 564 comprobaciones instrumentadas en verde; persistencia A/B y profundidad
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
- Mapa global data-driven con destinos, rutas, viajes y estado guardable;
  todavía usa zonas remotas provisionales y no cambia la escena jugable al
  llegar.
- Capas visuales, arte desacoplado mediante `Assets`, paleta maestra y kit de
  placeholders.
- `Actor` como base del jugador y ahora también de `Pirata`; la tripulación
  usa la misma transitabilidad y huella común, sin atravesar casillas
  bloqueadas.

## Autoloads registrados

`Reloj`, `BaseDeDatos`, `Plantel`, `Almacen`, `RastreoCarga`, `Motin`,
`Controles`, `GlobalColors`, `Guardado`, `Entidades`, `Assets`, `Bolsa`,
`CraftingManager`, `MercadoManager`, `TabernaManager`, `Ubicacion`,
`Contenedores`, `Interiores`, `RecursosMundo`, `CultivosMundo`,
`DioramasExternos`, `MapaGlobal` y `MuelleManager`.

## Límites conocidos

- Los destinos del mapa global todavía no cargan escenas artísticas propias.
- Los animales tienen datos, pero aún no son entidades visibles del mundo.
- No hay combate naval, economía dinámica completa ni NPCs con inventario y
  relaciones avanzadas.
- El arte definitivo sólo está integrado en una parte de los edificios; los
  placeholders técnicos siguen siendo válidos para probar capas y pivotes.

## Últimos checkpoints

- `dc60125` — la instalación de la red del muelle respeta el horario.
- `dc65dae` — capacidad validada antes de recolectar y cosechar.
- `c0f8c31` — rastreo de recursos y cultivos visible en el HUD.
- `0567889` — la tripulación reutiliza `Actor` y la transitabilidad.

## Reglas de continuidad

1. No tocar `iso.gd` sin una razón técnica excepcional.
2. No cambiar la API pública de `Almacen`.
3. No mezclar `Bolsa` con `Almacen`.
4. Guardar datos planos, nunca referencias a nodos.
5. Ejecutar las 19 suites y buscar errores reales después de cada bloque.
