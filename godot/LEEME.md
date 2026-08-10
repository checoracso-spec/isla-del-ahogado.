# Marea y Ceniza — proyecto Godot 4

La isla isométrica y la **logística** que la mueve: almacén, cuellos de botella,
sustitución de materias primas, rastreo de carga, motín y la base de datos de
contenido. El mapa no es un decorado: los edificios humean porque su estación
está produciendo y se ponen en rojo porque al almacén le falta el insumo.

---

## Cómo abrirlo

1. Abre `Godot_v4.7.1-stable_win64.exe` (está en tu carpeta de Descargas, dentro
   de la carpeta con ese mismo nombre).
2. En el Project Manager: **Import** → busca esta carpeta `godot` → **Import & Edit**.
3. Pulsa **F5** para jugar.

Sale la isla vista desde arriba en diagonal: mar, playa, la explanada de tierra
del pueblo y los edificios, con la tripulación andando entre ellos.

**Controles:** **WASD** mueve al jugador · **Shift** corre · **E** interactúa ·
**F5** guarda y **F9** carga (ranura 1, con aviso en pantalla) · rueda del
ratón para el zoom · botón derecho arrastrando suelta la cámara · espacio
pausa · Esc cierra. Las flechas no hacen nada: están reservadas para un modo
de cámara libre que todavía no existe.

> Ojo: **F5 dentro del editor de Godot relanza el proyecto.** Para probar el
> guardado rápido, la ventana del juego tiene que tener el foco.

### El recorrido que ya funciona

Camina hasta la **herrería**, la **capitanía** o el **faro** —los tres que usan
el modelo `casa_a`— y busca en el suelo, delante, un rombo con borde dorado.

```
isla → [E] entrar → planta baja → [E] subir → planta alta
	 → [E] bajar → [E] abrir cofre → tomar objeto
	 → [E] salir → misma casilla de la puerta
```

Y aguanta guardar y cargar en cualquier punto, incluso en la planta alta: al
cargar reapareces en la misma zona y casilla, y cada cofre sigue como lo
dejaste. El objeto que sacaste no vuelve a aparecer.

### Qué probar primero

| Botón | Qué demuestra |
|---|---|
| **Cortar el acero** | Borra todo el Aceite Imperial. La herrería **no se para**: pasa sola a Grasa de Ballena y el cañón sale al 65% de calidad. Sale en la bitácora como "PLAN B". |
| **Vaciar el ron** | La taberna se queda sin insumo: cartel rojo sobre el edificio, aviso de cuello de botella, y al anochecer sube el motín. |
| **Reponer** | Llega un mercader y las estaciones paradas arrancan solas. |
| **×6** | Acelera el reloj. Al anochecer la luz se vuelve azul y la tripulación se va a la taberna. |

## Escenas

- `escenas/mundo.tscn` — **el juego** (es la que arranca con F5).
- `escenas/principal.tscn` — panel de mando sin mapa. Útil para ver los números
  crudos y probar expediciones marítimas, que todavía no tienen mapa táctico.
- `escenas/prueba_logistica.tscn` — 37 comprobaciones de logística.
- `escenas/prueba_jugador.tscn` — 185 comprobaciones de jugador, colisiones,
  interiores, identidad, cofre y guardado.
- `escenas/prueba_crafteo.tscn` — 36 comprobaciones de fabricación manual:
  estación interactiva, recetas, sustitutos, energía y guardado de trabajos.
- `escenas/prueba_mercado.tscn` — prueba de puesto, compra, venta y guardado
  del stock del mercado.
- `escenas/prueba_taberna.tscn` — prueba del mostrador, ronda, consumo,
	 moral, rumores y contratación de marineros.
- `escenas/prueba_horarios.tscn` — 22 comprobaciones de rutinas data-driven,
	producción de herrería y estados de taberna según horario.

- `escenas/prueba_assets.tscn` — 89 comprobaciones del kit visual: manifiesto,
  pivotes, rejilla lógica, capas, zoom discreto, paleta maestra y sustitución
  de un edificio.
- `escenas/prueba_profundidad.tscn` — **no es automática**: genera cinco
  capturas para mirar con los ojos si el tejado tapa correctamente a un actor
  según pase por delante o por detrás. Se ejecuta con ventana, no headless.
- `escenas/prueba_persistencia_a.tscn` y `..._b.tscn` — la prueba de guardado
  **en dos procesos**. A monta el estado y guarda; B arranca de cero, carga y
  comprueba. Hay que ejecutarlas en ese orden, y **por separado**: guardar y
  cargar dentro del mismo proceso no demuestra nada, porque cualquier dato que
  siguiera vivo en memoria taparía un agujero en la serialización.

