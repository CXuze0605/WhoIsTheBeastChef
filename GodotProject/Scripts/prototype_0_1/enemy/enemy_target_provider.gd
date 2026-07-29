class_name EnemyTargetProvider
extends RefCounted

# Lightweight 0.6B target scoring shared by the two new enemies. It deliberately
# returns Node2D candidates instead of a strongly typed player so future players
# or weighted objectives can be added without rewriting their action states.


static func choose_target(actor: Node2D, player: PrototypePlayer) -> Node2D:
	var best: Node2D = player if player != null and is_instance_valid(player) and not player.is_defeated else null
	var best_score := 0.0
	for node in actor.get_tree().get_nodes_in_group("shabu_trap"):
		var trap := node as ShabuTrap
		if trap == null or not trap.is_available_for(actor as BasicTasteEnemy):
			continue
		var distance := actor.global_position.distance_to(trap.global_position)
		var score := 10000.0 - distance
		if score > best_score:
			best = trap
			best_score = score
	return best


static func try_claim_if_lure(actor: BasicTasteEnemy, candidate: Node2D) -> ShabuTrap:
	var trap := candidate as ShabuTrap
	if trap != null and trap.try_claim(actor):
		return trap
	return null
