extends Node
const FuenteRecursoDataScript := preload("res://scripts/datos/fuente_recurso_data.gd")
const DestinoDataScript := preload("res://scripts/datos/destino_data.gd")
const RutaGlobalDataScript := preload("res://scripts/datos/ruta_global_data.gd")
## AUTOLOAD: BaseDeDatos
##
## Todo el contenido del juego vive aquí, en tablas de diccionarios.
## Para añadir un ítem nuevo NO hay que tocar ningún otro archivo:
## añades una línea a TABLA_ITEMS y ya existe en el juego.
##
## Al arrancar, cada diccionario se convierte en un Resource tipado
## (ItemData, EdificioData, ...) para que el resto del código tenga
## autocompletado y avise si te equivocas de nombre.

# ---------------------------------------------------------------------------
# ÍTEMS Y MATERIALES
# ---------------------------------------------------------------------------
# Los 15 de la lista, más 7 marcados [extra] que hacen falta para que los
# edificios tengan algo que consumir o producir. Bórralos si no los quieres.

const TABLA_ITEMS := [
	{ "id": "doblon", "nombre": "Doblones de Oro", "tipo": "moneda",
	  "peso": 0.01, "volumen": 0.01, "valor": 1,
	  "desc": "La moneda del Caribe. Pesa poco hasta que llevas mil." },

	{ "id": "ron", "nombre": "Ron de Dudosa Procedencia", "tipo": "consumible",
	  "peso": 1.2, "volumen": 1.5, "valor": 14, "moral": 12.0,
	  "desc": "Nadie pregunta de dónde salió. Sin esto, hay motín." },

	{ "id": "polvora_humeda", "nombre": "Pólvora Húmeda", "tipo": "crudo",
	  "peso": 1.0, "volumen": 0.8, "valor": 4,
	  "desc": "Inútil hasta que la secas. Rescatada de los naufragios." },

	{ "id": "polvora_seca", "nombre": "Pólvora Seca", "tipo": "procesado",
	  "peso": 0.9, "volumen": 0.7, "valor": 18,
	  "desc": "Lo que separa un cañón de un tubo caro." },

	{ "id": "acero_imperial", "nombre": "Acero Imperial", "tipo": "raro",
	  "peso": 2.5, "volumen": 1.0, "valor": 45,
	  "desc": "Sólo se consigue saqueando. La Corona no lo vende." },

	{ "id": "grasa_ballena", "nombre": "Grasa de Ballena", "tipo": "crudo",
	  "peso": 1.8, "volumen": 2.0, "valor": 9,
	  "desc": "Sustituto de emergencia para casi cualquier químico. Apesta." },

	{ "id": "azufre_volcanico", "nombre": "Azufre Volcánico", "tipo": "crudo",
	  "peso": 1.1, "volumen": 0.9, "valor": 11,
	  "desc": "Se recoge en la ladera. Nadie dura ahí más de una hora." },

	{ "id": "seda_robada", "nombre": "Seda Robada", "tipo": "comercial",
	  "peso": 0.4, "volumen": 1.2, "valor": 60,
	  "desc": "Alto valor... si no inundas tú mismo el mercado." },

	{ "id": "madera_naufragio", "nombre": "Madera de Naufragio", "tipo": "crudo",
	  "peso": 2.0, "volumen": 2.5, "valor": 3,
	  "desc": "La marea la trae cada mañana. Húmeda y torcida." },

	{ "id": "tablon_tratado", "nombre": "Tablones Tratados", "tipo": "procesado",
	  "peso": 1.6, "volumen": 2.0, "valor": 16,
	  "desc": "Madera seca y curada. Con esto sí se construye." },

	{ "id": "raciones", "nombre": "Raciones de Pescado Salado", "tipo": "comida",
	  "peso": 0.8, "volumen": 0.8, "valor": 6, "comida": 30.0,
	  "desc": "Nadie las elogia, pero sin ellas la tripulación se va." },

	{ "id": "mapa_tesoro", "nombre": "Mapa del Tesoro a Medio Leer", "tipo": "mision",
	  "peso": 0.05, "volumen": 0.05, "valor": 0,
	  "desc": "Falta la mitad. La otra mitad la tiene alguien peor que tú." },

	{ "id": "cofre_oxidado", "nombre": "Cofre de Hierro Oxidado", "tipo": "contenedor",
	  "peso": 4.0, "volumen": 3.0, "valor": 20,
	  "desc": "Botín aleatorio. A veces son clavos." },

	{ "id": "cofre_corona", "nombre": "Cofre de la Corona Adornado", "tipo": "contenedor",
	  "peso": 5.0, "volumen": 3.5, "valor": 120,
	  "desc": "Botín épico. Y una marca en la espalda: te van a buscar." },

	{ "id": "reliquia", "nombre": "Reliquia Corsaria", "tipo": "prestigio",
	  "peso": 1.0, "volumen": 0.6, "valor": 200,
	  "desc": "No se vende: se exhibe. Mejora edificios de nivel alto." },

	# --- [extra] necesarios para cerrar las cadenas de producción ---
	{ "id": "carbon", "nombre": "Carbón de Manglar", "tipo": "crudo",
	  "peso": 1.0, "volumen": 1.2, "valor": 5, "desc": "[extra] Combustible de la herrería." },
	{ "id": "aceite_imperial", "nombre": "Aceite Imperial", "tipo": "raro",
	  "peso": 1.5, "volumen": 1.5, "valor": 38,
	  "desc": "[extra] Fluido de temple de la Corona. Es LO QUE SUSTITUYE la grasa de ballena." },
	{ "id": "canon", "nombre": "Cañón de Cubierta", "tipo": "procesado",
	  "peso": 12.0, "volumen": 8.0, "valor": 140, "desc": "[extra] Ocupa media bodega. Decide tú." },
	{ "id": "herramienta", "nombre": "Herramientas de Ribera", "tipo": "herramienta",
	  "peso": 1.4, "volumen": 1.0, "valor": 22, "desc": "[extra] Sin esto no se repara nada." },
	{ "id": "cuero", "nombre": "Cuero de Cabra", "tipo": "crudo",
	  "peso": 0.7, "volumen": 1.0, "valor": 8, "desc": "[extra] De las cabras de montaña." },
	{ "id": "carne_salada", "nombre": "Carne Salada", "tipo": "comida",
	  "peso": 0.9, "volumen": 0.9, "valor": 10, "comida": 40.0, "desc": "[extra] De los corrales." },
	{ "id": "fertilizante", "nombre": "Fertilizante de Marisma", "tipo": "procesado",
	  "peso": 1.3, "volumen": 1.5, "valor": 7, "desc": "[extra] Para los cultivos de cítricos y caña." },

	# --- intangible: no ocupa cofre, se convierte en alivio de motín ---
	{ "id": "moral", "nombre": "Moral de la Tripulación", "tipo": "intangible",
	  "peso": 0.0, "volumen": 0.0, "valor": 0,
	  "desc": "No se guarda. Al producirse, baja el Medidor de Motín." },
]

