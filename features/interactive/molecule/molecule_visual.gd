@tool
## MoleculeVisual
## Data-driven molecular structure renderer using Godot's _draw() API.
## Reads MoleculeData to draw atoms, bonds, and labels with perspective.
## No hardcoded molecular structures — pure data-driven rendering.
extends Node2D

const MoleculeData = preload("res://data/definitions/molecule/molecule_data.gd")
const MoleculeBondData = preload("res://data/definitions/molecule/molecule_bond_data.gd")
const MoleculeAtomData = preload("res://data/definitions/molecule/molecule_atom_data.gd")

@export var molecule_data: Resource:  # Runtime-casted to MoleculeData
	set(value):
		molecule_data = value
		if Engine.is_editor_hint() or is_node_ready():
			queue_redraw()

@export var ring_radius: float = 36.0:     # Scale factor for molecule layout
	set(value):
		ring_radius = value
		if Engine.is_editor_hint() or is_node_ready():
			queue_redraw()

@export var base_atom_radius: float = 12.0: # Base radius, overridden per-atom if MoleculeAtomData provides one
	set(value):
		base_atom_radius = value
		if Engine.is_editor_hint() or is_node_ready():
			queue_redraw()

@export var perspective_y_scale: float = 0.45: # Y foreshortening for pseudo-3D perspective
	set(value):
		perspective_y_scale = value
		if Engine.is_editor_hint() or is_node_ready():
			queue_redraw()


var _pulse: float = 0.0


func _ready() -> void:
	if molecule_data != null and molecule_data.validate():
		queue_redraw()


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		_pulse = (sin(Time.get_ticks_msec() / 800.0) + 1.0) * 0.5
		queue_redraw()


func set_molecule_data(data: MoleculeData) -> void:
	molecule_data = data
	if molecule_data != null and molecule_data.validate():
		queue_redraw()


func _draw() -> void:
	if molecule_data == null or molecule_data.atoms.is_empty():
		return
	
	_draw_bonds()
	_draw_atoms()


## ================================================================
##  Bond rendering
## ================================================================
func _draw_bonds() -> void:
	for bond in molecule_data.bonds:
		if bond.atom_a_index >= molecule_data.atoms.size() or bond.atom_b_index >= molecule_data.atoms.size():
			continue
		
		var atom_a: MoleculeAtomData = molecule_data.atoms[bond.atom_a_index]
		var atom_b: MoleculeAtomData = molecule_data.atoms[bond.atom_b_index]
		
		var pos_a := _to_screen(atom_a.position)
		var pos_b := _to_screen(atom_b.position)
		var r_a: float = atom_a.radius if atom_a.radius > 0.0 else base_atom_radius
		var r_b: float = atom_b.radius if atom_b.radius > 0.0 else base_atom_radius
		# Apply the same perspective scale that atoms get in _draw_atoms()
		var center_y := _to_screen(Vector2.ZERO).y
		var depth_factor_a := clampf(1.0 - (pos_a.y - center_y) * 0.003, 0.6, 1.4)
		var depth_factor_b := clampf(1.0 - (pos_b.y - center_y) * 0.003, 0.6, 1.4)
		r_a *= depth_factor_a
		r_b *= depth_factor_b
		
		match bond.bond_type:
			MoleculeBondData.BondType.SOLID:
				_draw_solid_bond(pos_a, pos_b, bond.color, bond.width, r_a, r_b)
			MoleculeBondData.BondType.DASHED:
				_draw_dashed_bond(pos_a, pos_b, bond.color, bond.width, r_a, r_b)
			MoleculeBondData.BondType.WEDGE:
				_draw_wedge_bond(pos_a, pos_b, bond.color, bond.width, r_a, r_b)


func _draw_solid_bond(a: Vector2, b: Vector2, color: Color, width: float, radius_a: float, radius_b: float) -> void:
	# Clip bond endpoints to atom radius edges so the bond doesn't
	# visually disappear inside the atom circles.
	var dir := (b - a).normalized()
	var start: Vector2 = a + dir * radius_a
	var end:   Vector2 = b - dir * radius_b
	
	var glow_color := Color(color.r, color.g, color.b, 0.25 + _pulse * 0.1)
	draw_line(start, end, glow_color, width + 5.0)
	draw_line(start, end, color, width)


