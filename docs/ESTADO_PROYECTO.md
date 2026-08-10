# Marea y Ceniza — estado del proyecto

**Fecha:** 9 de agosto de 2026
**Motor:** Godot 4.7.1
**Pruebas:** 336/336 en verde, sin errores

Documento de traspaso. Describe qué hay hecho, qué no, y qué se puede tocar sin
romper nada. Si vuelves al proyecto después de un tiempo, empieza por aquí.

---

## 1. Estado actual

El juego tiene una **base jugable y persistente completa**, y una
**infraestructura de arte lista** para recibir el pixel art definitivo.

Lo que se puede hacer hoy, de principio a fin:

```
isla → caminar → puerta → planta baja → escalera → planta alta
     → cofre → mochila → guardar → cerrar el juego → cargar arriba
     → bajar → salir por la misma puerta
```

Todo eso sobrevive a cerrar y reabrir el proceso: está demostrado con una
prueba en **dos procesos independientes**, no con un guardar/cargar en memoria.

El arte está en **migración**. La Capitanía ya tiene exterior modular e interior
artístico; los demás edificios siguen usando los renders antiguos y los
personajes continúan dibujados por código.

---

## 2. Arquitectura

### Los 15 autoloads

| Autoload | Responsabilidad |
|---|---|
| `Reloj` | Día/noche. Emite `nuevo_dia` y `anochecer`; todo lo demás se engancha |
| `BaseDeDatos` | **Todo el contenido**: ítems, recetas, edificios, personajes, animales, interiores |
| `Plantel` | Quién está reclutado y qué modifica su habilidad |
| `Almacen` | Los cofres del pueblo: cuellos de botella, sustitución, reservas |
| `RastreoCarga` | Mercancía en el mar / puerto / cofres; expediciones |
| `Motin` | El Medidor de Motín y el consumo diario de la tripulación |
| `Controles` | Registra las acciones de entrada por código |
| `GlobalColors` | Paleta maestra para UI, dibujo procedural y parámetros de shaders |
| `Guardado` | SaveManager por secciones registrables |
| `Entidades` | Identidad: definición vs instancia |
| `Assets` | Clave lógica → arte. La frontera entre lógica y gráficos |
| `Bolsa` | Lo que lleva encima el jugador |
| `Ubicacion` | Dónde está el jugador: zona, casilla, retorno |
| `Contenedores` | Inventarios de cofres y barriles, por instancia |
| `Interiores` | Cambio exterior ↔ interior y entre plantas del mismo edificio |

### Las ideas que sostienen todo

**Definición ≠ instancia.** `"taberna"` es *qué* es; `"edificio_0007"` es
*cuál* es. Los identificadores se acuñan por **clave natural**
(`"isla:taberna@34,21"`), así que sobreviven a regenerar el mundo y a guardar.
Sin esto no puede haber dos tabernas ni existir un guardado.

**Un solo inventario base.** `Inventario` es un contenedor puro. Lo usan la
mochila y los cofres; `Almacen` lo adoptará cuando toque. Mover objetos siempre
es `transferir_a`, nunca sumar y restar en dos sitios.

**`Bolsa` no es `Almacen`.** Una es lo que cargas; el otro es la logística del
pueblo con sus 37 pruebas. Entre ambos sólo hay dos puertas explícitas.

**El contenido de un cofre no vive en el cofre.** El nodo se destruye al salir
del interior; el contenido vive en `Contenedores`, indexado por instancia. Si
viviera en el nodo, el ron sería infinito.

**Una sola idea de colisión.** `Transitable` responde "¿puedo pisar aquí?" y la
implementan la isla y los interiores. Jugador, tripulación y futuros animales
usarán la misma.

**El guardado manda sobre la forma de todo.** Un sistema es guardable si su
estado son datos planos con identidad. Nunca se serializan referencias a nodos.

---

## 3. Sistemas terminados