# ---------------------------------------------------------------------------
# RECETAS
# ---------------------------------------------------------------------------
# Fíjate en "sustitutos": ahí vive el plan de contingencia.

const TABLA_RECETAS := [
	{ "id": "servicio_taberna", "nombre": "Ronda de la casa", "estacion": "taberna",
	  "insumos": { "ron": 2, "raciones": 3 },
	  "productos": { "moral": 14 },
	  "segundos": 8.0 },

	{ "id": "secar_polvora", "nombre": "Secado de pólvora", "estacion": "herreria",
	  "insumos": { "polvora_humeda": 3, "carbon": 1 },
	  "productos": { "polvora_seca": 2 },
	  "segundos": 7.0, "energia": 4.0 },

	{ "id": "forjar_canon", "nombre": "Fundición de cañón", "estacion": "herreria",
	  "insumos": { "acero_imperial": 3, "carbon": 4, "aceite_imperial": 2 },
	  "productos": { "canon": 1 },
	  # ⇩ EL PLAN DE RECUPERACIÓN: sin aceite imperial, 2 grasas por cada aceite,
	  #   y el cañón sale al 65% (más riesgo de reventar en combate).
	  "sustitutos": {
		  "aceite_imperial": { "id": "grasa_ballena", "ratio": 2.0, "calidad": 0.65 },
		  "carbon": { "id": "madera_naufragio", "ratio": 3.0, "calidad": 0.85 },
	  },
	  "segundos": 14.0, "energia": 12.0 },

	{ "id": "forjar_herramienta", "nombre": "Herramientas de ribera", "estacion": "herreria",
	  "insumos": { "acero_imperial": 1, "carbon": 2 },
	  "productos": { "herramienta": 2 },
	  "sustitutos": { "carbon": { "id": "madera_naufragio", "ratio": 3.0, "calidad": 0.85 } },
	  "segundos": 9.0, "energia": 6.0 },

	{ "id": "curar_madera", "nombre": "Curado de tablones", "estacion": "muelle_grua",
	  "insumos": { "madera_naufragio": 3 },
	  "productos": { "tablon_tratado": 2 },
	  "segundos": 6.0 },

	{ "id": "rastrillar_marea", "nombre": "Rastrillo de marea", "estacion": "muelle_grua",
	  "insumos": {},
	  "productos": { "madera_naufragio": 2, "polvora_humeda": 1 },
	  "segundos": 10.0 },

	{ "id": "destilar_alternativo", "nombre": "Destilado de contingencia", "estacion": "herreria",
	  "insumos": { "grasa_ballena": 3, "azufre_volcanico": 2 },
	  "productos": { "aceite_imperial": 1 },
	  "segundos": 12.0, "energia": 8.0 },

	{ "id": "vender_seda", "nombre": "Colocar seda", "estacion": "mercado",
	  "insumos": { "seda_robada": 1 },
	  "productos": { "doblon": 60 },
	  "segundos": 5.0 },

	{ "id": "salar_carne", "nombre": "Salazón", "estacion": "corrales",
	  "insumos": { "raciones": 1, "grasa_ballena": 1 },
	  "productos": { "carne_salada": 2, "fertilizante": 1 },
	  "segundos": 8.0 },

	{ "id": "curar_heridos", "nombre": "Atender heridos", "estacion": "capilla",
	  "insumos": { "ron": 1, "cuero": 1 },
	  "productos": { "moral": 6 },
	  "segundos": 10.0 },
]

# ---------------------------------------------------------------------------
# EDIFICIOS (los 10 de tu lista)
# ---------------------------------------------------------------------------

