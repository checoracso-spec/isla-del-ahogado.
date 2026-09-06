# Pipeline de assets

Esta herramienta usa Pillow y trabaja separada de Godot. Por defecto no modifica
ningún PNG existente.

## Validar

Desde la carpeta del proyecto Godot:

```powershell
python tools/asset_pipeline.py validate
```

Comprueba dimensiones declaradas en `assets/kit_validacion/manifiesto.json`,
canal alfa, magenta visible, negro opaco, relación entre tamaño lógico y físico,
y pivotes con formato válido. El resultado queda en
`docs/assets_pipeline/asset_report.json`.

## Crear copias normalizadas

```powershell
python tools/asset_pipeline.py normalize --remove-magenta --output docs/assets_pipeline/normalized
```

La salida es una copia de trabajo. El original nunca se reemplaza y la limpieza
de magenta/negro solo ocurre si se pasan explícitamente esas opciones.

## Generar hoja de contacto

```powershell
python tools/asset_pipeline.py sheet
```

La hoja se genera en `docs/assets_pipeline/contact_sheet.png`.

## Flujo recomendado

1. Colocar nuevos PNG en una carpeta de entrada separada.
2. Ejecutar `validate`.
3. Revisar el informe y la hoja de contacto.
4. Ejecutar `normalize` solo sobre copias aprobadas.
5. Integrar manualmente en Godot y ejecutar las pruebas del proyecto.

La herramienta no decide automáticamente el pivote artístico ni la huella de
colisión: esos datos siguen siendo decisiones del manifiesto y del modo
desarrollador de interiores.