| Sistema | Estado | Pruebas |
|---|---|---|
| Logística: almacén, cuellos de botella, sustitución de materias primas | Completo | 37 |
| Rastreo de carga y expediciones marítimas | Completo, sin mapa táctico | incluidas |
| Medidor de Motín y consumo diario | Completo | incluidas |
| Generación de isla por esquinas, con transiciones | Completo | — |
| Jugador: movimiento, colisiones, cámara, interacción | Completo | 174 |
| Inventario base, mochila, oro, salud, energía | Completo | incluidas |
| Identidad de instancia | Completo | incluidas |
| Interiores: entrar, caminar, cambiar de planta y salir | Capitanía PB/PA + Herrería + casa genérica | incluidas |
| Cofre con contenido persistente | Completo | incluidas |
| Guardado y carga, incluso desde una planta alta | Completo | 25 (dos procesos) |
| Manifiesto de assets, resolvedor y validador | Completo | 75 |
| Capas y orden de profundidad | Completo | incluidas |
| Zoom discreto y cámara a píxeles enteros | Implementado, **apagado por defecto** | incluidas |

---

## 4. Limitaciones

Lo que **no** existe, para que nadie se lleve una sorpresa:

- **El arte sólo está migrado en la Capitanía.** El resto de edificios aún usa
  renders antiguos y los personajes siguen dibujados por código.
- **La tripulación atraviesa paredes y agua.** `Pirata` todavía no hereda de
  `Actor`, así que no consulta la transitabilidad.
- **La Capitanía y la Herrería tienen interiores especializados.** El resto de
  edificios enterables todavía comparte el interior genérico de prueba. La
  Herrería conserva su exterior antiguo y ya tiene suelo, muros y fragua
  artísticos. Sus otros diez assets interiores siguen como placeholders.
- **No hay colisión entre actores.** Dos personajes pueden pisar el mismo sitio.
- **La huella de colisión sólo es rectangular y sin rotación.** Suficiente para
  personas; insuficiente para carros o barcos atracados.
- **No hay crafteo manual**, ni animales como entidades, ni barcos en el mapa,
  ni economía dinámica, ni NPCs con horarios, ni clima, ni combate.
- **`mundo.gd` sigue sin partirse en Zona.** El exterior no es una `Zona`
  formal; expone las mismas tres cosas por su cuenta.
- **La búsqueda de solar es cuadrada.** El manifiesto admite huellas
  rectangulares, pero `hueco_libre` todavía asume lado × lado.
- **La puerta exterior usa `z_index = -1`** en vez de la capa `MARCAS_SUELO`.
  Funciona, pero no respeta la tabla de capas.
- **Los carteles de avería siguen en el mundo**, no en el HUD.

---

## 5. Archivos relevantes

### Núcleo compartido
| Archivo | Qué |
|---|---|
| `scripts/mapa/iso.gd` | **Las cuentas del isométrico. Fuente única. No tocar** |
| `scripts/nucleo/inventario.gd` | Contenedor base |
| `scripts/nucleo/transitable.gd` · `transitable_rejilla.gd` | Colisión por casillas |
| `scripts/nucleo/huella.gd` | El sitio que ocupa un actor |
| `scripts/nucleo/identidad.gd` | Definición vs instancia |
| `scripts/nucleo/interactuable.gd` | Todo lo que responde a `E` |
| `scripts/nucleo/capas.gd` | Orden de dibujo |
| `scripts/nucleo/zona.gd` | Contrato común de espacio jugable |

### Lógica protegida por pruebas
`scripts/autoload/almacen.gd`, `motin.gd`, `rastreo_carga.gd`, `plantel.gd`,
`reloj.gd`, `scripts/estacion_trabajo.gd`.

### Contenido
`scripts/autoload/base_de_datos.gd` — 23 ítems, 10 recetas, 10 edificios,
20 personajes, 5 animales, 4 zonas interiores. **Todo el contenido del juego está aquí.**

### Arte
`assets/kit_validacion/manifiesto.json` — 49 claves declaradas.
`tools/generar-placeholders.ps1` y `tools/recortar-rombos.ps1`.

### Escenas
| Escena | Qué |
|---|---|
| `escenas/mundo.tscn` | El juego |
| `escenas/principal.tscn` | Panel de mando sin mapa |
| `escenas/prueba_logistica.tscn` | 37 comprobaciones |
| `escenas/prueba_jugador.tscn` | 185 |
| `escenas/prueba_persistencia_a/_b.tscn` | 25, en dos procesos |
| `escenas/prueba_assets.tscn` | 89 |
| `escenas/prueba_profundidad.tscn` | Capturas visuales, no automática |