const TABLA_EDIFICIOS := [
	{ "id": "taberna", "nombre": "Taberna de la Sirena Salada", "rol": "servicio",
	  "trabajadores": 3, "recetas": ["servicio_taberna"],
	  "coste": { "tablon_tratado": 20, "doblon": 150 },
	  "interior": "interior_taberna_pb",
	  "desc": "Convierte Raciones y Ron en Moral. Si para, el motín sube solo." },

	{ "id": "mercado", "nombre": "Mercado de Portobello", "rol": "comercio",
	  "trabajadores": 2, "recetas": ["vender_seda"],
	  "coste": { "tablon_tratado": 25, "doblon": 220 },
	  "interior": "interior_mercado_pb",
	  "desc": "Intercambia bienes procesados por Doblones al precio del día." },

	{ "id": "herreria", "nombre": "Herrería Calavera y Ancla", "rol": "produccion",
	  "trabajadores": 4, "recetas": ["secar_polvora", "forjar_canon", "forjar_herramienta", "destilar_alternativo"],
	  "coste": { "tablon_tratado": 30, "acero_imperial": 5, "doblon": 300 },
	  "interior": "interior_herreria_pb",
	  "desc": "Acero y Carbón en Cañones y Herramientas. El primer cuello de botella del juego." },

	{ "id": "alcaldia", "nombre": "Alcaldía del Sindicato", "rol": "gestion",
	  "trabajadores": 2, "recetas": [],
	  "coste": { "tablon_tratado": 40, "reliquia": 1, "doblon": 500 },
	  "desc": "Políticas del asentamiento, cuotas de producción y árbol de tecnología." },

	{ "id": "capilla", "nombre": "Capilla de San Brandán", "rol": "servicio",
	  "trabajadores": 2, "recetas": ["curar_heridos"],
	  "coste": { "tablon_tratado": 18, "doblon": 120 },
	  "desc": "Cura marineros heridos. Bajas menos bajas = menos motín." },

	{ "id": "capitania", "nombre": "Oficina del Capitán del Puerto", "rol": "gestion",
	  "trabajadores": 1, "recetas": [],
	  "coste": { "tablon_tratado": 22, "herramienta": 4, "doblon": 260 },
	  "interior": "interior_capitania_pb",
	  # ÚNICO edificio migrado al kit visual, y se decide AQUÍ, en los datos.
	  # Quitar esta línea lo devuelve al arte antiguo sin tocar código.
	  "asset_exterior": "edificio.capitania_v1",
	  "desc": "Interfaz del mapa táctico: aprovisionar y despachar expediciones." },

	{ "id": "cabana_capitan", "nombre": "Cabaña del Capitán Retirado", "rol": "vivienda",
	  "trabajadores": 0, "recetas": [],
	  "coste": { "tablon_tratado": 35, "seda_robada": 3, "doblon": 400 },
	  "desc": "Vivienda de alto nivel. Sin ella, las figuras históricas no se quedan." },

	{ "id": "muelle_grua", "nombre": "Muelle de Grúa de Madera", "rol": "recoleccion",
	  "trabajadores": 3, "recetas": ["rastrillar_marea", "curar_madera"],
	  "coste": { "madera_naufragio": 40, "doblon": 90 },
	  "desc": "Recolección automática de restos de naufragio. Tu única entrada garantizada." },

	{ "id": "faro", "nombre": "Faro de Piedra", "rol": "defensa",
	  "trabajadores": 1, "recetas": [],
	  "coste": { "tablon_tratado": 28, "grasa_ballena": 10, "doblon": 340 },
	  "interior": "interior_casa_a",
	  "desc": "Reduce el riesgo de que tus propios barcos se hundan al volver." },

	{ "id": "corrales", "nombre": "Corrales de Marisma", "rol": "produccion",
	  "trabajadores": 2, "recetas": ["salar_carne"],
	  "coste": { "tablon_tratado": 15, "doblon": 100 },
	  "desc": "Genera fertilizante y carne salada." },
]

# ---------------------------------------------------------------------------
# PERSONAJES (los 20)
# ---------------------------------------------------------------------------
# Los tipos de "efecto" que el código entiende están listados en plantel.gd.