## Dashed line for bonds pointing away from viewer
func _draw_dashed_bond(a: Vector2, b: Vector2, color: Color, width: float, radius_a: float, radius_b: float) -> void:
	var dir := (b - a).normalized()
	var start: Vector2 = a + dir * radius_a
	var end:   Vector2 = b - dir * radius_b
	
	var segments: int = 4
	var step := (end - start) / float(segments)
	for i in range(segments):
		if i % 2 == 0:
			draw_line(start + step * float(i), start + step * float(i + 1), color, width)


## Wedge/thick bond for bonds pointing toward viewer
func _draw_wedge_bond(a: Vector2, b: Vector2, color: Color, width: float, radius_a: float, radius_b: float) -> void:
	var dir := (b - a).normalized()
	var start: Vector2 = a + dir * radius_a
	var end:   Vector2 = b - dir * radius_b
	
	draw_line(start, end, color, width * 1.5)
	var perp := Vector2(-dir.y, dir.x).normalized() * 4.0
	draw_line(end, end - dir * 8.0 + perp, color, width * 0.7)
	draw_line(end, end - dir * 8.0 - perp, color, width * 0.7)


## ================================================================
##  Atom rendering (back-to-front for perspective)
## ================================================================
func _draw_atoms() -> void:
	# Sort atoms by screen Y (lowest Y = furthest back, drawn first)
	var sorted_indices: Array[int] = []
	for i in range(molecule_data.atoms.size()):
		sorted_indices.append(i)
	
	# Simple bubble sort by screen Y position (few atoms, so perf not issue)
	for i in range(sorted_indices.size()):
		for j in range(i + 1, sorted_indices.size()):
			var y_i: float = _to_screen(molecule_data.atoms[sorted_indices[i]].position).y
			var y_j: float = _to_screen(molecule_data.atoms[sorted_indices[j]].position).y
			if y_i > y_j:
				var tmp: int = sorted_indices[i]
				sorted_indices[i] = sorted_indices[j]
				sorted_indices[j] = tmp
	
	for idx in sorted_indices:
		var atom: MoleculeAtomData = molecule_data.atoms[idx]
		var screen_pos := _to_screen(atom.position)
		var r: float = atom.radius if atom.radius > 0.0 else base_atom_radius
		
		# Perspective scale based on screen Y position relative to molecule center
		var center_y := _to_screen(Vector2.ZERO).y
		var depth_factor := 1.0 - (screen_pos.y - center_y) * 0.003
		depth_factor = clampf(depth_factor, 0.6, 1.4)
		r *= depth_factor
		
		_draw_atom(screen_pos, r, atom.color, atom.label, atom.label_color, atom.label_size)


func _draw_atom(pos: Vector2, r: float, color: Color, label: String = "", label_color: Color = Color.BLACK, label_size: int = 0) -> void:
	# Glow
	var glow := Color(color.r, color.g, color.b, 0.22 + _pulse * 0.08)
	draw_circle(pos, r + 4.0 + _pulse * 2.0, glow)
	# Atom body
	draw_circle(pos, r, color)
	# Label
	if not label.is_empty():
		var font_size: int = label_size if label_size > 0 else 18
		_draw_text_centered(pos, label, font_size, label_color)


## ================================================================
##  Coordinate helpers — apply perspective and overall scale
## ================================================================
func _to_screen(local_pos: Vector2) -> Vector2:
	"""Transform local molecule coordinates to screen coordinates with perspective foreshortening."""
	# Apply Y foreshortening for pseudo-3D Haworth projection
	var persp_pos := Vector2(local_pos.x, local_pos.y * perspective_y_scale)
	# Scale by ring_radius so molecule_data positions are unitless (-1 to +1 roughly)
	return persp_pos * ring_radius


## ================================================================
##  Text rendering
## ================================================================
func _draw_text_centered(pos: Vector2, text: String, size: int, color: Color) -> void:
	var font := ThemeDB.fallback_font
	var sz := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, size)
	var ascent: float = font.get_ascent(size)
	var descent: float = font.get_descent(size)
	# draw_string places text at the baseline; shift so visual center lands on 'pos'
	var baseline_shift: float = (ascent - descent) * 0.5
	var draw_pos := Vector2(pos.x - sz.x * 0.5, pos.y + baseline_shift)
	draw_string(font, draw_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
