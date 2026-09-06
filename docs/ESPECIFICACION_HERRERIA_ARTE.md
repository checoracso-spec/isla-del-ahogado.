# Especificación de arte — Herrería Calavera y Ancla

**Fecha:** 10 de agosto de 2026
**Estado:** documento técnico, sin integración de PNG. Los 12 muebles de la
Herrería siguen usando `MuebleVisual` (fallback dibujado por código).

Este documento no reemplaza ningún asset. Es la referencia exacta que debe
cumplir el arte final antes de conectarlo al manifiesto — sea el Batch 02
regenerado, retocado a mano, o cualquier otra fuente.

Contexto: el análisis de compatibilidad del Batch 02 (`assets_raw/generados/
herreria_batch_02_4vistas/`) encontró que las 8 hojas no son pixel art de
paleta limitada (60.000–130.000 colores únicos por hoja) y que el 100% de los
píxeles de borde de los PNG "transparentes" conservan tinte magenta residual
del recorte de chroma-key. El paquete queda como **referencia artística**,
no como fuente de assets finales.

---

## 1. Claves exactas que necesita la Herrería

Todas ya existen en `assets/kit_validacion/manifiesto.json` — no hace falta
crear claves nuevas, solo producir los archivos PNG que faltan en
`interiores/arte/herreria/` (la carpeta no existe todavía en disco).

| Clave | Archivo esperado |
|---|---|
| `interior.herreria_v1.suelo_piedra` | `interiores/arte/herreria/herreria_v1_suelo_piedra.png` |
| `interior.herreria_v1.muro_norte` | `interiores/arte/herreria/herreria_v1_muro_norte.png` |
| `interior.herreria_v1.muro_oeste` | `interiores/arte/herreria/herreria_v1_muro_oeste.png` |
| `interior.herreria_v1.ventana_norte` | `interiores/arte/herreria/herreria_v1_ventana_norte.png` |
| `interior.herreria_v1.ventana_oeste` | `interiores/arte/herreria/herreria_v1_ventana_oeste.png` |
| `mueble.herreria.herramientas_colgadas` | `interiores/arte/herreria/herramientas_colgadas.png` |
| `mueble.herreria.panoplia_armas` | `interiores/arte/herreria/panoplia_armas.png` |
| `mueble.herreria.fragua` | `interiores/arte/herreria/fragua.png` |
| `mueble.herreria.banco_trabajo` | `interiores/arte/herreria/banco_trabajo.png` |
| `mueble.herreria.horno` | `interiores/arte/herreria/horno.png` |
| `mueble.herreria.yunque` | `interiores/arte/herreria/yunque.png` |
| `mueble.herreria.estanteria_herramientas` | `interiores/arte/herreria/estanteria_herramientas.png` |
| `mueble.herreria.deposito_carbon` | `interiores/arte/herreria/deposito_carbon.png` |
| `mueble.herreria.mesa_trabajo` | `interiores/arte/herreria/mesa_trabajo.png` |

Además la Herrería usa dos claves **compartidas** con otros edificios (ver
punto 4):

| Clave | Archivo |
|---|---|
| `mueble.comun.cofre_hierro.cerrado` | `interiores/arte/muebles/cofre_cerrado.png` |
| `mueble.comun.cofre_hierro.abierto` | `interiores/arte/muebles/cofre_abierto.png` |
| `objeto.barril` (×2, decorativos) | `objetos/barril.png` |

---

## 2. Dimensiones y pivotes por objeto

Todos: `escala_pixel: 2`, `filtro: nearest`, `capa: mundo` (salvo el suelo,
que es `terreno`). El pivote es `[x, y]` en píxeles físicos, esquina superior
izquierda del sprite como origen — **se declara, nunca se deduce**.

| Objeto | tam_físico | tam_lógico | pivote | huella | tipo |
|---|---|---|---|---|---|
| suelo_piedra | 256×64 (celda 128×64) | 128×32 (celda 64×32) | — | — | atlas_tile, 2 celdas: `piedra`, `tinta` |
| muro_norte | 128×112 | 64×56 | [64, 96] | — | sprite |
| muro_oeste | 128×112 | 64×56 | [64, 96] | — | sprite |
| ventana_norte | 128×112 | 64×56 | [64, 96] | — | sprite |
| ventana_oeste | 128×112 | 64×56 | [64, 96] | — | sprite |
| herramientas_colgadas | 128×128 | 64×64 | [64, 112] | — (pared) | sprite |
| panoplia_armas | 128×144 | 64×72 | [64, 128] | — (pared) | sprite |
| **fragua** | 192×256 | 96×128 | [96, 240] | [2, 1] | sprite, estación de crafteo |
| **banco_trabajo** | 192×160 | 96×80 | [96, 144] | [2, 1] | sprite, estación de crafteo |
| **horno** | 160×256 | 80×128 | [80, 240] | [1, 1] | sprite |
| **yunque** | 128×112 | 64×56 | [64, 96] | [1, 1] | sprite |
| **estanteria_herramientas** | 128×192 | 64×96 | [64, 176] | [1, 1] | sprite |
| **deposito_carbon** | 128×112 | 64×56 | [64, 96] | [1, 1] | sprite |
| **mesa_trabajo** | 192×128 | 96×64 | [96, 112] | [2, 1] | sprite |
| cofre_hierro (cerrado/abierto) | 128×144 | 64×72 | [64, 128] | [1, 1] | sprite, común |
| barril (objeto) | 80×96 | 40×48 | [40, 76] | [1, 1] | sprite, común |

Los objetos en **negrita** son los que hoy renderizan como `MuebleVisual`
(placeholder dibujado por código) y son candidatos directos del Batch 02 —
con la salvedad del punto 3.

