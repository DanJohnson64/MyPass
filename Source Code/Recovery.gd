## Responsible for:
##  * Driving the recovery question flow using Chain of Responsibility
##  * Forcing the user through each QuestionStep in order
##  * Revealing the existing master password on success
##  * Allowing the user to copy the recovered password securely
##  * Providing a Back button to return to the login screen
##  * NOT resetting the master password (this is a recovery flow)

extends Control

@onready var question_label: Label = %QuestionLabel
@onready var answer_edit: LineEdit = %AnswerEdit
@onready var next_button: Button = %NextButton

@onready var password_reveal_panel: Control = %PasswordRevealPanel
@onready var revealed_password_value: LineEdit = %RevealedPasswordValue
@onready var copy_button: Button = %CopyButton

@onready var info_label: Label = %InfoLabel
@onready var back_button: Button = %BackButton

var _chain: RecoveryStep = null
var _current_step: RecoveryStep = null
var _stage: String = "questions"

# Wire up buttons, hide reveal panel, and build recovery chain
func _ready() -> void:
	next_button.pressed.connect(_on_next_pressed)
	copy_button.pressed.connect(_on_copy_pressed)
	back_button.pressed.connect(_on_back_pressed)

	# Start with the reveal panel hidden
	password_reveal_panel.visible = false

	_build_chain()


## -------------------------- CoR Setup --------------------------------------

# Build the recovery chain and initialize the first step
func _build_chain() -> void:
	_chain = SessionManager.build_recovery_chain()
	_current_step = _chain

	if _current_step == null:
		question_label.text = "No recovery data configured for this account."
		answer_edit.editable = false
		next_button.disabled = true
		if info_label:
			info_label.text = "Set up recovery questions when creating your account."
		return

	_show_current_question()

# Update UI to display the current question in the chain
func _show_current_question() -> void:
	if _current_step == null:
		return

	if _current_step is QuestionStep:
		var qs := _current_step as QuestionStep
		question_label.text = qs.prompt
	else:
		question_label.text = "Recovery step."

	answer_edit.text = ""


## ------------------------- Question Handling --------------------------------

# Handle Next button press and advance/complete the chain
func _on_next_pressed() -> void:
	if _stage != "questions":
		return

	if _current_step == null:
		return

	var answer := answer_edit.text

	if _current_step is QuestionStep:
		var qs := _current_step as QuestionStep
		var result := qs.handle_answer(answer)

		match result:
			"fail":
				UIHub.notify_warning("Incorrect answer. Try again.")
			"ok_next":
				_current_step = _current_step.get_next()
				_show_current_question()
			"ok_done":
				_on_all_questions_passed()
	else:
		_on_all_questions_passed()


## ------------------------- Final CoR Action ---------------------------------

# Run when all questions pass and reveal the stored master password
func _on_all_questions_passed() -> void:
	_stage = "done"

	# Disable question UI
	answer_edit.editable = false
	next_button.disabled = true

	# Load recovered password
	var account := CryptoUtil.load_accout()
	if account.is_empty():
		UIHub.notify_error("Could not load account record.")
		return

	var recovered: String = str(account.get("master_password_plain", ""))

	if recovered.is_empty():
		UIHub.notify_error("Master password not available for recovery.")
		return

	# Switch UI to reveal panel
	password_reveal_panel.visible = true
	question_label.text = "Your master password is:"
	revealed_password_value.text = recovered

	if info_label:
		info_label.text = "You may now copy your master password and return to Login."

	UIHub.notify_info("Master password recovered successfully.")


## ---------------------------- Copy Button -----------------------------------


# Copy recovered master password using Clipboard_Guard
func _on_copy_pressed() -> void:
	var pwd := revealed_password_value.text
	if pwd.is_empty():
		UIHub.notify_warning("Nothing to copy.")
		return

	# ClipboardGuard is responsible for safe copying
	ClipboardGuard.copy_secret(pwd)

	UIHub.notify_info("Master password copied to clipboard.")


## ---------------------------- Back Button -----------------------------------

# Return user back to the Auth/login screen
func _on_back_pressed() -> void:
	UIHub.goto_auth()
