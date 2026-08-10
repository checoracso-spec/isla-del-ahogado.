# Documento de Diseño de Juego (GDD)
## Título de trabajo: "Marea y Ceniza" (placeholder)

**Versión:** 0.1 — Documento inicial
**Fecha:** 2026-08-07
**Plataforma:** Navegador (escritorio), empaquetable a app de escritorio más adelante
**Motor:** Phaser 3 + TypeScript
**Género:** Simulación de vida / crafteo / gestión de pueblo con elementos RPG y piratas, vista 2D top-down

---

## 1. Visión general (Pitch)

Naufragas en las costas de un reino medieval en decadencia, sin nada más que lo puesto. Debes reconstruir tu vida desde cero: cultivar, talar, minar, craftear y comerciar para levantar un asentamiento propio junto a un pueblo existente que te acoge con recelo. A medida que ganas reputación y tecnología, desbloqueas la posibilidad de reparar un barco y salir a navegar — comerciando, saqueando y explorando islas — mientras cumples con obligaciones "civiles" del pueblo (incluido, como guiño a Graveyard Keeper, hacerte cargo del cementerio/capilla local, un trabajo que nadie más quiere pero que da poder e ingresos).

**Pilares de diseño:**
1. **Progresión desde cero** (Medieval Dynasty): empiezas sin nada, cada mejora se siente ganada.
2. **Profundidad de sistemas y humor negro/cotidiano** (Graveyard Keeper): crafteo en capas, gestión de un "negocio" poco convencional, muchas mecánicas entrelazadas.
3. **Libertad y aventura** (Piratas): una vez estable en tierra, el mar abre exploración, comercio marítimo y combate naval opcional.
4. **Un pueblo vivo**: NPCs con rutinas, necesidades y relaciones que reaccionan a tus decisiones, no decoración estática.

---

## 2. Ambientación y tono

- Época: pseudo-medieval tardío con toque de "era de la vela" (permite barcos y piratas sin romper coherencia).
- Tono: cálido y acogedor en el pueblo, con humor seco; más duro y misterioso en el mar y las ruinas/mazmorras.
- Mapa: un continente costero con un pueblo central, y un archipiélago de islas navegables descubribles progresivamente.

---

## 3. Loop de juego principal

**Loop corto (minuto a minuto):**
Explorar → Recolectar recurso → Craftear/Procesar → Usar o vender → Mejorar herramienta/edificio.

**Loop medio (por día/sesión):**
Cumplir necesidades (comer, dormir, energía) → Avanzar 1-2 tareas de misión → Interactuar con NPCs (relación/comercio) → Invertir excedente en construcción o tecnología.

**Loop largo (por "temporada"/acto):**
Desbloquear tier tecnológico → Desbloquear nueva zona (bosque profundo, mina, costa, mar abierto) → Nuevas misiones y facción → Nuevo tipo de amenaza/desafío.

---

## 4. Sistemas de juego

### 4.1 Supervivencia
- Barras: **Hambre, Energía, Salud**. (Sin sed para no saturar de números; se puede añadir después.)
- Dormir restaura energía; el reloj avanza en ciclos día/noche con estaciones (4 estaciones, ~28 días cada una, ajustable).
- Clima afecta rendimiento (lluvia reduce estamina en exteriores, invierno exige comida/leña extra).

### 4.2 Recolección y Producción
- Recursos primarios: madera, piedra, fibra, mineral, pesca, caza, cultivos.
- Cadenas de producción por estaciones de trabajo (ej: mineral → fundición → lingote → herrero → herramienta), inspirado en las cadenas largas de Graveyard Keeper.
- Herramientas con niveles de calidad que afectan velocidad/rendimiento.

### 4.3 Agricultura y Granja
- Parcelas de cultivo con estaciones (algunos cultivos solo crecen en ciertas estaciones, como en Medieval Dynasty).
- Animales domésticos (gallinas, cabras, luego caballos para transporte) con necesidades propias.

