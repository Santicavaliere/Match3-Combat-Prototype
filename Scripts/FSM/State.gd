class_name State extends Node

# Referencia al objeto que controla este estado (ej: la Pieza o el Tablero)
var state_machine = null
var context = null 

func enter():
	pass # Se ejecuta al entrar al estado

func exit():
	pass # Se ejecuta al salir del estado

func update(_delta: float):
	pass # Se ejecuta en _process

func physics_update(_delta: float):
	pass # Se ejecuta en _physics_process
