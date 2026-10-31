extends CharacterBody2D

# =============================================================================
# FÍSICAS DE MARIO (SMB1 NES) EN GODOT - VERSIÓN COMENTADA
#
# IDEA CLAVE: la NES guarda las velocidades como números en "punto fijo":
#   parte entera (píxeles) + subpíxeles en fracciones de 1/16, 1/256 y 1/4096.
# Por eso las constantes se escriben como fracciones (ej: 9.0/256 + 8.0/4096).
# Esos valores son "píxeles por frame" (la NES corre a 60 fps).
#
# CONVERSIÓN A GODOT/LOVE (que trabajan en segundos):
#   - velocidad:    px/frame      * 60      = px/segundo
#   - aceleración:  px/frame^2    * 60 * 60 = px/segundo^2
# Por eso las velocidades llevan "*60" y las aceleraciones "*60 *60".
# =============================================================================

# Nodos asignados desde el editor de Godot (en Love2D serían campos de tu objeto jugador)
@export var body:Node2D            # Nodo visual (sprite) que se voltea y se dibuja redondeado
@export var anim:AnimationPlayer   # Reproductor de animaciones (Idle, Walk, Skid, Jump)

# ---------------------------------------------------------------------------
# VARIABLES DE ESTADO
# ---------------------------------------------------------------------------
var acc:					= 0.0	# Aceleración horizontal actual (walk_acc o run_acc)
var is_skidding:			= false	# true mientras Mario "derrapa" (frena al cambiar de dirección)

# Estos 4 flags se calculan EN EL SUELO y quedan "congelados" en el aire.
# Así funciona el original: la velocidad con la que despegás decide cómo se
# comporta todo el salto (gravedad, altura, control en el aire).
var faster_air_limit:		= false		# Salto empezó con velocidad > max_walk  -> permite llegar hasta max_run en el aire
var faster_air_spd:			= false		# Salto empezó con velocidad > air_spd_treshold -> cambia el "drag" al invertir dirección
var fast_jump:				= false		# Salto empezó con velocidad > fast_jump_treshold -> gravedad media
var fastest_jump:			= false		# Salto empezó con velocidad > fastest_jump_treshold -> gravedad grande + salto más alto
var direction:				= 0.0		# Dirección horizontal del input (-1 izquierda, 0 nada, 1 derecha)
var is_grounded:			= true		# ¿Está en el suelo? (se actualiza al final del update)

# Buffer de sprint: en el original, soltar el botón B no te quita la velocidad
# de carrera de inmediato; hay un margen de frames. Se cuenta en FRAMES, no en segundos.
var sprint_buffer:			= 0
var sprint_buffer_amount:	= 10		# Cantidad de frames de margen

# ---------------------------------------------------------------------------
# CONSTANTES (valores originales de la NES, convertidos a px/s y px/s^2)
# ---------------------------------------------------------------------------
# --- Movimiento en el suelo ---
const walk_acc:					= (9.0/256 + 8.0/(16*16*16)) 	*60	*60	# Aceleración caminando
const run_acc:					= (14.0/256 + 4.0/(16*16*16))	*60	*60	# Aceleración corriendo (botón B)
const min_walk:					= (1.0/16 + 3.0/256)			*60		# Velocidad mínima al arrancar desde quieto
const max_walk:					= (1 + 9.0/16)					*60		# Velocidad máxima caminando
const max_run:					= (2 + 9.0/16)					*60		# Velocidad máxima corriendo
const release_deacc:			= (13.0/256)					*60	*60	# Desaceleración al soltar la dirección
const skid_deacc:				= (1.0/16 + 10.0/256)			*60	*60	# Desaceleración al derrapar (más fuerte)
const turn_treshold:			= (9.0/16)						*60		# Debajo de esta velocidad, el derrape corta a 0 de golpe

# --- Control en el aire ---
const air_spd_treshold:			= (1 + 13.0/16)					*60		# Umbral de velocidad de despegue para elegir el drag
const air_slow_acc:				= (9.0/256 + 8.0/(16*16*16))	*60	*60	# Aceleración en el aire (velocidad lenta)
const air_fast_acc:				= (14.0/256 + 4.0/(16*16*16))	*60	*60	# Aceleración en el aire (velocidad >= max_walk)
const air_fast_drag:			= (13.0/256)					*60		# OJO: es una VELOCIDAD (no aceleración): se asigna directo al invertir dirección (despegue rápido)
const air_slow_drag:			= (9.0/256 + 8.0/(16*16*16))	*60		# Ídem, para despegue lento