const TABLA_PERSONAJES := [
	{ "id": "barbanegra", "nombre": "Barbanegra", "titulo": "Edward Teach",
	  "rol": "Especialista en Intimidación",
	  "habilidad": "Acelera la producción en la herrería mediante el miedo.",
	  "efecto": { "tipo": "velocidad_produccion", "valor": 0.30, "ambito": "herreria" },
	  "horario": "herrero" },

	{ "id": "anne_bonny", "nombre": "Anne Bonny", "titulo": "",
	  "rol": "Maestra del Contrabando",
	  "habilidad": "Aumenta la capacidad de carga de los barcos un 15%.",
	  "efecto": { "tipo": "capacidad_carga", "valor": 0.15 } },

	{ "id": "mary_read", "nombre": "Mary Read", "titulo": "",
	  "rol": "Capitana de Asalto",
	  "habilidad": "Reduce el tiempo de viaje en expediciones de saqueo.",
	  "efecto": { "tipo": "tiempo_expedicion", "valor": -0.25 } },

	{ "id": "calico_jack", "nombre": "Calico Jack", "titulo": "John Rackham",
	  "rol": "Gestor de la Taberna",
	  "habilidad": "Mantiene el motín a raya gastando menos ron.",
	  "efecto": { "tipo": "consumo_ron", "valor": -0.30, "ambito": "taberna" },
	  "horario": "tabernero" },

	{ "id": "henry_morgan", "nombre": "Henry Morgan", "titulo": "Sir",
	  "rol": "Gobernador del Sindicato",
	  "habilidad": "Mejora los precios de venta en el mercado negro.",
	  "efecto": { "tipo": "precio_venta", "valor": 0.20 } },

	{ "id": "ching_shih", "nombre": "Ching Shih", "titulo": "",
	  "rol": "Almirante de Flota",
	  "habilidad": "Permite despachar dos barcos simultáneamente.",
	  "efecto": { "tipo": "barcos_simultaneos", "valor": 1.0 } },

	{ "id": "black_bart", "nombre": "Black Bart", "titulo": "Bartholomew Roberts",
	  "rol": "Redactor de Leyes",
	  "habilidad": "Evita que los trabajadores roben ítems del almacén.",
	  "efecto": { "tipo": "robo_almacen", "valor": -1.0 } },

	{ "id": "kidd", "nombre": "Capitán Kidd", "titulo": "William Kidd",
	  "rol": "Buscador de Tesoros",
	  "habilidad": "Más probabilidad de recursos raros en la playa.",
	  "efecto": { "tipo": "rareza_playa", "valor": 0.25 } },

	{ "id": "drake", "nombre": "Francis Drake", "titulo": "Sir",
	  "rol": "Explorador Real",
	  "habilidad": "Revela nuevas rutas comerciales en el mapa táctico.",
	  "efecto": { "tipo": "rutas_reveladas", "valor": 2.0 } },

	{ "id": "charles_vane", "nombre": "Charles Vane", "titulo": "",
	  "rol": "Experto en Balística",
	  "habilidad": "Mejora la defensa de la ciudad contra la Marina.",
	  "efecto": { "tipo": "defensa", "valor": 0.30 } },

	{ "id": "hornigold", "nombre": "Benjamin Hornigold", "titulo": "",
	  "rol": "Instructor de la Tripulación",
	  "habilidad": "Los NPCs ganan experiencia más rápido.",
	  "efecto": { "tipo": "experiencia_npc", "valor": 0.35 } },

	{ "id": "stede_bonnet", "nombre": "Stede Bonnet", "titulo": "El Pirata Caballero",
	  "rol": "Contador Incompetente",
	  "habilidad": "Genera oro extra, pero a veces pierde materias primas al azar.",
	  "efecto": { "tipo": "ingreso_oro", "valor": 0.25 },
	  "efecto_extra": { "tipo": "merma_almacen", "valor": 0.06 } },

	{ "id": "grace_omalley", "nombre": "Grace O'Malley", "titulo": "",
	  "rol": "Negociadora de Rehenes",
	  "habilidad": "Obtiene rescates automáticos de barcos capturados.",
	  "efecto": { "tipo": "rescate_automatico", "valor": 1.0 } },

	{ "id": "jean_lafitte", "nombre": "Jean Lafitte", "titulo": "",
	  "rol": "Enlace del Mercado Negro",
	  "habilidad": "Trae mercaderes raros al puerto de noche.",
	  "efecto": { "tipo": "mercader_nocturno", "valor": 1.0 } },

	{ "id": "olonnais", "nombre": "François l'Olonnais", "titulo": "",
	  "rol": "Verdugo",
	  "habilidad": "Extrae secretos (puntos de tecnología) de los prisioneros.",
	  "efecto": { "tipo": "puntos_tecnologia_dia", "valor": 1.0 } },

	{ "id": "black_sam", "nombre": "Black Sam", "titulo": "Samuel Bellamy",
	  "rol": "Robin Hood del Mar",
	  "habilidad": "Aumenta drásticamente la moral global.",
	  "efecto": { "tipo": "moral_global", "valor": 0.40 } },

	{ "id": "woodes_rogers", "nombre": "Woodes Rogers", "titulo": "",
	  "rol": "Espía Infiltrado",
	  "habilidad": "Da alertas tempranas sobre bloqueos navales.",
	  "efecto": { "tipo": "alerta_bloqueo", "valor": 1.0 } },

	{ "id": "garfio_cobre", "nombre": "Garfio de Cobre", "titulo": "",
	  "rol": "Contramaestre de Logística",
	  "habilidad": "Coordina la madera: menos paradas en el muelle.",
	  "efecto": { "tipo": "velocidad_produccion", "valor": 0.20, "ambito": "muelle_grua" },
	  "horario": "muelle",
	  "historico": false },

	{ "id": "dientes_oro", "nombre": "Dientes de Oro", "titulo": "",
	  "rol": "Cocinero Principal",
	  "habilidad": "Estira las raciones: la tripulación come un 15% menos.",
	  "efecto": { "tipo": "consumo_raciones", "valor": -0.15 },
	  "historico": false },

	{ "id": "ojo_vidrio", "nombre": "Ojo de Vidrio", "titulo": "",
	  "rol": "Vigía del Faro",
	  "habilidad": "Menos naufragios propios al volver a puerto.",
	  "efecto": { "tipo": "riesgo_naufragio", "valor": -0.35, "ambito": "faro" },
	  "historico": false },
]

# ---------------------------------------------------------------------------
# INTERIORES
# ---------------------------------------------------------------------------
# Un interior es sólo esto: medidas, por dónde se entra y qué muebles hay.
# Añadir la taberna o la herrería será una entrada más en esta tabla, sin
# tocar una línea de código.

