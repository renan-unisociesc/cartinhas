@tool
class_name Card
extends TextureRect


const TEMPLATE_TEXTURE = "res://addons/tcg-toolkit/texture/card_example.png"
enum BorderPositions {Internal, Center, External}

@export_placeholder("Creature Name") var title = ""
@export_global_file("*.png") var title_icon

@export_global_file("*.png") var card_texture = Card.TEMPLATE_TEXTURE

@export_group("Draw Properties", "draw_")
@export_subgroup("size", "size_")
@export var size_minimum_size : Vector2
@export_flags("horizontal", "vertical") var size_auto_stretch = 0b00
@export_subgroup("border", "border_")
@export var border_active = false:
	set(value):
		border_active = value
		self.queue_redraw()
@export var border_width : int = 8:
	set(value):
		border_width = value
		if self.border_active:
			self.queue_redraw()
@export var border_radius : int = 20:
	set(value):
		border_radius = value if value >= 0 else 0
		if self.border_active:
			self.queue_redraw()
@export var border_color = Color("#ffdd00"):
	set(value):
		border_color = value
		if self.border_active:
			self.queue_redraw()
@export var border_anti_aliasing : bool = true:
	set(value):
		border_anti_aliasing = value
		if self.border_active:
			self.queue_redraw()
@export var border_position: BorderPositions = 1:
	set(value):
		border_position = value
		if self.border_active:
			self.queue_redraw()



func _enter_tree():
	# Insert to inherit object
	self.texture = load(self.card_texture)
	self.size_minimum_size = self.texture.get_size()
	self.custom_minimum_size = self._get("size_minimum_size")
	
	# Change default values
	#self.clip_contents = true
	self.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	self.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

func _get(property):
	if (property == "size_minimum_size"):
		var parent_size = self.get_parent().get_rect().size
		match self.size_auto_stretch:
			0b01:
				return Vector2(parent_size.x, self.size_minimum_size.y)
			0b10:
				return Vector2(self.size_minimum_size.x, parent_size.y)
			0b11:
				return parent_size
		return self.size_minimum_size

func _draw():
	if self.border_active:
		self._draw_border()



func _draw_border():
	var width = self.border_width
	var card_size = self.size_minimum_size
	if border_radius == 0:
		var border_rect = Rect2()
		match self.border_position:
			BorderPositions.Internal:
				border_rect = Rect2(width/2, width/2, card_size.x-width, card_size.y-width)
			BorderPositions.Center:
				border_rect = Rect2(0, 0, card_size.x, card_size.y)
			BorderPositions.External:
				border_rect = Rect2(-width/2, -width/2, card_size.x+width, card_size.y+width)
		
		self.draw_rect(border_rect, self.border_color, false, self.border_width)
	else: # calculate each border and draw using line and arc
		var edge_size = self.border_radius + (width / 2)
		var edge_radius = self.border_radius
		var arc_center = Vector2()
		var arc : Array = []
		var line_dist = width / 2
		var ali = self.border_anti_aliasing
		
		match self.border_position:
			BorderPositions.Center:
				edge_size = self.border_radius
				line_dist = 0
			BorderPositions.External:
				edge_size = self.border_radius - (width / 2)
				line_dist = -(width / 2)
		
		# top left edge
		arc = [deg_to_rad(180), deg_to_rad(270)]
		arc_center = Vector2(edge_size, edge_size)
		draw_arc(arc_center, edge_radius, arc[0], arc[1], 20, self.border_color, width, ali)
		# top right edge
		arc = [deg_to_rad(270), deg_to_rad(360)]
		arc_center = Vector2(card_size.x - edge_size, edge_size)
		draw_arc(arc_center, edge_radius, arc[0], arc[1], 20, self.border_color, width, ali)
		# bottom right edge
		arc = [deg_to_rad(0), deg_to_rad(90)]
		arc_center = Vector2(card_size.x - edge_size, card_size.y - edge_size)
		draw_arc(arc_center, edge_radius, arc[0], arc[1], 20, self.border_color, width, ali)
		# bottom left edge
		arc = [deg_to_rad(90), deg_to_rad(180)]
		arc_center = Vector2(edge_size, card_size.y - edge_size)
		draw_arc(arc_center, edge_radius, arc[0], arc[1], 20, self.border_color, width, ali)
		
		var line_pos : Array = [Vector2(), Vector2()]
		# top line
		line_pos[0] = Vector2(edge_size, line_dist)
		line_pos[1] = Vector2(card_size.x - edge_size, line_dist)
		draw_line(line_pos[0], line_pos[1], self.border_color, self.border_width, ali)
		# right line
		line_pos[0] = Vector2(card_size.x - line_dist, edge_size)
		line_pos[1] = Vector2(card_size.x - line_dist, card_size.y-edge_size)
		draw_line(line_pos[0], line_pos[1], self.border_color, self.border_width, ali)
		# bottom line
		line_pos[0] = Vector2(edge_size, card_size.y-line_dist)
		line_pos[1] = Vector2(card_size.x - edge_size, card_size.y-line_dist)
		draw_line(line_pos[0], line_pos[1], self.border_color, self.border_width, ali)
		# left line
		line_pos[0] = Vector2(line_dist, edge_size)
		line_pos[1] = Vector2(line_dist, card_size.y-edge_size)
		draw_line(line_pos[0], line_pos[1], self.border_color, self.border_width, ali)
