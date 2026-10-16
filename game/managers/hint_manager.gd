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
				"\n\tIts thread [b]can't be cut[/b].\n\n\tClear the others while you can.")
	elif lull.spin_speed != 0.0 and _seen.has(&"threads"):
		_show_once.call_deferred(&"spin", "Turning Threads",
				"\n\tSometimes threads will circle the Stronghold.\n\n\tWhen a thread is cut an enemy group appears [b]where its thread points.\n\n\t[/b] Like beforehand, you want to spread the groups out, while also trying to face your towers.\n\n\n\t[b]Double Duty Time![/b]" )
	else:
		_show_once.call_deferred(&"threads", "Signal Threads",
				"\n\tEach thread holds enemies in the dark.\n\n\t[b]Click[/b] one to release its group now.\n\n\tWhen the timer runs out, [b]every uncut thread swarms at once.[/b]\n\n\t[i]There is a 1 second cooldown between each thread cut.[/i]")


## Called by WardAura through the "hint_listeners" group.
func on_ward_activated() -> void:
	_show_once.call_deferred(&"cultist", "Cultist",
			"\n\tEnemies inside its circle take [b]half damage[/b].\n\n\tKill it first, if possible.")


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
