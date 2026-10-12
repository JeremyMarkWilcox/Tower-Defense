class_name HintCard
extends BaseMenu
## A short tutorial card. MenuManager pauses the game while it's open; Got it or Esc closes it.

@export var title_label: Label
@export var body_label: RichTextLabel
@export var got_it_button: Button


func _ready() -> void:
	super()
	got_it_button.pressed.connect(MenuManager.close_menu)


func show_hint(title: String, body: String) -> void:
	title_label.text = title
	body_label.text = body
	MenuManager.open_menu(self)
