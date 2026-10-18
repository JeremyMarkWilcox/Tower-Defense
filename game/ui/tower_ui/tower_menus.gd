class_name TowerMenus
extends Node
## Routes socket clicks: empty sockets open the build panel, built ones the upgrade panel.

@export var stronghold: Stronghold
@export var build_panel: TowerBuildPanel
@export var upgrade_panel: TowerUpgradePanel

var _hidden_panel: TowerPanel  # a panel tucked away while a hint or pause menu is up
var _selected := -1  # socket picked with the controller, -1 = none yet

func _ready() -> void:
	stronghold.socket_clicked.connect(_on_socket_clicked)
	MenuManager.menu_opened.connect(_on_menu_opened)
	MenuManager.menu_closed.connect(_on_menu_closed)


func _on_socket_clicked(socket: TowerSocket) -> void:
	var panel: TowerPanel = build_panel if socket.is_empty() else upgrade_panel
	var other: TowerPanel = upgrade_panel if panel == build_panel else build_panel
	other.close()
	if panel.visible and panel.socket == socket:
		panel.close()  # same socket clicked again: close it
	else:
		panel.open_for(socket)
		

func _on_menu_opened(_menu: BaseMenu) -> void:
	for panel: TowerPanel in [build_panel, upgrade_panel]:
		if panel.visible:
			_hidden_panel = panel
			panel.hide()  # hide only; it keeps its socket so it can come back


func _on_menu_closed(_menu: BaseMenu) -> void:
	if MenuManager.is_menu_open() or _hidden_panel == null:
		return  # still under another menu (e.g. Pause -> Settings), wait for the last one
	var panel := _hidden_panel
	_hidden_panel = null
	if is_instance_valid(panel.socket):
		panel.open_for(panel.socket)  # also refreshes, in case gold changed meanwhile

## Controller / keyboard: jump to the next socket and open its panel.
func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("socket_next") or MenuManager.is_menu_open():
		return
	var sockets := stronghold.sockets
	if sockets.is_empty():
		return
	get_viewport().set_input_as_handled()
	if _selected >= 0 and _selected < sockets.size():
		sockets[_selected]._set_hover(false)
	# Next socket that still exists (they hide when the Stronghold falls).
	for i in sockets.size():
		_selected = (_selected + 1) % sockets.size()
		if sockets[_selected].visible:
			break
	var socket := sockets[_selected]
	if not socket.visible:
		return
	socket._set_hover(true)
	var panel: TowerPanel = build_panel if socket.is_empty() else upgrade_panel
	var other: TowerPanel = upgrade_panel if panel == build_panel else build_panel
	other.close()
	panel.open_for(socket)
	panel.focus_first()
