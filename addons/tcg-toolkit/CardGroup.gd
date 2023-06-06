@tool
class_name CardGroup
extends Control


var can_manipulate_tree = false

@export_flags("horizontal", "vertical") var overlapping = 0b00:
	set(value):
		overlapping = value
		self._update_card_distribution()
@export var spacing = Vector2(10, 10):
	set(value):
		spacing = value
		self._update_card_distribution()
@export var card_amount = 0:
	set(value):
		card_amount = value
		if value == 0:
			self.cards_scale = 1
		if self.can_manipulate_tree:
			self._sync_nodes()
			var need_update = self.card_amount != self.get_child_count()
			while self.card_amount > self.get_child_count():
				self.insert_card(Card.new(), -1, false)
			while self.card_amount < self.get_child_count():
				self.remove_child(self.get_child(-1))
			if need_update:
				_update_card_distribution()
@export var row_limit = 0:
	set(value):
		row_limit = value if value >= 0 else 0
		self._update_card_distribution()

@export var background_color = Color("#ffffff00"):
	set(value):
		background_color = value
		self._update_cards()

@export_range(0.001, 5) var cards_scale : float = 1.0:
	set(value):
		cards_scale = value
		self.scale.x = value
		self.scale.y = value
		for card in self.get_children():
			if snapped(card.size_scale, 0.001) != snapped(value, 0.001):
				card.size_scale = value


func _enter_tree():
	self.can_manipulate_tree = true
	self._sync_nodes()
	self._update_card_distribution()

func _process(delta):
	if self.card_amount != self.get_child_count():
		self._update_cards()
	self._sync_nodes()

func _draw():
	#draw background rect
	self.draw_rect(Rect2(0, 0, self.size.x, self.size.y), self.background_color)



func insert_card(new_card: Card = Card.new(), index: int = -1, _update_at_end: bool = true):
	self.add_child(new_card)
	if index != -1:
		self.move_child(new_card, index)
	new_card.set_owner(get_tree().get_edited_scene_root())
	new_card.set_name("Card")
	if _update_at_end:
		self._update_cards()

func remove_card(card: Card):
	self.remove_child(card)
	self._update_cards()

func remove_card_in(index: int):
	self.remove_child(self.get_child(index))
	self._update_cards()

func _update_cards():
	var child_nodes = self.get_children()
	
	# iterate children to prevent non Cards
	for node in child_nodes:
		if not is_instance_of(node, Card):
			self.remove_child(node)
			push_warning("You can only assign nodes of type \"Card\" inside an CardGroup.")
	
	# update private amount checker and call update for distribution
	self.card_amount = self.get_child_count()
	self._update_card_distribution()

func _update_card_distribution():
	self.size.x = 0
	if self.get_child_count() > 0:
		var cards = self.get_children()
		var base_size = cards[0].size
		if base_size == Vector2.ZERO:
			base_size = load(Card.TEMPLATE_TEXTURE).get_size()
		var card_spacing = Vector2(self.spacing.x + base_size.x, self.spacing.y + base_size.y)
		match self.overlapping:
			0b01:
				card_spacing.x = self.spacing.x
			0b10:
				card_spacing.y = self.spacing.y
			0b11:
				card_spacing.x = self.spacing.x
				card_spacing.y = self.spacing.y
		
		# update self size based on card distribution
		if self.row_limit > 0:
			var col_size = floor((self.card_amount - 1)/self.row_limit)
			self.size.y = (card_spacing.y * col_size) + base_size.y
			self.size.x = (card_spacing.x * (self.row_limit - 1)) + base_size.x
		else:
			self.size.y = base_size.y
			self.size.x = (card_spacing.x * (self.card_amount - 1)) + base_size.x
		
		# update each card position
		var card_index = 0
		for card in cards:
			#card.size = base_size
			if self.row_limit == 0:
				card.position.x = card_spacing.x * card_index
				card.position.y = 0
			else:
				var new_pos = Vector2()
				new_pos.x = card_index % self.row_limit
				new_pos.y = int(card_index / self.row_limit)
				card.position.x = card_spacing.x * new_pos.x
				card.position.y = card_spacing.y * new_pos.y
			
			card_index += 1

func _sync_nodes():
	for node in self.get_children():
		if node.get_owner() != get_tree().get_edited_scene_root():
			node.set_owner(get_tree().get_edited_scene_root())
			node.set_name("Card")
