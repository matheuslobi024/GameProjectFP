@tool
extends Node3D

@export var speed: float = 0.002


func _process(delta):
	rotate_y(speed * delta)
