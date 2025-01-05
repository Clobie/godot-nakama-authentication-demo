extends Panel

@onready var email = $VBoxContainer/Email
@onready var password = $VBoxContainer/Password
@onready var create_account = $VBoxContainer/CreateAccount
@onready var login = $VBoxContainer/Login
@onready var text_edit = $TextEdit
@onready var scrollbar = text_edit.get_v_scroll_bar()
@onready var timer = $Timer


var max_attempts = 5
var attempts = 0
var rate_limited = false

func append_text(text):
	text_edit.text += text + '\n'
	scrollbar.set_deferred("value", scrollbar.max_value)

func log_text(created: bool, _result):
	var account = await Authy.get_account()
	if account.is_exception():
		append_text(account.exception.message)
	else:
		append_text('')
		if created:
			append_text('User created and logged in:')
		else:
			append_text('Logged in:')
		append_text('User ID: ' + account.user.id)
		append_text('Username: ' + account.user.username)
		append_text('Token: ' + Authy.session.token)
		append_text('Token Expired: ' + str(Authy.session.expired))
		append_text('Token Expiration: ' + str(Time.get_datetime_string_from_unix_time(Authy.session.expire_time)))
		
func _on_create_account_button_down():
	attempts += 1
	if attempts >= max_attempts:
		if not rate_limited:
			timer.start()
			rate_limited = true
		var timeleft = timer.time_left
		append_text('Max attempts exceeded.  Try again in ' + str(snapped(timeleft, 0.1)) + ' seconds.')
		return
	var result = await Authy.create_account(email.text, password.text)
	password.text = ''
	if result is String:
		append_text(result)
	else:
		log_text(true, result)
	
func _on_login_button_down():
	attempts += 1
	if attempts >= max_attempts:
		if not rate_limited:
			timer.start()
			rate_limited = true
		var timeleft = timer.time_left
		append_text('Max attempts exceeded.  Try again in ' + str(snapped(timeleft, 0.1)) + ' seconds.')
		return
	var result = await Authy.login(email.text, password.text)
	if result is String:
		append_text(result)
	else:
		log_text(false, result)

func _on_timer_timeout():
	attempts = 0
	rate_limited = false
	append_text('Rate limit lifted.  You may try again.')