const TABLA_INTERIORES := [
	{ "id": "interior_taberna_pb", "nombre": "Taberna de la Sirena Salada", "tipo": "taberna",
	  "ancho": 10, "alto": 8, "suelo": "madera", "entrada": Vector2i(4, 6),
	  "muebles": [
		  { "tipo": "puesto_taberna", "casilla": Vector2i(4, 2), "solido": true,
			"huella": Vector2i(2, 1), "interactuable": "taberna",
			"horario_id": "tabernero", "actividades_productivas": ["trabajar", "taberna"],
			"actividades_preparacion": ["casa"] },
		  { "tipo": "mesa", "casilla": Vector2i(3, 4), "solido": true },
		  { "tipo": "banco", "casilla": Vector2i(2, 4), "solido": true },
		  { "tipo": "banco", "casilla": Vector2i(5, 4), "solido": true },
		  { "tipo": "barril", "casilla": Vector2i(7, 2), "solido": true },
		  { "tipo": "cofre", "casilla": Vector2i(2, 5), "solido": true,
			"definicion": "cofre_oxidado", "contenido": { "ron": 2, "raciones": 2 } }
	  ] },
	{ "id": "interior_mercado_pb", "nombre": "Mercado de Portobello", "tipo": "mercado",
	  "ancho": 10, "alto": 8, "suelo": "madera", "entrada": Vector2i(4, 6),
	  "muebles": [
		  { "tipo": "puesto_mercado", "casilla": Vector2i(4, 2), "solido": true,
			"huella": Vector2i(2, 1), "interactuable": "mercado" },
		  { "tipo": "estanteria", "casilla": Vector2i(1, 1), "solido": true },
		  { "tipo": "barril", "casilla": Vector2i(7, 2), "solido": true },
		  { "tipo": "cofre", "casilla": Vector2i(2, 5), "solido": true,
			"definicion": "cofre_oxidado", "contenido": { "seda_robada": 1 } }
	  ] },

	{ "id": "interior_casa_a", "nombre": "Casa de madera", "tipo": "casa",
	  "ancho": 9, "alto": 8, "suelo": "madera",
	  "asset_suelo": "interior.suelo_madera",
	  "asset_muro_norte": "interior.muro_norte",
	  "asset_muro_oeste": "interior.muro_oeste",
	  "entrada": Vector2i(4, 6),
	  "muebles": [
		  { "tipo": "chimenea",   "casilla": Vector2i(1, 1), "solido": true },
		  { "tipo": "mesa",       "casilla": Vector2i(4, 3), "solido": true },
		  { "tipo": "banco",      "casilla": Vector2i(3, 3), "solido": true },
		  { "tipo": "banco",      "casilla": Vector2i(5, 3), "solido": true },
		  { "tipo": "cama",       "casilla": Vector2i(7, 2), "solido": true },
		  { "tipo": "estanteria", "casilla": Vector2i(2, 1), "solido": true },
		  { "tipo": "barril",     "casilla": Vector2i(7, 5), "solido": true },
		  { "tipo": "cofre",      "casilla": Vector2i(2, 5), "solido": true,
			"definicion": "cofre_oxidado", "contenido": { "ron": 3 } },
	  ] },

	{ "id": "interior_herreria_pb", "nombre": "Herrería Calavera y Ancla",
	  "tipo": "herreria", "ancho": 10, "alto": 8, "suelo": "piedra",
	  "asset_suelo": "interior.herreria_v1.suelo_piedra",
	  "asset_muro_norte": "interior.herreria_v1.muro_norte",
	  "asset_muro_oeste": "interior.herreria_v1.muro_oeste",
	  "entrada": Vector2i(4, 6),
	  "muebles": [
		  { "tipo": "ventana", "casilla": Vector2i(3, 0), "solido": false,
			"capa_visual": "pared", "asset": "interior.herreria_v1.ventana_norte" },
		  { "tipo": "ventana", "casilla": Vector2i(6, 0), "solido": false,
			"capa_visual": "pared", "asset": "interior.herreria_v1.ventana_norte" },
		  { "tipo": "ventana", "casilla": Vector2i(0, 2), "solido": false,
			"capa_visual": "pared", "asset": "interior.herreria_v1.ventana_oeste" },
		  { "tipo": "herramientas", "casilla": Vector2i(8, 0), "solido": false,
			"capa_visual": "pared", "asset": "mueble.herreria.herramientas_colgadas" },
		  { "tipo": "panoplia", "casilla": Vector2i(0, 4), "solido": false,
			"capa_visual": "pared", "asset": "mueble.herreria.panoplia_armas" },

		  { "tipo": "fragua", "casilla": Vector2i(1, 1), "solido": true,
			"capa_visual": "mundo", "asset": "mueble.herreria.fragua",
			"huella": Vector2i(2, 1), "interactuable": "crafteo",
			"estacion_id": "herreria", "accion": "Usar fragua",
			"horario_id": "herrero" },
		  { "tipo": "banco_trabajo", "casilla": Vector2i(6, 1), "solido": true,
			"capa_visual": "mundo", "asset": "mueble.herreria.banco_trabajo",
			"huella": Vector2i(2, 1), "interactuable": "crafteo",
			"estacion_id": "herreria", "accion": "Usar banco de trabajo",
			"horario_id": "herrero" },
		  { "tipo": "horno", "casilla": Vector2i(8, 1), "solido": true,
			"capa_visual": "mundo", "asset": "mueble.herreria.horno" },
		  { "tipo": "yunque", "casilla": Vector2i(4, 2), "solido": true,
			"capa_visual": "mundo", "asset": "mueble.herreria.yunque" },
		  { "tipo": "estanteria", "casilla": Vector2i(1, 3), "solido": true,
			"capa_visual": "mundo", "asset": "mueble.herreria.estanteria_herramientas" },
		  { "tipo": "carbon", "casilla": Vector2i(7, 3), "solido": true,
			"capa_visual": "mundo", "asset": "mueble.herreria.deposito_carbon" },
		  { "tipo": "mesa", "casilla": Vector2i(3, 4), "solido": true,
			"capa_visual": "mundo", "asset": "mueble.herreria.mesa_trabajo",
			"huella": Vector2i(2, 1) },
		  { "tipo": "barril", "casilla": Vector2i(7, 5), "solido": true,
			"capa_visual": "mundo", "asset": "objeto.barril" },
		  { "tipo": "barril", "casilla": Vector2i(8, 5), "solido": true,
			"capa_visual": "mundo", "asset": "objeto.barril" },
		  { "tipo": "cofre", "casilla": Vector2i(1, 5), "solido": true,
			"capa_visual": "mundo", "definicion": "cofre_oxidado",
			"contenido": { "herramienta": 1, "carbon": 4 },
			"asset_cerrado": "mueble.comun.cofre_hierro.cerrado",
			"asset_abierto": "mueble.comun.cofre_hierro.abierto" },
	  ] },

	{ "id": "interior_capitania_pb", "nombre": "Capitanía · Planta Baja",
	  "tipo": "capitania", "ancho": 9, "alto": 8, "suelo": "madera",
	  "asset_suelo": "interior.capitania_v1.suelo_madera",
	  "asset_muro_norte": "interior.capitania_v1.muro_norte",
	  "asset_muro_oeste": "interior.capitania_v1.muro_oeste",
	  "entrada": Vector2i(4, 6),
	  "muebles": [
		  { "tipo": "chimenea",   "casilla": Vector2i(7, 1), "solido": true,
			"asset": "mueble.comun.chimenea_piedra" },
		  { "tipo": "mesa",       "casilla": Vector2i(4, 3), "solido": true,
			"asset": "mueble.capitania.escritorio", "huella": Vector2i(2, 1) },
		  { "tipo": "banco",      "casilla": Vector2i(3, 5), "solido": true,
			"asset": "mueble.comun.banco_madera" },
		  { "tipo": "banco",      "casilla": Vector2i(6, 5), "solido": true,
			"asset": "mueble.comun.banco_madera" },
		  { "tipo": "estanteria", "casilla": Vector2i(2, 1), "solido": true,
			"asset": "mueble.capitania.estanteria_nautica" },
		  { "tipo": "escalera",   "casilla": Vector2i(7, 3), "solido": true,
			"asset": "mueble.comun.escalera_madera", "huella": Vector2i(1, 2),
			"destino_zona": "interior_capitania_pa",
			"entrada_destino": Vector2i(6, 4), "accion": "Subir" },
		  { "tipo": "cofre",      "casilla": Vector2i(2, 5), "solido": true,
			"definicion": "cofre_oxidado", "contenido": { "ron": 3 },
			"asset_cerrado": "mueble.comun.cofre_hierro.cerrado",
			"asset_abierto": "mueble.comun.cofre_hierro.abierto" },
	  ] },

	# Primera zona adicional del mismo edificio. Reutiliza el kit modular de
	# suelo, muros y muebles; luego podrá recibir arte propio sin tocar lógica.
	{ "id": "interior_capitania_pa", "nombre": "Capitanía · Planta Alta",
	  "tipo": "capitania", "ancho": 9, "alto": 8, "suelo": "madera",
	  "salida_exterior": false,
	  "asset_suelo": "interior.capitania_v1.suelo_madera",
	  "asset_muro_norte": "interior.capitania_v1.muro_norte",
	  "asset_muro_oeste": "interior.capitania_v1.muro_oeste",
	  "entrada": Vector2i(6, 4),
	  "muebles": [
		  { "tipo": "mesa",       "casilla": Vector2i(4, 2), "solido": true,
			"asset": "mueble.capitania.escritorio", "huella": Vector2i(2, 1) },
		  { "tipo": "estanteria", "casilla": Vector2i(2, 1), "solido": true,
			"asset": "mueble.capitania.estanteria_nautica" },
		  { "tipo": "banco",      "casilla": Vector2i(3, 4), "solido": true,
			"asset": "mueble.comun.banco_madera" },
		  { "tipo": "escalera",   "casilla": Vector2i(7, 3), "solido": true,
			"asset": "mueble.comun.escalera_madera_bajada", "huella": Vector2i(1, 2),
			"destino_zona": "interior_capitania_pb",
			"entrada_destino": Vector2i(6, 4), "accion": "Bajar" },
		  { "tipo": "cofre",      "casilla": Vector2i(2, 5), "solido": true,
			"definicion": "cofre_oxidado", "contenido": { "mapa_tesoro": 1 },
			"asset_cerrado": "mueble.comun.cofre_hierro.cerrado",
			"asset_abierto": "mueble.comun.cofre_hierro.abierto" },
	  ] },
]

