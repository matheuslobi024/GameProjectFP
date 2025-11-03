extends Node

# Ajuste a resolução padrão usada pelo seu shader (deve bater com target_resolution do shader)
@export var target_resolution: Vector2 = Vector2(640, 360)

@onready var ground_vp: Viewport = $SubViewportContainer/SubViewport/CharacterBody3D/Node3D/Camera3D/PostProcessing/GroundViewport
# câmera principal fora do Viewport (na sua árvore)
@onready var main_cam: Camera3D = $SubViewportContainer/SubViewport/CharacterBody3D/Node3D/Camera3D
# câmera que está dentro do GroundViewport (renderiza só a layer do chão)
@onready var vp_cam: Camera3D = $SubViewportContainer/SubViewport/CharacterBody3D/Node3D/Camera3D/PostProcessing/GroundViewport/GroundCamera3D
# nó que contém o material de pós-processo (assumimos que é um MeshInstance ou similar)
@onready var postprocess_node: Node = $SubViewportContainer/SubViewport/CharacterBody3D/Node3D/Camera3D/PostProcessing

func _ready():
	# configurações do Viewport
	ground_vp.render_target = true
	ground_vp.render_target_update_mode = Viewport.VRS_UPDATE_ALWAYS
	_resize_viewport(target_resolution)
	# força o Viewport a usar 3D
	ground_vp.disable_3d = false

	# sincroniza câmera do Viewport com a câmera principal imediatamente
	_sync_viewport_camera()

	# passa a ViewportTexture ao shader
	_assign_mask_texture()

	# opcional: escuta redimensionamento da janela para ajustar o Viewport dinamicamente
	if has_node("/root/Root"):
		# se você tem um root custom, ignore; esta linha é apenas preventiva
		pass

func _process(delta):
	# sincroniza toda frame (útil se a câmera principal se mover)
	_sync_viewport_camera()

func _sync_viewport_camera():
	if not main_cam or not vp_cam:
		return
	# copia transform (posição e rotação) e algumas propriedades de projeção
	vp_cam.transform = main_cam.transform
	vp_cam.fov = main_cam.fov
	vp_cam.near = main_cam.near
	vp_cam.far = main_cam.far
	vp_cam.keep_aspect = main_cam.keep_aspect
	# se você usa projection mode diferente (ortho/perspective), copie também
	vp_cam.projection = main_cam.projection

func _resize_viewport(new_size: Vector2):
	if not ground_vp:
		return
	ground_vp.size = new_size
	# se o seu shader possui uniform target_resolution, atualize também (se material exposto)
	var mat := _get_shader_material()
	if mat:
		mat.set_shader_param("target_resolution", new_size)

func _assign_mask_texture():
	var mask_tex: Texture = ground_vp.get_texture()
	if not mask_tex:
		push_error("GroundViewport não possui texture ainda.")
		return
	var mat := _get_shader_material()
	if not mat:
		push_error("PostProcessing material não encontrado ou não é ShaderMaterial.")
		return
	mat.set_shader_param("ground_mask", mask_tex)

func _get_shader_material() -> ShaderMaterial:
	if not postprocess_node:
		return null
	# tenta MeshInstance / MeshInstance3D padrão (material em slot 0)
	if postprocess_node is MeshInstance3D:
		var m = postprocess_node.get_active_material(0)
		if m and m is ShaderMaterial:
			return m
	# tenta que seja um Sprite3D ou ImmediateGeometry com material
	if "material_override" in postprocess_node:
		var mo = postprocess_node.material_override
		if mo and mo is ShaderMaterial:
			return mo
	# tenta propriedade "material" genérica
	if postprocess_node.has_method("get_material"):
		var gm = postprocess_node.get_material()
		if gm and gm is ShaderMaterial:
			return gm
	return null
