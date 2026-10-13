class_name TowerMenus
extends Node
## Routes socket clicks: empty sockets open the build panel, built ones the upgrade panel.

@export var stronghold: Stronghold
@export var build_panel: TowerBuildPanel
@export var upgrade_panel: TowerUpgradePanel

var _hidden_panel: TowerPanel  # a panel tucked away while a hint or pause menu is up


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