Ábrelas con doble clic y ejecútalas con **F6**; el resultado sale en el panel
*Output* y la escena se cierra sola.

Sin abrir el editor, las diez de una vez:

```bash
G="$USERPROFILE/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe"; for E in prueba_logistica prueba_jugador prueba_persistencia_a prueba_persistencia_b prueba_assets prueba_crafteo prueba_mercado prueba_taberna prueba_horarios prueba_muelle; do "$G" --headless --path . "res://escenas/$E.tscn"; done
```

### Fabricación manual

Acércate a la fragua de la herrería y pulsa **E**. El panel usa las recetas
de `BaseDeDatos`, comprueba la mochila del jugador y descuenta energía al
iniciar. Si falta un material compatible, aplica el sustituto definido por la
receta; por ejemplo, la grasa de ballena puede mantener la fundición del
cañón con calidad reducida. El trabajo activo también se guarda como datos
planos dentro de la sección `crafting`, sin referencias a nodos.

Para cambiar cuál arranca con F5: *Project → Project Settings → Application →
Run → Main Scene*.

---

## Cómo está hecho el mapa

El terreno se guarda **por esquinas**, no por casillas. Cada rombo mira sus
cuatro esquinas y de ahí sale el tile: por eso la orilla y el borde de la
explanada tienen forma orgánica en vez de escalones.

Los rombos de transición (playa↔agua, hierba↔tierra) vienen en hojas donde
nadie documenta cuál es cuál. En vez de escribir una tabla a mano de 48
casillas, `constructor_tileset.gd` **mira** cada rombo: muestrea sus cuatro
vértices, decide si cada uno es terreno A o B y arma una máscara de 4 bits.
Si mañana añades otra hoja de transición, funciona sola.

### Dos trampas de estos assets, ya resueltas

1. **Los PNG de tiles traen las esquinas en negro OPACO, no transparente.** En
   isométrico las celdas se solapan por las esquinas, así que cada tile pintaba
   un rectángulo negro sobre sus vecinos y el suelo salía a cuadros. Lo arregla
   `tools/recortar-rombos.ps1`, que pone alfa 0 fuera del rombo. **Si añades
   tiles nuevos, pásalos por ese script.**

2. **Cada edificio trae 8 PNG que NO son 8 rotaciones.** Son 4 rotaciones
   (`_00` a `_03`) y las mismas 4 **con nieve** (`_04` a `_07`). Usar un `_04`
   o mayor deja el tejado blanco en mitad del Caribe. Sólo `_00`–`_03`.

---

## Cómo está organizado

```
godot/
├─ project.godot            configuración y lista de autoloads
├─ escenas/
│  ├─ principal.tscn        el panel de mando
│  └─ prueba_logistica.tscn las pruebas automáticas
└─ scripts/
   ├─ datos/                las "fichas" (Custom Resources)
   │  ├─ item_data.gd
   │  ├─ receta_data.gd
   │  ├─ edificio_data.gd
   │  ├─ personaje_data.gd
   │  └─ animal_data.gd
   ├─ autoload/             los sistemas que están siempre vivos
   │  ├─ reloj.gd           el tiempo: día/noche, señal de amanecer
   │  ├─ base_de_datos.gd   ← TODO EL CONTENIDO DEL JUEGO ESTÁ AQUÍ
   │  ├─ plantel.gd         quién está reclutado y qué modifica
   │  ├─ almacen.gd         el InventoryManager
   │  ├─ rastreo_carga.gd   qué hay en el mar / puerto / cofres
   │  └─ motin.gd           el Medidor de Motín
   ├─ mapa/                 todo lo que se ve
   │  ├─ iso.gd             las cuentas del isométrico, en un solo sitio
   │  ├─ constructor_tileset.gd  arma el TileSet leyendo los PNG
   │  ├─ generador_isla.gd  genera costa, playa, explanada y bosque
   │  ├─ edificio_visual.gd el edificio en pantalla + humo + cartel de avería
   │  ├─ pirata.gd          un tripulante andando
   │  └─ camara.gd          zoom y arrastre
   ├─ nucleo/               las piezas que comparte todo
   │  ├─ inventario.gd      contenedor base: mochila, cofres, bodegas...
   │  ├─ transitable.gd     "¿puedo pisar esta casilla?"
   │  ├─ transitable_rejilla.gd  la versión para espacios cerrados
   │  ├─ huella.gd          el sitio que ocupa un actor en el suelo
   │  ├─ interactuable.gd   todo lo que responde a la tecla E
   │  ├─ identidad.gd       definición ("taberna") vs instancia ("edificio_7")
   │  └─ zona.gd            isla, interior o cubierta: el mismo contrato
   ├─ actores/
   │  ├─ actor.gd           posición, dirección, movimiento con colisión
   │  ├─ jugador.gd         control e interacción
   │  └─ figura.gd          el muñeco dibujado por código (provisional)
   ├─ interiores/
   │  ├─ interior_definicion.gd  el interior COMO DATOS
   │  ├─ interior_escena.gd      lo construye y lo dibuja
   │  └─ puerta.gd               punto de paso; sólo avisa, no decide
   ├─ objetos/cofre.gd      cofre con identidad e inventario
   ├─ ui/panel_cofre.gd     interfaz mínima de trasvase
   ├─ estacion_trabajo.gd   un edificio produciendo
   ├─ mundo.gd              monta la isla y la enchufa a la logística
   ├─ principal.gd          el panel de mando sin mapa
   ├─ prueba_logistica.gd   pruebas de logística
   └─ prueba_jugador.gd     pruebas de jugador e interiores
```