# ---------------------------------------------------------------------------
# ANIMALES Y FAUNA
# ---------------------------------------------------------------------------

const TABLA_ANIMALES := [
	{ "id": "cerdo_salvaje", "nombre": "Cerdos Salvajes de la Isla", "tipo": "ganado",
	  "produce": { "grasa_ballena": 1, "carne_salada": 1 }, "consume": { "fertilizante": 1 },
	  "desc": "Fuente de grasa y carne. Sí, la 'grasa de ballena' a veces es de cerdo." },

	{ "id": "cabra_montana", "nombre": "Cabras de Montaña", "tipo": "ganado",
	  "produce": { "cuero": 2 }, "consume": {},
	  "desc": "Cuero resistente. Suben donde no sube nadie." },

	{ "id": "loro_vigia", "nombre": "Loros Vigías", "tipo": "utilidad",
	  "produce": {}, "consume": { "raciones": 1 },
	  "desc": "Asignables a un personaje: amplían el radio de visión en la niebla." },

	{ "id": "rata_muelle", "nombre": "Ratas de Muelle", "tipo": "plaga",
	  "produce": {}, "consume": { "raciones": 3 },
	  "contramedida": "gato_de_barco",
	  "desc": "Se comen tus raciones cada día si el almacén no tiene un Gato de Barco." },

	{ "id": "mono_ladron", "nombre": "Monos Ladrones", "tipo": "plaga",
	  "produce": {}, "consume": { "doblon": 25 },
	  "contramedida": "cofre_nivel_2",
	  "desc": "Evento aleatorio: roban doblones si los cofres no están mejorados." },
]

