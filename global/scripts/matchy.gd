extends Node

var peers: Dictionary = {}
var current_scene: String = ''
var spawned_players: Array = []

func _ready():
	Authy.on_peer_connected.connect(_on_peer_connected)
	Authy.on_peer_disconnected.connect(_on_peer_disconnected)

# -------------------------------------------------
# RPCs
# -------------------------------------------------
@rpc("any_peer", "call_local", "reliable")
func _replicate_player_info(p: String):
	peers.merge(JSON.parse_string(p))

@rpc("authority", "call_remote", "reliable")
func change_scene(scene):
	Matchy.current_scene = scene
	Sceney.change_to_scene(scene)

@rpc("authority", "call_local", "reliable")
func spawn_player(root_node: Node, peer_id: int, spawn_position: Vector2, display_name: String, scene_preload: PackedScene):
	if peer_id not in spawned_players:
		Loggy.info(self, "Spawning player: " + str(peer_id))
		var scene = scene_preload.instantiate()
		scene.name = str(peer_id)
		scene.set_multiplayer_authority(peer_id)
		scene.global_position = spawn_position
		scene.display_name = display_name
		root_node.add_child(scene)
		spawned_players.append(peer_id)

# -------------------------------------------------
# Other
# -------------------------------------------------
func new_players_detected():
	return spawned_players.size() < peers.size()

func add_peer(_peer_id: int):
	if !multiplayer.get_unique_id() in peers:
		var account = await Authy.get_account()
		peers[str(multiplayer.get_unique_id())] = {
			"user_id": Authy.get_user_id(),
			"username": account.user.username,
			"display_name": account.user.display_name,
			"avatar_url": account.user.avatar_url
		}
	_replicate_player_info.rpc(JSON.stringify(peers))
	
# -------------------------------------------------
# Callbacks
# -------------------------------------------------
func _on_peer_connected(peer_id: int):
	Loggy.debug(self, "Peer size: " + str(peers.size()))
	Loggy.debug(self, "Spawned size: " + str(spawned_players.size()))
	add_peer(peer_id)
	if multiplayer.get_unique_id() == 1:
		change_scene.rpc(current_scene)

func _on_peer_disconnected(peer_id: int):
	peers.erase(peer_id)
	spawned_players.erase(peer_id)

func set_current_scene(scene_path):
	current_scene = scene_path

# -------------------------------------------------
# Player information
# -------------------------------------------------
func get_peer_user_id(peer_id):
	return peers[str(peer_id)]["user_id"]

func get_peer_username(peer_id):
	return peers[str(peer_id)]["username"]

func get_peer_display_name(peer_id):
	return peers[str(peer_id)]["display_name"]

func get_peer_avatar_url(peer_id):
	return peers[str(peer_id)]["avatar_url"]
