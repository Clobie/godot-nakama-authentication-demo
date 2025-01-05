extends Node

var scheme: String = 'http'
var host: String = 'ip_here'
var port: int = 7350
var server_key: String = 'defaultkey'

var client: NakamaClient = null
var session: NakamaSession = null
var socket: NakamaSocket = null
var bridge: NakamaMultiplayerBridge = null

var authenticated = false
var in_match = false

signal on_socket_closed()
signal on_socket_connected()
signal on_socket_connection_error(err)
signal on_received_channel_message(channel_message)
signal on_received_channel_presence(channel_presence)
signal on_received_error(err)
signal on_received_matchmaker_matched(matchmaker_matched)
signal on_received_match_state(match_state)
signal on_received_match_presence(match_presence_event)
signal on_received_notification(api_notification)
signal on_received_status_presence(status_presence_event)
signal on_received_stream_presence(stream_presence_event)
signal on_received_stream_state(stream_state)
signal on_received_party(party)
signal on_received_party_close(party_close)
signal on_received_party_data(party_data)
signal on_received_party_join_request(party_join_request)
signal on_received_party_leader(party_leader)
signal on_received_party_matchmaker_ticket(party_matchmaker_ticket)
signal on_received_party_presence(party_presence_event)
signal on_match_join_error(error)
signal on_match_joined()
signal on_peer_connected(peer_id)
signal on_peer_disconnected(peer_id)

func _ready():
	pass

# -------------------------------------------------
# Authentication
# -------------------------------------------------
func logout():
	Loggy.info(self, "Logging out")
	authenticated = false
	if session:
		var result = await client.session_logout_async(session)
		Loggy.debug(self, "Successfully logged out\nResult: " + str(result))
	else:
		Loggy.error(self, "No active session found to log out")

func login(email, password):
	client = create_client()
	if !client:
		return false
	session = await create_session(email, password, false)
	if session.is_exception():
		return session.exception.message
	socket = await create_socket()
	if !socket:
		return false
	bridge = await create_bridge()
	if !bridge:
		return false
	var account = await get_account()
	if account.is_exception():
		return account.exception.message
	Loggy.info(self, "Login success")
	authenticated = true
	return account

func create_account(email, password):
	client = create_client()
	if !client:
		return false
	session = await create_session(email, password, true)
	if session.is_exception():
		if session.exception.status_code == 401:
			return 'That account already exists.'
		return str(session.exception.message) + " (" + str(session.exception.status_code) + ") "
	socket = await create_socket()
	if !socket:
		return false
	bridge = await create_bridge()
	if !bridge:
		return false
	var account = await get_account()
	if account.is_exception():
		return account.exception.message
	Loggy.info(self, "Create account success")
	authenticated = true
	return account

# -------------------------------------------------
# Client
# -------------------------------------------------
func create_client():
	Loggy.info(self, "Creating Nakama client")
	client = Nakama.create_client(server_key, host, port, scheme)
	if client:
		Loggy.info(self, "Client created successfully")
		return client
	Loggy.error(self, "Failed to create Nakama client")
	return false

# -------------------------------------------------
# Connections
# -------------------------------------------------
func create_session(email, password, create = false, username = ''):
	Loggy.info(self, "Creating session")
	session = await client.authenticate_email_async(email, password, username, create)
	if session:
		Loggy.info(self, "Session created\n" + str(session))
		return session
	Loggy.error(self, "Failed to create session")
	return null