# ---------------------------------------------------------------------------
# CARGA
# ---------------------------------------------------------------------------

const TABLA_FUENTES := [
	{ "id": "restos_naufragio", "nombre": "Restos de Naufragio",
	  "tipo": "naufragio", "zona": "costa",
	  "productos": { "madera_naufragio": 2, "polvora_humeda": 1 },
	  "ciclos_maximos": 1, "regeneracion_horas": 24.0 },
	{ "id": "arbol_manglar", "nombre": "Manglar Aprovechable",
	  "tipo": "arbol", "zona": "bosque",
	  "productos": { "madera_naufragio": 3, "carbon": 1 },
	  "ciclos_maximos": 3, "regeneracion_horas": 48.0 },
	{ "id": "veta_azufre", "nombre": "Veta de Azufre Volcanico",
	  "tipo": "veta", "zona": "montana",
	  "productos": { "azufre_volcanico": 2 },
	  "ciclos_maximos": 2, "regeneracion_horas": 72.0 },
]

const TABLA_DESTINOS := [
	{ "id": "isla_principal", "nombre": "Marea y Ceniza", "tipo": "isla",
	  "mapa_id": "isla_principal", "coordenadas": Vector2(0, 0), "puerto": true,
	  "descripcion": "La guarida corsaria y su puerto principal." },
	{ "id": "portobello", "nombre": "Portobello", "tipo": "ciudad",
	  "mapa_id": "isla_portobello", "coordenadas": Vector2(1, -1), "puerto": true,
	  "descripcion": "Ciudad mercante donde opera el mercado negro." },
	{ "id": "isla_ceniza", "nombre": "Isla Ceniza", "tipo": "isla",
	  "mapa_id": "isla_ceniza", "coordenadas": Vector2(-1, 1), "puerto": true,
	  "descripcion": "Isla volcánica rica en azufre." },
	{ "id": "fortaleza_corona", "nombre": "Fortaleza de la Corona", "tipo": "fortaleza",
	  "mapa_id": "fortaleza_corona", "coordenadas": Vector2(2, 1), "puerto": true,
	  "descripcion": "Puesto naval imperial y objetivo de alto riesgo." },
]

const TABLA_RUTAS_GLOBALES := [
	{ "id": "principal_portobello", "origen": "isla_principal", "destino": "portobello",
	  "barco": "bergantin", "dias": 2, "riesgo": 0.15 },
	{ "id": "principal_ceniza", "origen": "isla_principal", "destino": "isla_ceniza",
	  "barco": "balandra", "dias": 2, "riesgo": 0.25 },
	{ "id": "principal_fortaleza", "origen": "isla_principal", "destino": "fortaleza_corona",
	  "barco": "galeon", "dias": 4, "riesgo": 0.60 },
	{ "id": "portobello_principal", "origen": "portobello", "destino": "isla_principal",
	  "barco": "bergantin", "dias": 2, "riesgo": 0.15 },
	{ "id": "ceniza_principal", "origen": "isla_ceniza", "destino": "isla_principal",
	  "barco": "balandra", "dias": 2, "riesgo": 0.25 },
]

const TABLA_HORARIOS := [
	{ "id": "tripulacion", "nombre": "Rutina de tripulación",
	  "tramos": [
		{ "desde": 0.0, "hasta": 7.0, "actividad": "dormir" },
		{ "desde": 7.0, "hasta": 8.0, "actividad": "casa" },
		{ "desde": 8.0, "hasta": 12.0, "actividad": "trabajar" },
		{ "desde": 12.0, "hasta": 13.0, "actividad": "comer" },
		{ "desde": 13.0, "hasta": 18.0, "actividad": "trabajar" },
		{ "desde": 18.0, "hasta": 20.0, "actividad": "pasear" },
		{ "desde": 20.0, "hasta": 22.0, "actividad": "taberna" },
		{ "desde": 22.0, "hasta": 24.0, "actividad": "dormir" },
	  ] },
	{ "id": "herrero", "nombre": "Jornada del herrero",
	  "tramos": [
		{ "desde": 0.0, "hasta": 6.0, "actividad": "dormir" },
		{ "desde": 6.0, "hasta": 7.0, "actividad": "casa" },
		{ "desde": 7.0, "hasta": 12.0, "actividad": "trabajar" },
		{ "desde": 12.0, "hasta": 13.0, "actividad": "comer" },
		{ "desde": 13.0, "hasta": 18.0, "actividad": "trabajar" },
		{ "desde": 18.0, "hasta": 20.0, "actividad": "casa" },
		{ "desde": 20.0, "hasta": 22.0, "actividad": "taberna" },
		{ "desde": 22.0, "hasta": 24.0, "actividad": "dormir" },
	  ] },
	{ "id": "tabernero", "nombre": "Jornada del tabernero",
	  "tramos": [
		{ "desde": 0.0, "hasta": 8.0, "actividad": "dormir" },
		{ "desde": 8.0, "hasta": 12.0, "actividad": "trabajar" },
		{ "desde": 12.0, "hasta": 16.0, "actividad": "casa" },
		{ "desde": 16.0, "hasta": 24.0, "actividad": "taberna" },
	  ] },
	{ "id": "muelle", "nombre": "Jornada del muelle",
	  "tramos": [
		{ "desde": 0.0, "hasta": 6.0, "actividad": "dormir" },
		{ "desde": 6.0, "hasta": 12.0, "actividad": "trabajar" },
		{ "desde": 12.0, "hasta": 13.0, "actividad": "comer" },
		{ "desde": 13.0, "hasta": 18.0, "actividad": "trabajar" },
		{ "desde": 18.0, "hasta": 22.0, "actividad": "pasear" },
		{ "desde": 22.0, "hasta": 24.0, "actividad": "dormir" },
	  ] },
]