Autoloads: `Reloj`, `BaseDeDatos`, `Plantel`, `Almacen`, `RastreoCarga`,
`Motin`, `Controles`, `Guardado`, `Entidades`, `Assets`, `Bolsa`, `Ubicacion`,
`Contenedores`, `Interiores`.

---

## El kit visual de validación

En `assets/kit_validacion/` conviven, sin tocar el arte actual, los
placeholders **técnicos** del futuro pixel art. Todo lo describe
`manifiesto.json`; la lógica nunca escribe una ruta de archivo, pide una clave:

```gdscript
var s := Assets.sprite("edificio.kit_casa.cuerpo")   # ya trae pivote y filtro
```

**Reglas del arte**, que el validador comprueba solo:

| Regla | Por qué |
|---|---|
| Se dibuja a resolución **lógica** y se amplía ×2 con Nearest | Cada píxel artístico es un bloque de 2×2. Densidad uniforme |
| El PNG físico mide exactamente el lógico × 2 | Si no, se mezclan píxeles de tamaños distintos |
| El pivote se **declara**, jamás se deduce | Deducirlo del alfa fue lo que nos dio edificios flotando |
| Cuerpo y tejado comparten lienzo y pivote | Si difieren un píxel, el tejado baila al ocultarse |
| Las esquinas de cada celda de tile son transparentes | La trampa del negro opaco, ahora detectada sola |
| La huella es `[ancho, alto]`, nunca un número | Un carro es 2×1 y un barco 5×2 |

Regenerar los placeholders:

```bash
powershell -ExecutionPolicy Bypass -File tools/generar-placeholders.ps1
```

Llevan el rombo de huella dibujado, marcas de esquina y una **cruz magenta en
el pivote**: un anclaje mal puesto se ve al instante en vez de manifestarse
como "esto parece un poco hundido".

### Capas: la regla que no se puede romper

Dentro del contenedor ordenado por profundidad **no se usa `z_index`**. El
orden lo decide la Y del nodo, y `z_index` se la salta: un tejado con z alto
se dibujaría encima de un actor que pasa *por delante* de la casa.

Las piezas de una entidad —cuerpo, tejado, adornos— se ordenan por **orden de
hijos** y comparten la Y de su padre, así que viajan como una sola unidad.
Está en `nucleo/capas.gd`, y lo comprueban las pruebas del kit.

### Decisiones tomadas, pendientes de aplicar

- **Zoom discreto**: 0.5 (vista general) y 1.0 (normal), con la cámara
  ajustada a píxeles enteros. Se aplicará cuando el kit entre en el mundo;
  hacerlo ahora sólo empeoraría la vista del arte fotorrealista.
- **Farol**: llama y brillo pequeño pintados en el sprite; el halo grande lo
  hace una `PointLight2D` que se enciende de noche. El manifiesto **declara**
  la luz; crearla es decisión de la lógica.

### Tres decisiones que conviene no deshacer

1. **`Bolsa` no es `Almacen`.** Una es lo que llevas encima; el otro son los
   cofres del pueblo con su cadena de suministro y sus 37 pruebas. Pasar cosas
   de uno a otro es un trasvase explícito, nunca un apaño de contabilidad.
2. **El contenido de un cofre no vive en el cofre.** El nodo se destruye al
   salir del interior; su contenido vive en `Contenedores`, indexado por
   instancia. Si viviera en el nodo, el ron sería infinito.
3. **Definición ≠ instancia.** `"taberna"` es qué es; `"edificio_0007"` es cuál
   es. Sin esa separación no puede haber dos tabernas ni guardarse la partida.

**Los "autoload" son nodos globales**: existen desde que arranca el juego y se
llaman por su nombre desde cualquier sitio (`Almacen.anadir("ron", 5)`). No hay
que buscarlos en el árbol de escenas.

---

## Añadir contenido sin tocar código