func create_socket():
	Loggy.info(self, "Creating socket")
	socket = Nakama.create_socket_from(client)
	await socket.connect_async(session)
	if socket:
		Loggy.info(self, "Socket created: " + str(socket))
		if not socket.closed.is_connected(self._on_socket_closed):
			socket.closed.connect(self._on_socket_closed)
		if not socket.connected.is_connected(self._on_socket_connected):
			socket.connected.connect(self._on_socket_connected)
		if not socket.connection_error.is_connected(self._on_socket_connection_error):
			socket.connection_error.connect(self._on_socket_connection_error)
		if not socket.received_channel_message.is_connected(self._on_received_channel_message):
			socket.received_channel_message.connect(self._on_received_channel_message)
		if not socket.received_channel_presence.is_connected(self._on_received_channel_presence):
			socket.received_channel_presence.connect(self._on_received_channel_presence)
		if not socket.received_error.is_connected(self._on_received_error):
			socket.received_error.connect(self._on_received_error)
		if not socket.received_matchmaker_matched.is_connected(self._on_received_matchmaker_matched):
			socket.received_matchmaker_matched.connect(self._on_received_matchmaker_matched)
		if not socket.received_match_state.is_connected(self._on_received_match_state):
			socket.received_match_state.connect(self._on_received_match_state)
		if not socket.received_match_presence.is_connected(self._on_received_match_presence):
			socket.received_match_presence.connect(self._on_received_match_presence)
		if not socket.received_notification.is_connected(self._on_received_notification):
			socket.received_notification.connect(self._on_received_notification)
		if not socket.received_status_presence.is_connected(self._on_received_status_presence):
			socket.received_status_presence.connect(self._on_received_status_presence)
		if not socket.received_stream_presence.is_connected(self._on_received_stream_presence):
			socket.received_stream_presence.connect(self._on_received_stream_presence)
		if not socket.received_stream_state.is_connected(self._on_received_stream_state):
			socket.received_stream_state.connect(self._on_received_stream_state)
		if not socket.received_party.is_connected(self._on_received_party):
			socket.received_party.connect(self._on_received_party)
		if not socket.received_party_close.is_connected(self._on_received_party_close):
			socket.received_party_close.connect(self._on_received_party_close)
		if not socket.received_party_data.is_connected(self._on_received_party_data):
			socket.received_party_data.connect(self._on_received_party_data)
		if not socket.received_party_join_request.is_connected(self._on_received_party_join_request):
			socket.received_party_join_request.connect(self._on_received_party_join_request)
		if not socket.received_party_leader.is_connected(self._on_received_party_leader):
			socket.received_party_leader.connect(self._on_received_party_leader)
		if not socket.received_party_matchmaker_ticket.is_connected(self._on_received_party_matchmaker_ticket):
			socket.received_party_matchmaker_ticket.connect(self._on_received_party_matchmaker_ticket)
		if not socket.received_party_presence.is_connected(self._on_received_party_presence):
			socket.received_party_presence.connect(self._on_received_party_presence)
		return socket
	Loggy.error(self, "Failed to create socket")
	return null

func create_bridge():
	Loggy.info(self, "Creating bridge")
	bridge = NakamaMultiplayerBridge.new(socket)
	if bridge:
		Loggy.info(self, "Bridge created: " + str(bridge))
		if not bridge.match_join_error.is_connected(self._on_match_join_error):
			bridge.match_join_error.connect(self._on_match_join_error)
		if not bridge.match_joined.is_connected(self._on_match_joined):
			bridge.match_joined.connect(self._on_match_joined)
		multiplayer.set_multiplayer_peer(bridge.multiplayer_peer)
		if not multiplayer.peer_connected.is_connected(self._on_peer_connected):
			multiplayer.peer_connected.connect(self._on_peer_connected)
		if not multiplayer.peer_disconnected.is_connected(self._on_peer_disconnected):
			multiplayer.peer_disconnected.connect(self._on_peer_disconnected)
		return bridge
	Loggy.error(self, "Failed to create bridge")
	return null

func get_account():
	Loggy.info(self, "Retrieving account")
	var account = await client.get_account_async(session)
	if account:
		Loggy.info(self, "Account retrieved\n" + str(account))
		return account
	Loggy.error(self, "Failed to retrieve account")
	return null

# -------------------------------------------------
# Update user account
# -------------------------------------------------
func update_account_information(displayname, username, avatar_url, language, location, timezone):
	Loggy.info(self, "Updating account")
	var result = await client.update_account_async(
		session,
		username,
		displayname,
		avatar_url,
		language,
		location,
		timezone
	)
	if result.is_exception():
		Loggy.error(self, "Failed to update account. Status: " + str(result.exception.message) + " Code: " + str(result.exception.status_code))
	Loggy.info(self, "Account updated\n" + str(result))
	return result

func update_username(username):
	var result = await client.update_account_async(session, username)
	return result

func update_display_name(display_name):
	var result = await client.update_account_async(session, null, display_name)
	return result

func update_avatar_url(url):
	var result = await client.update_account_async(session, null, null, url)
	return result