var items: Dictionary = {}        ## id -> ItemData
var recetas: Dictionary = {}      ## id -> RecetaData
var edificios: Dictionary = {}    ## id -> EdificioData
var personajes: Dictionary = {}   ## id -> PersonajeData
var animales: Dictionary = {}     ## id -> AnimalData
var interiores: Dictionary = {}   ## id -> InteriorDefinicion
var horarios: Dictionary = {}     ## id -> HorarioData
var fuentes: Dictionary = {}      ## id -> FuenteRecursoData
var destinos: Dictionary = {}     ## id -> DestinoData
var rutas: Dictionary = {}        ## id -> RutaGlobalData

func _ready() -> void:
	for d in TABLA_ITEMS:
		var it := ItemData.desde_dic(d)
		items[it.id] = it
	for d in TABLA_RECETAS:
		var r := RecetaData.desde_dic(d)
		recetas[r.id] = r
	for d in TABLA_EDIFICIOS:
		var e := EdificioData.desde_dic(d)
		edificios[e.id] = e
	for d in TABLA_PERSONAJES:
		var p := PersonajeData.desde_dic(d)
		personajes[p.id] = p
	for d in TABLA_ANIMALES:
		var a := AnimalData.desde_dic(d)
		animales[a.id] = a
	for d in TABLA_INTERIORES:
		var n := InteriorDefinicion.desde_dic(d)
		interiores[n.id] = n
	for d in TABLA_HORARIOS:
		var h: HorarioData = HorarioData.desde_dic(d)
		horarios[h.id] = h
	for d in TABLA_FUENTES:
		var f = FuenteRecursoDataScript.desde_dic(d)
		fuentes[f.id] = f
	for d in TABLA_DESTINOS:
		var destino = DestinoDataScript.desde_dic(d)
		destinos[destino.id] = destino
	for d in TABLA_RUTAS_GLOBALES:
		var ruta = RutaGlobalDataScript.desde_dic(d)
		rutas[ruta.id] = ruta
	_validar()
	print("[BaseDeDatos] %d ítems, %d recetas, %d edificios, %d personajes, %d animales."
		% [items.size(), recetas.size(), edificios.size(), personajes.size(), animales.size()])

## Avisa en consola si una receta menciona un ítem que no existe.
## Es el error nº1 al añadir contenido a mano.
func _validar() -> void:
	for r: RecetaData in recetas.values():
		for grupo in [r.insumos, r.productos]:
			for id in grupo:
				if not items.has(id):
					push_warning("Receta '%s' usa un ítem inexistente: '%s'" % [r.id, id])
		for orig in r.sustitutos:
			var s: Dictionary = r.sustitutos[orig]
			if not items.has(s.get("id", "")):
				push_warning("Receta '%s': sustituto inexistente '%s'" % [r.id, s.get("id", "")])
	for e: EdificioData in edificios.values():
		for rid in e.recetas:
			if not recetas.has(rid):
				push_warning("Edificio '%s' apunta a una receta inexistente: '%s'" % [e.id, rid])
		if e.interior != "" and not interiores.has(e.interior):
			push_warning("Edificio '%s' apunta a un interior inexistente: '%s'" % [e.id, e.interior])
	for n: InteriorDefinicion in interiores.values():
		var ent := n.entrada_valida()
		if ent != n.entrada:
			push_warning("Interior '%s': la entrada %s cae en la pared; se usará %s"
				% [n.id, n.entrada, ent])

# --- accesos cómodos (devuelven null si no existe, nunca revientan) ---

func item(id: String) -> ItemData:
	return items.get(id)

func receta(id: String) -> RecetaData:
	return recetas.get(id)

func edificio(id: String) -> EdificioData:
	return edificios.get(id)

func personaje(id: String) -> PersonajeData:
	return personajes.get(id)

func animal(id: String) -> AnimalData:
	return animales.get(id)

func interior(id: String) -> InteriorDefinicion:
	return interiores.get(id)

func horario(id: String) -> HorarioData:
	return horarios.get(id, horarios.get("tripulacion"))

func fuente(id: String) -> Resource:
	return fuentes.get(id)

func destino(id: String) -> Resource:
	return destinos.get(id)

func ruta(id: String) -> Resource:
	return rutas.get(id)

func nombre_item(id: String) -> String:
	var it: ItemData = items.get(id)
	return it.nombre if it != null else id