### 4.4 Construcción de asentamiento
- Sistema de planos (blueprints) desbloqueados por tecnología.
- Edificios: casa (mejorable), almacén, taller, herrería, muelle, capilla/cementerio, astillero.
- Reubicación/expansión libre en una grilla, similar a Medieval Dynasty.

### 4.5 Árbol de tecnología
- Estructurado en 4 ramas que cruzan entre sí:
  - **Rama Tierra** (agricultura, construcción, minería)
  - **Rama Artesanía** (herrería, alquimia/curtido, carpintería — guiño Graveyard Keeper)
  - **Rama Fe/Comunidad** (capilla, cementerio, sermones, reputación — el "negocio poco convencional")
  - **Rama Mar** (navegación, astillero, cartografía, combate naval, comercio exterior)
- Se desbloquea con "puntos de conocimiento" obtenidos leyendo libros, hablando con NPCs expertos, o investigando en un atril/laboratorio — no solo grindeando recursos.
- Cada nodo tecnológico desbloquea: receta(s), edificio o mejora de herramienta.

### 4.6 El Cementerio/Capilla (guiño directo a Graveyard Keeper)
- Trabajo secundario asignado al jugador por el pueblo: gestionar entierros, mantener la capilla, oficiar pequeños ritos.
- Mecánica de "procesar" cuerpos/almas de forma moralmente ambigua y con humor negro ligero (sin gore explícito), que da recursos únicos (velas, reliquias) y puntos de fe.
- Sube una reputación paralela ("Fe del pueblo") que desbloquea favores especiales.

### 4.7 NPCs con comportamiento inteligente simulado
*(Sin llamadas a modelos de lenguaje — todo corre localmente, instantáneo y gratis.)*
- **Máquina de estados + sistema de necesidades** por NPC: cada uno tiene rutina diaria (dormir, trabajar, comer, socializar, ocio) definida por horario y modulada por sus propias necesidades (energía, hambre, ánimo).
- **Memoria ligera**: cada NPC recuerda tus últimas interacciones relevantes (regalos, favores, misiones) y ajusta diálogo/relación.
- **Sistema de relación**: puntos de amistad/romance por NPC, con umbrales que desbloquean diálogos, recetas, descuentos comerciales o misiones personales.
- **Diálogo dirigido por árbol + plantillas**: árboles de diálogo ramificados con variables (nombre, clima, estado de misión, relación) insertadas en plantillas de texto, dando sensación de reactividad sin generación en vivo.
- **Horarios cruzados**: los NPCs interactúan entre sí (van a la taberna juntos, chismean), generando vida ambiental de fondo.
- NPCs clave: Alcalde/Reeve del pueblo, Herrero, Sacerdote/rival por la capilla, Tabernero, Mercader itinerante, Capitán de barco retirado (mentor de la rama Mar).

### 4.8 Misiones
- **Misiones principales**: arco narrativo dividido en 3 actos — (1) Asentarte y ganarte al pueblo, (2) Estabilizar y desbloquear el mar, (3) Piratas y el misterio de las islas.
- **Misiones secundarias**: por NPC (relación/backstory) y por facción (pueblo, iglesia/capilla, gremio de comercio, piratas).
- **Misiones dinámicas cortas**: tablón de anuncios con encargos repetibles (entregar X recurso, cazar amenaza) para ingresos constantes.

### 4.9 Piratas y el mar
- Desbloqueado tras cierto progreso tecnológico (rama Mar) y narrativo.
- Barco propio mejorable (velocidad, carga, cañones).
- Navegación entre islas del archipiélago con clima y eventos aleatorios (tormentas, naufragios, encuentros).
- Elección de rol: comerciante naval legítimo vs. corsario/pirata (afecta reputación y facciones disponibles).
- Combate naval simplificado (cañones, abordaje) y combate terrestre básico en islas/mazmorras (exploración de ruinas, saqueo de tesoro).

### 4.10 Comercio y economía
- Mercado local con precios fluctuantes por oferta/demanda simulada.
- Mercader itinerante y, más adelante, rutas comerciales marítimas.
- Moneda única + posibilidad de trueque con NPCs específicos.

