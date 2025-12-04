## Responsible for:
##  * One security question step in the recovery chain
##  * Validating a single answer against a stored hash
##  * Letting caller know whether to move to next step or finish

extends RecoveryStep
class_name QuestionStep

var prompt: String = ""
var _expected_hash: String = ""


func _init(question: String = "", expected_hash: String = "") -> void:
	prompt = question
	_expected_hash = expected_hash


# Handle a single answer for this step.
# Returns:
#  * "fail"    -> answer incorrect, chain stops
#  * "ok_next" -> answer correct, move to next handler
#  * "ok_done" -> answer correct and this is the last handler
func handle_answer(answer: String) -> String:
	var actual_hash := CryptoUtil.hash_answer(answer)
	if actual_hash != _expected_hash:
		return "fail"

	if get_next() != null:
		return "ok_next"

	return "ok_done"
