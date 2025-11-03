@tool
extends DirectionalLight3D

func _process(_delta):
	($"../../CharacterBody3D/Node3D/Camera3D/PostProcessing" as MeshInstance3D).mesh.surface_get_material(0).set_shader_parameter('light_direction', -global_basis.z)