### 4.11 Progresión del personaje
- Sin clases rígidas; progresión por uso (mientras más minas, mejor minero) + puntos de habilidad por hitos de misión.
- Árboles de habilidad ligeros: Trabajo (producción), Cuerpo (combate/estamina), Palabra (comercio/relaciones/fe).

---

## 5. Estructura del mundo

```
[Islas del Archipiélago - Acto 3]
        ▲  (barco)
        │
   [Costa / Muelle] ── [Pueblo Central] ── [Bosque]
                              │                │
                        [Capilla/Cementerio] [Mina]
                              │
                        [Granja del jugador]
```
- Mapa desbloqueado progresivamente: se empieza confinado cerca del pueblo y la playa de naufragio; el bosque profundo, la mina y el mar se abren por misiones/tecnología.

---

## 6. Arte y estilo visual

- **Pixel art 2D top-down**, resolución base tipo 16x16 o 32x32 px, paleta cálida (ocres, verdes bosque, azul mar) con acentos según zona (fría/gris en cementerio, dorada en pueblo, turquesa en mar).
- Iluminación dinámica día/noche y clima con tintado de escena (post-processing simple de Phaser).
- Referencia de mood: Stardew Valley (calidez/legibilidad) + Graveyard Keeper (paleta otoñal/gótica ligera) + arte de piratas tipo "Sea of Thieves" pero en 2D pixel.
- UI: paneles con bordes tipo pergamino/madera tallada, iconografía clara, tipografía legible pixel-friendly.

---

## 7. Interfaz y controles

- Movimiento WASD/flechas, interacción con E/clic, inventario con grid tipo Stardew, rueda rápida de herramientas.
- Menú de árbol tecnológico como mapa visual navegable (no lista plana).
- Diario de misiones con secciones por acto/facción.
- Mapa del mundo y, al desbloquear barco, mapa náutico con niebla de guerra.

---

## 8. Stack técnico

- **Motor:** Phaser 3 (rendering, física arcade, tilemaps vía Tiled).
- **Lenguaje:** TypeScript + Vite (bundler, hot reload rápido para iterar juntos).
- **Datos de juego:** JSON/TS data-driven (recetas, árbol tecnológico, diálogos, NPCs) para poder ampliar contenido sin tocar el motor del juego.
- **Guardado:** LocalStorage inicialmente (autosave), exportable a archivo más adelante.
- **Assets:** pixel art propio o de packs con licencia adecuada (a definir); marcadores de posición (placeholders) geométricos durante el prototipo para no bloquear el desarrollo en arte.

---

## 9. Hoja de ruta de desarrollo (fases)

1. **Fase 0 — Esqueleto técnico:** proyecto Phaser+TS, mapa base (Tiled), movimiento de personaje, cámara, día/noche básico.
2. **Fase 1 — Vertical slice:** loop de recolección/crafteo mínimo, 1 NPC con rutina y diálogo, 1 misión completa, inventario y HUD de necesidades.
3. **Fase 2 — Pueblo vivo:** 4-5 NPCs, sistema de relaciones, tablón de misiones, mercado básico, primeras 2 ramas del árbol tecnológico.
4. **Fase 3 — Capilla/Cementerio:** mecánica única, reputación de fe, recompensas.
5. **Fase 4 — Mar y piratas:** barco, navegación, primera isla, combate naval simplificado.
6. **Fase 5 — Contenido y pulido:** arco narrativo completo, más islas, balance, arte final, sonido/música.

Cada fase termina en una versión **jugable** para probar juntos antes de seguir.

---

## 10. Preguntas abiertas para iterar más adelante

- ¿Nombre final del juego?
- ¿Multijugador cooperativo o estrictamente un jugador? (por defecto: un jugador)
- ¿Nivel de combate deseado (ligero/opcional vs. central)?
- ¿Usar assets de pixel art existentes con licencia, o generarlos/dibujarlos a medida?
- ¿Guardado en la nube o solo local?

---

**Siguiente paso propuesto:** Fase 0 — montar el esqueleto técnico (Phaser + TypeScript + Vite) con un personaje moviéndose en un mapa de prueba, para tener algo jugable en el navegador desde el primer día.
