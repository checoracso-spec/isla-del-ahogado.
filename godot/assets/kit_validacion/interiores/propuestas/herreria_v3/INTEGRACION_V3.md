# Integracion Herreria V3

La copia jugable esta en:
`res://assets/kit_validacion/interiores/arte/herreria_v3/`.

Se conservaron las claves logicas `interior.herreria_v1.*` para no romper
BaseDeDatos, partidas guardadas ni pruebas. El manifiesto apunta ahora esas
claves a las piezas V3: suelo de una celda 128x64 y muros de 128x144 con
pivote [64,128].

Los PNG V1 originales siguen archivados fuera del proyecto activo en:
`C:\\Users\\checo\\.claude\\medieval-pirates-game\\archivo_assets_v1_pre_v3\\`.

Validacion realizada:
- prueba_assets: 89/89
- comparador_herreria.tscn: arranque limpio
- mundo.tscn: arranque limpio
- 28 escenas prueba_*.tscn: codigo de salida 0