Todo el contenido vive en tablas dentro de `scripts/autoload/base_de_datos.gd`.
Para un ítem nuevo, añade una línea:

```gdscript
{ "id": "cañaverales", "nombre": "Caña de Azúcar", "tipo": "crudo",
  "peso": 1.0, "volumen": 1.4, "valor": 4, "desc": "Para destilar ron." },
```

Y ya existe en el juego: aparece en el almacén, se puede cargar en un barco,
se puede usar en recetas. Si escribes mal un nombre en una receta, la consola
te avisa al arrancar (`_validar()` en base_de_datos.gd).

---

## Los tres puntos del encargo

### 1. Cuellos de botella

Cada estación registra sus insumos críticos al arrancar:

```gdscript
Almacen.vigilar("taberna", "ron", 6)   # avisa si el ron baja de 6
```

Cuando se cruza el mínimo se emite `cuello_de_botella` **una sola vez** (no un
aviso por fotograma), y `cuello_resuelto` cuando se recupera. `Almacen.cuellos_activos()`
devuelve todo lo que está en rojo ahora mismo — eso es lo que pinta la UI en rojo.

### 2. Sustitución de materia prima

Vive en la receta, no en el código de la herrería:

```gdscript
"sustitutos": {
	"aceite_imperial": { "id": "grasa_ballena", "ratio": 2.0, "calidad": 0.65 },
}
```

`Almacen.consumir()` intenta primero el material correcto; el hueco lo rellena
con el sustituto al ratio indicado y devuelve la calidad del lote. Un lote de
calidad baja **rinde menos unidades**, así que la contingencia funciona pero
cuesta. Soporta sustitución parcial (algo de aceite + algo de grasa).

Regla importante: **planifica antes de gastar**. Si el plan completo no es viable,
no toca nada y devuelve qué falta. Nunca deja el almacén a medio consumir.

### 3. Rastreo de carga

`RastreoCarga.inventario_global()` devuelve, para cada ítem, cuánto hay
`en el mar`, `en el puerto` y `en los cofres`. Un barco que atraca **no** vuelca
su carga en el almacén: queda en el puerto hasta que la descargas. Eso convierte
un puerto saturado en un cuello de botella de verdad.

Las expediciones avanzan por días (señal `Reloj.nuevo_dia`). En el mar pueden
recibir un **informe de interceptación**: sueltas lo más pesado y escapas, o
luchas con los cañones que embarcaste.

---

## Las pruebas

37 comprobaciones automáticas de las reglas de arriba. Para ejecutarlas sin abrir
el editor, desde esta carpeta:

```bash
"$USERPROFILE/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe" --headless --path . res://escenas/prueba_logistica.tscn
```

Si tocas `almacen.gd`, `motin.gd` o `rastreo_carga.gd`, vuelve a pasarlas.

---

## Contenido cargado

- **23 ítems** — los 15 de la lista + 7 marcados `[extra]` en el código que hacían
  falta para cerrar las cadenas (carbón, aceite imperial, cañón, herramientas,
  cuero, carne salada, fertilizante) + `moral`, que es intangible.
  Ojo: **Aceite Imperial** no estaba en tu lista, pero es lo que la Grasa de
  Ballena sustituye, así que sin él la mecánica no existía.
- **10 recetas** que conectan esos ítems entre sí.
- **10 edificios**, los de tu lista, cada uno con sus recetas y su coste.
- **20 personajes**, con la habilidad pasiva traducida a un efecto que el código
  lee de verdad (no es texto decorativo). Ver `plantel.gd` para la lista de
  tipos de efecto.
- **5 animales**, incluidas las dos plagas, que muerden el almacén cada amanecer.

## Lo que todavía NO existe

Sé honesto contigo mismo sobre esto:

- **Los personajes están dibujados por código**, no son sprites. Es deliberado:
  los únicos personajes isométricos gratuitos que encontramos son pixel art de
  22 px y chocan con los edificios renderizados. Cuando aparezcan sprites
  decentes se cambia `_draw()` de `pirata.gd` por un `AnimatedSprite2D` y no hay
  que tocar nada más.
- **Sólo hay 5 modelos de edificio** para 10 edificios del juego, repartidos con
  giros distintos. Se nota si te fijas.
- **No se puede construir ni colocar nada.** El pueblo se genera al arrancar.
- **Mercado con precios variables.** Hay `valor_base` por ítem, pero no fluctúa.
- **Mapa táctico de expediciones.** Los barcos existen y funcionan, pero se
  manejan desde `principal.tscn`, no desde el mapa.
- **Árbol de tecnología, misiones, diálogos.** Existen en el prototipo HTML antiguo
  (`../index.html`), no aquí.
- **Guardado.** Cada vez que arrancas, empiezas de cero.
