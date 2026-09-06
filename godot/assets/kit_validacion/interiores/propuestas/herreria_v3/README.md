# Herrería V3 — Propuesta de dirección visual

Esta carpeta contiene una propuesta visual nueva y aislada para sustituir los muros y suelos de la Herrería.

## Estado

- `lamina_muros_pisos_v3.png`: lámina de referencia artística, todavía no integrada como asset jugable.
- `fuente_muro_piedra_v3.png` y `fuente_suelo_piedra_v3.png`: fuentes generadas para preparar el lote.
- `referencia_muro_v3_basada_en_aprobada.png`: nueva iteración generada usando las referencias aprobadas como entrada visual directa.
- `referencia_maestra_muro.png`: referencia definitiva aprobada por el usuario para todos los muros.
- `referencia_maestra_suelo.png`: referencia definitiva aprobada por el usuario para todos los suelos y bordes.
- `prototipo_suelo_piedra_v3.png`: prueba 128×64.
- `prototipo_muro_norte_v3.png` y `prototipo_muro_oeste_v3.png`: pruebas 128×144 con apoyo en y=128.
- `herreria_v2_lote1_final_rechazado.zip`: respaldo del lote anterior rechazado por calidad visual.

Los assets actuales de la Herrería continúan funcionando en sus rutas originales. No se han borrado ni reemplazado.

## Dirección aprobada para el siguiente lote

- Isométrico 2D estricto 2:1.
- Tile visual de 128×64 px.
- Subdivisión opcional de trabajo de 2×2 en 64×32 px, sin cambiar `Iso.ANCHO` ni `Iso.ALTO`.
- Muros altos de piedra, aproximadamente 128×144 px, con pivote de apoyo en `[64,128]`.
- Piedra grande e irregular, juntas visibles y pocas formas repetidas.
- Sin madera en los muros.
- Sin almenas ni coronas de fortaleza.
- Sin deformación, postes repetidos ni piezas inclinadas.
- Transparencia limpia, sin #ff00ff residual y sin #000000 renderizado.

La lámina es una referencia de diseño. Antes de integrarla hay que producir las piezas PNG individuales, validarlas y probarlas en `comparador_herreria.tscn`.