Casillas y orientación en el plano 10×8 de `interior_herreria_pb` (para que
el artista sepa qué cara del objeto se ve desde la entrada, que está en
`Vector2i(4,6)`, es decir el jugador entra mirando hacia el norte):

| Mueble | Casilla | Sólido | Huella | Interacción |
|---|---|---|---|---|
| fragua | (1,1) | sí | 2×1 | `[E] Usar fragua` (crafteo) |
| banco_trabajo | (6,1) | sí | 2×1 | `[E] Usar banco de trabajo` (crafteo) |
| horno | (8,1) | sí | 1×1 | — |
| yunque | (4,2) | sí | 1×1 | — |
| estanteria_herramientas | (1,3) | sí | 1×1 | — |
| deposito_carbon | (7,3) | sí | 1×1 | — |
| mesa_trabajo | (3,4) | sí | 2×1 | — |
| cofre (hierro) | (1,5) | sí | 1×1 | abrir cofre |
| barril ×2 | (7,5), (8,5) | sí | 1×1 | — |
| herramientas_colgadas | (8,0) | no | pared | — |
| panoplia_armas | (0,4) | no | pared | — |

---

## 3. Objetos faltantes: horno y mesa_trabajo

El Batch 02 trae 8 hojas: `yunque, fragua, banco_trabajo,
estanteria_herramientas, panoplia, barril_carbon, cofre_hierro,
escaleras_madera`. **No incluye `horno` ni `mesa_trabajo`**, aunque ambos ya
tienen clave y dimensiones declaradas en el manifiesto (ver tabla arriba) y
aparecen en `docs/ESTADO_PROYECTO.md` como parte del mismo lote pendiente.

Especificación exacta para producirlos cuando exista una fuente pixel-art
real:

- **horno**: 160×256 físicos (80×128 lógicos), pivote [80, 240], huella
  1×1. En la referencia visual original (la imagen adjunta al pedido de pase
  artístico) corresponde al horno de piedra con chimenea situado junto a la
  fragua, no al brasero redondo que sí trae el batch bajo el nombre
  `fragua_4vistas.png` — son dos objetos distintos y el batch actual solo
  cubre uno de ellos con ese aspecto.
- **mesa_trabajo**: 192×128 físicos (96×64 lógicos), pivote [96, 112],
  huella 2×1. Mesa de trabajo horizontal (no confundir con `banco_trabajo`,
  que es la estación de crafteo interactiva).

---

## 4. Reutilización correcta de `cofre_hierro`

`mueble.comun.cofre_hierro.cerrado/abierto` **no es una clave de la
Herrería**: es un asset compartido (`interiores/arte/muebles/
cofre_*.png`) que también usan otros interiores con cofre. La Herrería lo
referencia tal cual en `interior_herreria_pb` (mueble tipo `cofre`, casilla
`(1,5)`, `asset_cerrado`/`asset_abierto` apuntando a esa clave común).

El `cofre_hierro_4vistas.png` del Batch 02 **no debe registrarse como clave
nueva de Herrería**. Si el arte de ese cofre se considera bueno, el archivo
final reemplaza `cofre_cerrado.png`/`cofre_abierto.png` en la ruta común —
y eso afecta a todos los interiores que usan esa clave, no solo a la
Herrería. Cualquier cambio ahí necesita revisión aparte, fuera del alcance
de "solo Herrería".

---

## 5. Decisión pendiente: `deposito_carbon`

La clave real del manifiesto es `mueble.herreria.deposito_carbon` (128×112,
64×56, pivote [64,96], huella 1×1). El Batch 02 trae `barril_carbon_4vistas
.png`, con un nombre distinto y sin confirmar si representa el mismo
objeto (el depósito de la definición actual) o un mueble adicional.

Pendiente de decidir, no asumido aquí:

- ¿`barril_carbon` sustituye a `deposito_carbon` (mismo objeto, nombre de
  archivo distinto), o
- es un objeto nuevo que requeriría su propia clave y su propia entrada en
  `interior_herreria_pb.muebles`?

---

## 6. Decisión pendiente: escaleras y planta alta

`escaleras_madera_4vistas.png` no tiene ninguna clave de manifiesto ni
entrada en `interior_herreria_pb.muebles` hoy. Tampoco existe
`interior_herreria_pa` (planta alta) — a diferencia de la Capitanía, que sí
tiene PB y PA.

Dos caminos posibles, ninguno decidido en este documento:

- **Decorativa únicamente**: se añade como mueble sin `destino_zona`,
  igual que `panoplia_armas` o `herramientas_colgadas` — visualmente
  presente, no interactiva. Requiere solo definir casilla, huella,
  `solido` y pivote.
- **Funcional**: se conecta como transición (`destino_zona`, como ya usa
  el sistema en `_montar_transiciones()` de `interior_escena.gd`) hacia una
  planta alta nueva de la Herrería. Esto es un edificio nuevo de facto
  (nueva `InteriorDefinicion`, nuevo guardado de esa zona) y queda fuera del
  alcance que fijaste ("no nuevos edificios, no refactor de mundo.gd").

Recomiendo la primera opción si se decide usar el objeto en este pase, y
dejar la segunda para cuando la Herrería reciba una planta alta real.

---

## Resumen

Nada de esto se ha integrado. `manifiesto.json`, `base_de_datos.gd`,
`iso.gd`, `almacen.gd`, `mundo.gd` y las identidades guardadas no se
tocaron. Los 12 muebles siguen en `MuebleVisual`. Este documento es la
especificación a cumplir cuando exista una versión del Batch 02 (o de
cualquier otra fuente) que sea pixel art real de paleta limitada, sin halo
magenta, y a la escala física/lógica exacta de cada clave.