func update_language(language):
	var result = await client.update_account_async(session, null, null, null, language)
	return result

func update_location(loc):
	var result = await client.update_account_async(session, null, null, null, null, loc)
	return result

func update_timezone(tz):
	var result = await client.update_account_async(session, null, null, null, null, null, tz)
	return result

# -------------------------------------------------
# Create, join and leave matches
# -------------------------------------------------
func create_match():
	Loggy.info(self, "Creating match with random id")
	await bridge.create_match()
	var match_id = bridge.match_id
	if match_id:
		Loggy.info(self, "Match created. ID: " + str(match_id))
		in_match = true
		return match_id
	Loggy.info(self, "Failed to create match")
	in_match = false
	return false
		

func create_named_match(match_name: String):
	Loggy.info(self, "Creating match with name: " + match_name)
	await bridge.join_named_match(match_name)
	var match_id = bridge.match_id
	if match_id:
		Loggy.info(self, "Match created. ID: " + str(match_id))
		in_match = true
		return match_id
	Loggy.info(self, "Failed to create match")
	in_match = false
	return false

func join_match(match_id: String):
	Loggy.info(self, "Joining match with ID: " + str(match_id))
	await bridge.join_match(match_id)
	var joined_match_id = bridge.match_id
	if joined_match_id:
		Loggy.info(self, "Match joined. ID: " + str(joined_match_id))
		in_match = true
		return joined_match_id
	Loggy.info(self, "Failed to join match")
	in_match = false
	return false

func join_named_match(match_name: String):
	Loggy.info(self, "Joining match with name: " + match_name)
	await bridge.join_named_match(match_name)
	var joined_match_id = bridge.match_id
	if joined_match_id:
		Loggy.info(self, "Match created. ID: " + str(joined_match_id))
		in_match = true
		return joined_match_id
	Loggy.info(self, "Failed to join match")
	in_match = false
	return false
	
func leave_match():
	var match_id = bridge.match_id
	in_match = false
	await bridge.leave()
	Loggy.info(self, "You have left the match: '" + str(match_id) + "'")

# -------------------------------------------------
# Authority TBA
# -------------------------------------------------

# -------------------------------------------------
# Data storage
# -------------------------------------------------
func store_personal_data_read_write(collection, key, dict: Dictionary):
	Loggy.info(self, "Storing data\nCollection: " + str(collection) + "\nKey: " + str(key) + "\nDictionary: " + str(dict))
	var data = JSON.stringify(dict)
	var result : NakamaAPI.ApiStorageObjectAcks = await client.write_storage_objects_async(
		session, [NakamaWriteStorageObject.new(collection, key, 1, 1, data, "")]
	)
	if result.is_exception():
		Loggy.error(self, "Failed to store data. Status: " + str(result.exception.message) + " Code: " + str(result.exception.code))
		return false
	return result

func store_public_data_read_write(collection, key, dict: Dictionary):
	Loggy.info(self, "Storing data\nCollection: " + str(collection) + "\nKey: " + str(key) + "\nDictionary: " + str(dict))
	var data = JSON.stringify(dict)
	var result : NakamaAPI.ApiStorageObjectAcks = await client.write_storage_objects_async(
		session, [NakamaWriteStorageObject.new(collection, key, 2, 1, data, "")]
	)
	if result.is_exception():
		Loggy.error(self, "Failed to store data. Status: " + str(result.exception.message) + " Code: " + str(result.exception.code))
		return false
	return result

func read_storage_data(collection, key):
	Loggy.info(self, "Reading storage data\nCollection: " + str(collection) + "\nKey: " + str(key))
	var result = await client.read_storage_objects_async(session,[NakamaStorageObjectId.new(collection, key, session.user_id)])
	if result.is_exception():
		Loggy.error(self, str(result))
		return
	if result.is_exception():
		Loggy.error(self, "Failed to storage data. Status: " + str(result.exception.message) + " Code: " + str(result.exception.code))
		return false
	Loggy.info(self, "Retrieved storage data\n" + str(result))
	return result

