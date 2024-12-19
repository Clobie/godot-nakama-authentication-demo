extends Node

var client = null
var session = null
var socket = null
var bridge = null

var scheme: String = 'http'
var host: String = 'ip_here'
var port: int = 7350
var server_key: String = 'defaultkey'

func _ready():
	client = Nakama.create_client(server_key, host, port, scheme)

func login(email, password):
	var session = await create_session(email, password, false)
	if session.is_exception():
		return session.exception.message
	var socket = await create_socket()
	var bridge = await create_bridge()
	_add_listeners()
	var account = await get_account()
	if account.is_exception():
		return account.exception.message
	return account

func create_account(email, password):
	var session = await create_session(email, password, true)
	if session.is_exception():
		if session.exception.status_code == 401:
			return 'That account already exists.'
		return str(session.exception.message) + " (" + str(session.exception.status_code) + ") "
	var socket = await create_socket()
	var bridge = await create_bridge()
	_add_listeners()
	var account = await get_account()
	if account.is_exception():
		return account.exception.message
	return account

func create_session(email, password, create_account = false, username = ''):
	session = await client.authenticate_email_async(email, password, username, create_account)
	return session

func create_socket():
	socket = Nakama.create_socket_from(client)
	await socket.connect_async(session)
	return socket

func create_bridge():
	bridge = NakamaMultiplayerBridge.new(socket)
	return bridge

func get_account():
	var account = await client.get_account_async(session)
	return account

func update_account_information(displayname, username='', avatar_url='', language='', location='', timezone=''):
	var acc = await get_account()
	await client.update_account_async(
		username or acc.user.username,
		displayname or acc.user.displayname,
		avatar_url or acc.user.avatar_url,
		language or acc.user.lang_tag,
		location or acc.user.location,
		timezone or acc.user.timezone
	)

func create_match() -> String:
	var match_id = await bridge.create_match()
	return match_id

func join_match(match_id):
	bridge.join_match(match_id)

func join_named_match(match_name):
	bridge.join_named_match(match_name)

func _on_socket_connected():
	emit_signal("on_socket_connected")
	print("Socket connected.")

func _on_socket_closed():
	emit_signal("on_socket_closed")
	print("Socket closed.")

func _on_socket_error(err):
	emit_signal("on_socket_error", err)
	printerr("Socket error %s" % err)

func _on_match_join_error(error):
	emit_signal("on_match_join_error", error)
	print("Unable to join match: ", error.message)

func _on_match_joined() -> void:
	emit_signal("on_match_joined")
	print("Joined match with id: ", bridge.match_id)

func _on_peer_connected(peer_id):
	emit_signal("on_peer_connected", peer_id)
	print("Peer joined match: ", peer_id)

func _on_peer_disconnected(peer_id):
	emit_signal("on_peer_disconnected", peer_id)
	print("Peer left match: ", peer_id)

func _add_listeners():
	if bridge:
		if not bridge.match_join_error.is_connected(self._on_match_join_error):
			bridge.match_join_error.connect(self._on_match_join_error)
			print("Connected _on_match_join_error")
		if not bridge.match_joined.is_connected(self._on_match_joined):
			bridge.match_joined.connect(self._on_match_joined)
			print("Connected _on_match_joined")
	multiplayer.set_multiplayer_peer(bridge.multiplayer_peer)
	if not multiplayer.peer_connected.is_connected(self._on_peer_connected):
		multiplayer.peer_connected.connect(self._on_peer_connected)
		print("Connected _on_peer_connected")
	if not multiplayer.peer_disconnected.is_connected(self._on_peer_disconnected):
		multiplayer.peer_disconnected.connect(self._on_peer_disconnected)
		print("Connected _on_peer_disconnected")
	if socket:
		if not socket.connected.is_connected(self._on_socket_connected):
			socket.connected.connect(self._on_socket_connected)
			print("Connected _on_socket_connected")
		if not socket.closed.is_connected(self._on_socket_closed):
			socket.closed.connect(self._on_socket_closed)
			print("Connected _on_socket_closed")
		if not socket.received_error.is_connected(self._on_socket_error):
			socket.received_error.connect(self._on_socket_error)
			print("Connected _on_socket_error")
