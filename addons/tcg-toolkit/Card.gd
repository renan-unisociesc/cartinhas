@tool
class_name Card
extends TextureRect


const TEMPLATE_TEXTURE = "res://addons/tcg-toolkit/texture/card_example.png"
const CARD_MODEL_RES = "res://assets/cardmodel/"
enum BorderPositions {Internal, Center, External}
enum TierBackground {Common, Uncommon, Rare, VeryRare}

@export_placeholder("Creature Name") var title = ""
@export var tier : TierBackground = 0:
	set(value):
		tier = value
		queue_redraw()
@export_range(0.001, 5) var size_scale : float = 1.0:
	set(value):
		size_scale = value
		var parent_node = get_parent()
		if parent_node and is_instance_of(parent_node, CardGroup):
			if snapped(parent_node.cards_scale, 0.001) != snapped(value, 0.001):
				parent_node.cards_scale = value

@export_group("Card Model Layers", "layer_")
@export_global_file("*.png") var layer_background = Card.CARD_MODEL_RES + "card_color_bg.png"
var layer_background_texture : Texture
@export_global_file("*.png") var layer_creature = ""
var layer_creature_texture : Texture
@export_global_file("*.png") var layer_border = Card.CARD_MODEL_RES + "card_border.png"
var layer_border_texture : Texture
@export_global_file("*.png") var layer_extra = ""
var layer_extra_texture : Texture
# icons
# bonuses # lateral bars with effects to side cards
@export_subgroup("Tier Colors", "tier_")
@export var tier_common : Color = Color("#ffffff"):
	set(value):
		tier_common = value
		queue_redraw()
@export var tier_uncommon : Color = Color("#deff00"):
	set(value):
		tier_uncommon = value
		queue_redraw()
@export var tier_rare : Color = Color("#0096ff"):
	set(value):
		tier_rare = value
		queue_redraw()
@export var tier_veryrare : Color = Color("#a525ff"):
	set(value):
		tier_veryrare = value
		queue_redraw()

@export_group("Draw Properties", "draw_")
@export_subgroup("size", "size_")
@export var draw_size : Vector2:
	set(value):
		draw_size = value
		self.size = value
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
	self.texture = load(self.layer_background)
	self.draw_size = self.texture.get_size()
	
	self._load_card_models()
	
	# presets to sync Control sizes to self.draw_size
	#self.layout_mode = 1
	#self.anchors_preset = -1
	#self.anchor_right = 1
	#self.anchor_bottom = 1
	#self.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	#self.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

func _draw():
	self._draw_card_model()
	if self.border_active:
		self._draw_border()

func _process(delta):
	#self._update_offset_size()
	pass



func _update_offset_size():
	if self.offset_left != 0:
		self.draw_size.x -= self.offset_left
		self.offset_left = 0
	if self.offset_right != 0:
		self.draw_size.x += self.offset_right
		self.offset_right = 0
	if self.offset_top != 0:
		self.draw_size.y -= self.offset_top
		self.offset_top = 0
	if self.offset_bottom != 0:
		self.draw_size.y += self.offset_bottom
		self.offset_bottom = 0

func _load_card_models():
	if !self.layer_background.is_empty():
		self.layer_background_texture = load(self.layer_background)
	if !self.layer_creature.is_empty():
		self.layer_creature_texture = load(self.layer_creature)
	if !self.layer_border.is_empty():
		self.layer_border_texture = load(self.layer_border)
	if !self.layer_extra.is_empty():
		self.layer_extra_texture = load(self.layer_extra)

func _draw_card_model():
	if !self.layer_background.is_empty():
		var color_filter = self.tier_common
		match self.tier:
			TierBackground.Uncommon:
				color_filter = self.tier_uncommon
			TierBackground.Rare:
				color_filter = self.tier_rare
			TierBackground.VeryRare:
				color_filter = self.tier_veryrare
		draw_texture(self.layer_background_texture, Vector2(), color_filter)
	if !self.layer_creature.is_empty():
		draw_texture(self.layer_creature_texture, Vector2())
	if !self.layer_border.is_empty():
		draw_texture(self.layer_border_texture, Vector2())
	if !self.layer_extra.is_empty():
		draw_texture(self.layer_extra_texture, Vector2())

func _draw_border():
	var width = self.border_width
	var card_size = self.draw_size
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
