extends Node2D

## Nivel separado de referencia para El Abismo; el Prompt 3 lo visita inline
## para conservar la sesión, mientras esta escena reserva su futura expansión.

func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color("#082f39"), true)
	for y in range(0, 720, 32):
		for x in range(0, 1280, 32):
			if (int(x / 32) + int(y / 32)) % 2 == 0:
				draw_rect(Rect2(x, y, 32, 32), Color("#0c4148"), true)