---

## 6. Decisiones visuales

**Estilo: pixel art.** Elegido sobre ilustración digital tras comparar ambos.
Referencia: oscuro, detallado, medieval-pirata tropical. Los renders
fotorrealistas actuales **no sobreviven** a esta decisión.

**Rejilla física 128×64, densidad lógica 64×32 ampliada ×2 con Nearest.** Cada
píxel artístico es un bloque físico de 2×2. `Iso` no se toca.

**Zoom discreto: 0.5 y 1.0.** Cualquier valor intermedio reparte los píxeles de
forma desigual y la imagen tiembla. La cámara se cuadra a píxeles enteros; el
movimiento lógico sigue siendo continuo. Para ver la isla entera habrá un mapa
estratégico aparte, no un zoom lejano.

**El pivote se declara, nunca se deduce.** Deducirlo del canal alfa fue lo que
dio edificios flotando.

**Cuerpo y tejado comparten lienzo y pivote.** Si difieren un píxel, el tejado
baila al ocultarse.

**Las transiciones usan 16 máscaras en orden explícito** (celda *n* = máscara
*n*; bit 0 arriba, 1 derecha, 2 abajo, 3 izquierda).

**Luz principal desde arriba a la izquierda**, sombras frías, luces cálidas
sólo en emisores. El farol lleva llama y brillo pequeño pintados; el halo
grande lo hace una `PointLight2D` que el manifiesto **declara** y la lógica
decide encender.

**Paleta maestra en `GlobalColors`.** Sus 32 colores son la fuente única para
UI y dibujo generado por código. `#ff00ff` queda reservado exclusivamente para
chroma-key y no forma parte de la paleta de juego; el vacío y los contornos
usan `#0f0f1b`, nunca negro puro. Salud, estamina, interacción, peligro y
selección tienen accesores semánticos para evitar hexadecimales dispersos.

**Filtro Nearest por nodo, nunca global.** Así el arte antiguo no cambia
mientras dure la transición.

### Dos trampas de los assets actuales, ya resueltas
1. Los PNG de tiles traían las esquinas en **negro opaco**. El validador ahora
   lo detecta solo.
2. Los 8 PNG por edificio no son 8 rotaciones: son **4 rotaciones y 4 con
   nieve**. Sólo `_00`–`_03`.

---

## 7. Próximo paso exacto

**Batch 02 de la Herrería: seis muebles de mundo.** Banco de trabajo, horno,
yunque, estantería de herramientas, depósito de carbón y mesa de trabajo. El
Batch 01 ya sustituyó suelo, muro norte, muro oeste y fragua. El plano 10×8,
las capas visuales, las 35 casillas transitables, el cofre y el guardado siguen
funcionando. Exterior, PointLight2D y crafteo permanecen fuera de alcance.

---

## 8. Lo que no debe tocarse

### Nunca, sin una razón muy fuerte
- **`scripts/mapa/iso.gd`** — fuente única de las coordenadas. Todo depende de
  ella.
- **La API pública de `Almacen`** — 37 pruebas y toda la logística encima.
- **La frontera `Bolsa` / `Almacen`** — si se mezclan, el juego de gestión y el
  de exploración se contaminan.

### Reglas que hay que respetar al añadir cosas
- **Nunca guardar referencias a nodos** en nada que se serialice.
- **Nunca `z_index` dentro del contenedor ordenado por Y.** Las piezas de una
  entidad se ordenan por orden de hijos.
- **Nunca deducir un pivote** de la imagen: se declara en el manifiesto.
- **Nunca `load()` con una ruta de arte** en la lógica: se pide a `Assets`.
- **Todo tile nuevo pasa por `tools/recortar-rombos.ps1`.**
- **Ejecutar las cinco suites después de cada cambio**, y buscar
  `SCRIPT ERROR` además del texto final: un error de parseo deja la escena
  vacía y el proceso colgado sin decir nada.

### Reversible con una línea
`capitania` usa el kit porque su ficha en `base_de_datos.gd` tiene
`"asset_exterior": "edificio.capitania_v1"`. Borrar esa línea la devuelve al arte
antiguo sin tocar código.