# --- Salto y gravedad ---
const jump_spd:					= 4.0							*60		# Velocidad inicial del salto normal
const big_jump_spd:				= 5.0							*60		# Velocidad inicial del salto con mucha velocidad (más alto)
# "up_drag" = gravedad mientras SUBÍS y mantenés el botón de salto (más suave => salto más alto)
const small_up_drag:			= (2.0/16)						*60	*60
const medium_up_drag:			= (1.0/16 + 14.0/256)			*60	*60
const big_up_drag:				= (2.0/16 + 8.0/256)			*60	*60
# "gravity" = gravedad normal (al bajar, o al subir sin mantener el botón => salto corto)
const small_gravity:			= (7.0/16)						*60	*60
const medium_gravity:			= (6.0/16)						*60	*60
const big_gravity:				= (9.0/16)						*60	*60
const fast_jump_treshold:		= 1.0							*60		# Velocidad de despegue para categoría "fast"
const fastest_jump_treshold:	= (2 + 5.0/16)					*60		# Velocidad de despegue para categoría "fastest"
const max_fall:					= 4.0							*60		# Velocidad máxima de caída (terminal)

# ---------------------------------------------------------------------------
# INPUTS
# ---------------------------------------------------------------------------
# Se guardan en variables propias en vez de consultar Input a cada rato.
# input_jump_p = "previous": estado del botón de salto en el frame anterior,
# sirve para detectar el instante exacto en que se presiona (flanco).
var input_right:	= 0.0
var input_left:		= 0.0
var input_up:		= 0.0
var input_down:		= 0.0
var input_jump:		= false
var input_jump_p:	= false
var input_action:	= false	# Botón B (correr)

func _unhandled_input(event:InputEvent)->void:
	# Cada evento actualiza solo su variable correspondiente.
	# get_action_strength devuelve 0..1 (útil para gamepad analógico).
	if event.is_action("input_right"):
		input_right		= Input.get_action_strength("input_right")
	elif event.is_action("input_left"):
		input_left		= Input.get_action_strength("input_left")
	elif event.is_action("input_up"):
		input_up		= Input.get_action_strength("input_up")
	elif event.is_action("input_down"):
		input_down		= Input.get_action_strength("input_down")
	elif event.is_action("input_jump"):
		input_jump		= Input.is_action_pressed("input_jump")
	elif event.is_action("input_action"):
		input_action	= Input.is_action_pressed("input_action")
	# Herramienta de debug: mantener "ui_accept" pone el juego en cámara lenta
	elif event.is_action_pressed("ui_accept"):
		Engine.time_scale = 0.5
	elif event.is_action_released("ui_accept"):
		Engine.time_scale = 1.0

func _process(delta:float)->void:				#Drawing
	# Primero la lógica y después las animaciones.
	# NOTA: la física corre en _process (frame de dibujo) y no en _physics_process,
	# así que depende del framerate. En Love2D esto equivale a hacerlo en love.update(dt).
	update(delta)
	animation_states()

