class_name HintManager
extends Node
## Shows each tutorial card the first time its moment happens, once per session.
## Restarting the run doesn't repeat them.

@export var wave_manager: WaveManager
@export var hint_card: HintCard

# Static, so it survives SceneManager reloading the game scene on restart.
static var _seen: Dictionary = {}


func _ready() -> void:
	add_to_group(&"hint_listeners")
	wave_manager.lull_requested.connect(_on_lull_requested)


func _on_lull_requested(lull: LullDefinition) -> void:
	# Deferred so the threads are laid out behind the card when it appears.
	if _has_boss(lull):
		_show_once.call_deferred(&"boss", "Something is coming",
				"Its thread [b]can't be cut[/b].\nClear the others while you can.")
	elif lull.spin_speed != 0.0 and _seen.has(&"threads"):
		_show_once.call_deferred(&"spin", "Turning Threads",
				"In some levels threads circle the Stronghold.\nWhen a thread is cut an enemy group appears [b]where its thread points.[/b] So like before you want to spread the groups out, but also try to cut when the thread faces your towers.\n\n[b]Double Duty Time![/b]" )
	else:
		_show_once.call_deferred(&"threads", "Signal Threads",
				"Each thread holds enemies in the dark.\n[b]Click[/b] one to release its group now.\nWhen the timer runs out, [b]every uncut thread swarms at once.[/b]")


## Called by WardAura through the "hint_listeners" group.
func on_ward_activated() -> void:
	_show_once.call_deferred(&"cultist", "Cultist",
			"Enemies inside its circle take [b]half damage[/b].\nKill it first.")


func _show_once(id: StringName, title: String, body: String) -> void:
	if _seen.has(id) or MenuManager.is_menu_open():
		return
	_seen[id] = true
	hint_card.show_hint(title, body)


func _has_boss(lull: LullDefinition) -> bool:
	for thread in lull.threads:
		if thread and thread.enemy and thread.enemy.is_boss:
			return true
	return false