func list_storage_data(collection):
	Loggy.info(self, "Listing storage data\nCollection: " + str(collection))
	var result = await client.list_storage_objects_async(
		session,
		collection,
		session.user_id
	)
	if result.is_exception():
		Loggy.error(self, "Failed to list storage data. Status: " + str(result.exception.message) + " Code: " + str(result.exception.code))
	Loggy.info(self, "Retrieved storage data list\n" + str(result))
	return result

# -------------------------------------------------
# Get stuff
# -------------------------------------------------
func get_user_id():
	return session.user_id

# -------------------------------------------------
# Callbacks
# -------------------------------------------------
func _on_socket_closed():
	on_socket_closed.emit()
	Loggy.info(self, "Socket closed.")

func _on_socket_connected():
	on_socket_connected.emit()
	Loggy.info(self, "Socket connected.")

func _on_socket_connection_error(err):
	on_socket_connection_error.emit(err)
	Loggy.error(self, "Socket connection error %s" % err)

func _on_received_channel_message(channel_message):
	on_received_channel_message.emit(channel_message)
	Loggy.debug(self, "Received channel message: " + str(channel_message))

func _on_received_channel_presence(channel_presence):
	on_received_channel_presence.emit(channel_presence)
	Loggy.debug(self, "Received channel presence: " + str(channel_presence))

func _on_received_error(err):
	on_received_error.emit(err)
	Loggy.error(self, "Received error: " + str(err))

func _on_received_matchmaker_matched(matchmaker_matched):
	on_received_matchmaker_matched.emit(matchmaker_matched)
	Loggy.debug(self, "Received matchmaker matched: " + str(matchmaker_matched))

func _on_received_match_state(match_state):
	on_received_match_state.emit(match_state)
	#Loggy.debug(self, "Received match state: " + str(match_state))

func _on_received_match_presence(match_presence_event):
	on_received_match_presence.emit(match_presence_event)
	Loggy.debug(self, "Received match presence event: " + str(match_presence_event))

func _on_received_notification(api_notification):
	on_received_notification.emit(api_notification)
	Loggy.debug(self, "Received notification: " + str(api_notification))

func _on_received_status_presence(status_presence_event):
	on_received_status_presence.emit(status_presence_event)
	Loggy.debug(self, "Received status presence event: " + str(status_presence_event))

func _on_received_stream_presence(stream_presence_event):
	on_received_stream_presence.emit(stream_presence_event)
	Loggy.debug(self, "Received stream presence event: " + str(stream_presence_event))

func _on_received_stream_state(stream_state):
	on_received_stream_state.emit(stream_state)
	Loggy.debug(self, "Received stream state: " + str(stream_state))

func _on_received_party(party):
	on_received_party.emit(party)
	Loggy.debug(self, "Received party: " + str(party))

func _on_received_party_close(party_close):
	on_received_party_close.emit(party_close)
	Loggy.debug(self, "Received party close: " + str(party_close))

func _on_received_party_data(party_data):
	on_received_party_data.emit(party_data)
	Loggy.debug(self, "Received party data: " + str(party_data))

func _on_received_party_join_request(party_join_request):
	on_received_party_join_request.emit(party_join_request)
	Loggy.debug(self, "Received party join request: " + str(party_join_request))

func _on_received_party_leader(party_leader):
	on_received_party_leader.emit(party_leader)
	Loggy.debug(self, "Received party leader: " + str(party_leader))

func _on_received_party_matchmaker_ticket(party_matchmaker_ticket):
	on_received_party_matchmaker_ticket.emit(party_matchmaker_ticket)
	Loggy.debug(self, "Received party matchmaker ticket: " + str(party_matchmaker_ticket))

func _on_received_party_presence(party_presence_event):
	on_received_party_presence.emit(party_presence_event)
	Loggy.debug(self, "Received party presence event: " + str(party_presence_event))

func _on_match_join_error(error):
	on_match_join_error.emit(error)
	Loggy.error(self, "Match join error: " + str(error))

func _on_match_joined():
	on_match_joined.emit()
	Loggy.info(self, "Successfully joined match.")

func _on_peer_connected(peer_id):
	on_peer_connected.emit(peer_id)
	Loggy.debug(self, "Peer connected: " + str(peer_id))

func _on_peer_disconnected(peer_id):
	on_peer_disconnected.emit(peer_id)
	Loggy.debug(self, "Peer disconnected: " + str(peer_id))
