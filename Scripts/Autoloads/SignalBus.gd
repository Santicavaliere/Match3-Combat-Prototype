extends Node

# Aquí definiremos todas las señales globales del juego

# Eventos de la Grilla
signal grid_generated
signal match_found(gem_type: String, amount: int) # Esta la escuchará el combate
signal turn_ended

# Eventos de Combate
signal enemy_damaged(amount: int)
signal player_healed(amount: int)
