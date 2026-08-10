# Checkpoint de recursos, cultivos y arte externo

Fecha del checkpoint: 2026-08-10.

## Recursos del mundo

`RecursosMundo` y `FuenteRecurso` muestran cuatro instancias deterministas en
la isla:

- restos de naufragio: madera y pólvora húmeda;
- manglar: madera y carbón;
- semillero de la isla: las tres semillas iniciales;
- veta de azufre: azufre volcánico.

Cada fuente conserva `definition_id`, `instance_id`, cantidad, agotamiento,
regeneración e identidad natural. Su zona, orden y criterio de colocación
viven en `FuenteRecursoData`; `mundo.gd` sólo monta las definiciones activas.
El guardado usa diccionarios planos; no serializa nodos.

`RecolectorRecurso` es un componente opcional para automatizar una fuente
hacia `Almacen` cuando una grua, red o mejora del muelle lo habilite. No se
monta todavia en el mapa principal: la receta existente `rastrillar_marea`
continua siendo la autoridad de la produccion inicial y asi se evita duplicar
salidas durante el prototipo.

## Cultivos

`CultivoData` define semillas, cosechas y horas de crecimiento.
`CultivosMundo` conserva el estado de cada parcela y escucha `Reloj`.
`ParcelaCultivo` es el objeto interactuable reutilizable.

Definiciones iniciales:

- cítricos;
- caña de azúcar;
- tabaco.

La isla crea tres parcelas de prueba. El recorrido funcional verificado para
los cítricos es:

`semilla → sembrar → crecer según Reloj → cosechar → mochila → guardar/cargar`.

## Pack externo

Los 67 PNG del pack descargado viven en:

`assets/externos/room_diorama/`

La fuente y la atribución están en el README de esa carpeta. Las imágenes
originales miden 302×256; el diorama de herrería seleccionado tiene un apoyo
aproximado en `(161,255)` dentro del lienzo. Por eso todavía no se registra
como pieza del manifiesto principal 128×64: es una escena completa, no un
conjunto modular. Antes de usarlo en una escena jugable hay que recortarlo o
validar escala, huella y oclusión.

La galería independiente `res://escenas/galeria_diorama.tscn` permite revisar
la pieza sin modificar la escena principal.

## Pruebas nuevas

- `prueba_recursos_mundo.tscn`: 25/25.
- `prueba_cultivos_mundo.tscn`: 17/17.

El naufragio determinista actual se monta en `(24, 1)`, junto a la costa,
fuera del encuadre inicial de la camara. La bitacora orienta al jugador hacia
el recurso y su silueta incluye mastil y bandera para facilitar su lectura al
explorar. La identidad natural no cambia.

La regresión existente sigue pasando y el arranque de `mundo.tscn` no produce
`SCRIPT ERROR`. `prueba_profundidad.tscn` es una escena visual y se ejecuta
con límite de tiempo porque no se autocierra.
