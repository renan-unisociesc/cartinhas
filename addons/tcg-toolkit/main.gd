@tool
extends EditorPlugin


func _enter_tree():
	# Initialization
	add_custom_type("Card", "TextureRect", preload("Card.gd"), preload("texture/cardicon.png"))
	add_custom_type("CardGroup", "Control", preload("CardGroup.gd"), preload("texture/cardgroupicon.png"))

func _exit_tree():
	# Clean-up
	remove_custom_type("Card")
	remove_custom_type("CardGroup")