func update(delta:float)->void:
	# Combina izquierda y derecha: si ambas están presionadas se anulan (0)
	direction = input_right - input_left
	var dir:float = sign(direction)		# -1, 0 o 1 (dirección "pura", sin analógico)
	
	# =========================================================================
	# EN EL SUELO
	# =========================================================================
	if is_grounded:
		# Una pequeña gravedad constante pegada al piso: sin esto is_on_floor()
		# no detecta el suelo de forma estable.
		velocity.y = small_gravity *delta									#need to have a little gravity for ground detection

		# --- Elegir aceleración según si se mantiene B ---
		if input_action:
			sprint_buffer = sprint_buffer_amount	# Recargar el margen de sprint
			acc = run_acc
		else:
			if sprint_buffer > 0:
				sprint_buffer -= 1					# Gastar el margen de a 1 por frame
			acc = walk_acc

		# --- Hay dirección presionada ---
		if abs(direction) > 0.01:
			# Derrape: se está moviendo en sentido contrario al input
			is_skidding = sign(velocity.x) != dir && abs(velocity.x) > 0.00001
			if is_skidding:
				if abs(velocity.x) > turn_treshold:
					# Todavía rápido: frenar de a poco. Sumar skid_deacc*dir
					# funciona porque dir tiene signo opuesto a velocity.x.
					velocity.x += skid_deacc * dir * delta
				else:
					# Ya lento: cortar a 0 de golpe (así da el "tirón" del original)
					velocity.x = 0.0
			else:
				if is_equal_approx(velocity.x, 0.0):   						#no velocity.x
					# Arrancando desde quieto: velocidad mínima inicial (no empieza en 0)
					velocity.x = min_walk * dir
				else:
					velocity.x += acc * dir * delta
				# Límites de velocidad
				if abs(velocity.x) > max_walk && sprint_buffer == 0:
					# Sin B (y sin margen de sprint): no puede pasar de max_walk
					velocity.x = max_walk * dir
				elif abs(velocity.x) > max_run:								#clamp velocity to max_run
					velocity.x = max_run * dir
		# --- No hay dirección presionada ---
		else:   															#no direction pressed
			# Si venía derrapando usa la desaceleración fuerte, si no la normal
			var de_acc: = skid_deacc if is_skidding else release_deacc
			if abs(velocity.x) < de_acc * delta:
				velocity.x = 0		# Evita pasarse de 0 y oscilar
			else:
				velocity.x -= de_acc * sign(velocity.x) * delta

		# --- Clasificar el salto según la velocidad ACTUAL en el suelo ---
		# Se recalcula cada frame en el piso; al despegar queda congelado.
		var abs_spd:float		= abs(velocity.x)
		fastest_jump		= abs_spd > fastest_jump_treshold
		fast_jump			= abs_spd > fast_jump_treshold
		faster_air_limit	= abs_spd > max_walk
		faster_air_spd		= abs_spd > air_spd_treshold
		# --- Iniciar salto: solo en el frame en que se presiona el botón ---
		if input_jump && !input_jump_p:										#just pressed
			# Y negativa = hacia arriba. Con mucha velocidad el salto es más potente.
			velocity.y = -big_jump_spd if fastest_jump else -jump_spd
	
	# =========================================================================
	# EN EL AIRE
	# =========================================================================
	else:	#MIDAIR
		# --- Control horizontal en el aire ---
		if abs(direction) > 0.01:
			if abs(velocity.x) >= max_walk:
				# Yendo rápido: aceleración de aire rápida
				velocity.x += air_fast_acc * dir * delta
			else:
				if sign(velocity.x) == dir:									#pointing same direction
					velocity.x += air_slow_acc * dir * delta
				else:														#pointing opposite direction
					# Invertir dirección en el aire: la velocidad se SETEA directamente
					# (no se acelera). El valor depende de la velocidad de despegue.
					velocity.x = (air_fast_drag if faster_air_spd else air_slow_drag) * dir

		# --- Límite horizontal en el aire ---
		# Si despegaste a más de max_walk podés llegar a max_run; si no, quedás en max_walk.
		if faster_air_limit:
			velocity.x = clamp(velocity.x, -max_run, max_run)
		else:
			velocity.x = clamp(velocity.x, -max_walk, max_walk)

		# --- Gravedad vertical ---
		# Subiendo (velocity.y < 0) Y manteniendo el botón: gravedad suave => salto alto.
		# Si soltás el botón, se aplica la gravedad normal (más fuerte) => salto corto.
		# El tipo de gravedad (small/medium/big) lo decide la velocidad de despegue.
		if velocity.y < 0.0 && input_jump:
			if fastest_jump:
				velocity.y += big_up_drag * delta
			elif fast_jump:
				velocity.y += medium_up_drag * delta
			else:
				velocity.y += small_up_drag * delta
		else:
			if fastest_jump:
				velocity.y += big_gravity * delta
			elif fast_jump:
				velocity.y += medium_gravity * delta
			else:
				velocity.y += small_gravity * delta
		# Velocidad terminal de caída
		if velocity.y > max_fall:
			velocity.y = max_fall
	
	# =========================================================================
	# FINAL DEL FRAME
	# =========================================================================
	input_jump_p = input_jump												#save old jump button state
	move_and_slide()			# Mueve el cuerpo usando "velocity" y resuelve colisiones (función propia de Godot)
	is_grounded = is_on_floor()	# Para el próximo frame: ¿estamos tocando el piso?


func animation_states()->void:
	# Voltear el sprite según hacia dónde se mira (solo si hay input)
	if	!is_equal_approx(direction, 0.0):
		body.scale.x = sign(direction)			#flip sprite
	# Dibujar el sprite en posición entera: evita el "temblor" de subpíxeles (look pixel-perfect)
	body.global_position = global_position.round()
	if is_grounded:
		if is_equal_approx(velocity.x, 0.0):
			anim.play("Idle")
		else:
			if is_skidding:
				anim.play("Skid")
			else:
				anim.play("Walk")
				# La animación de caminar va más rápida cuanto más rápido corre Mario
				if abs(velocity.x) >= max_walk:
					anim.speed_scale = 1.96
				elif abs(velocity.x) >= min_walk:
					anim.speed_scale = 1.62
				else:
					anim.speed_scale = 1
	else:
		anim.play("Jump")