## // SPRITE // ##

extends Node2D

## // VARIABLES // ##

@onready var networking = self.get_parent().get_node("Networking")
var error_to_str = {
	"pass_not_correct" = "Incorrect Password.",
	"user_not_found" = "Username not found.",
	"name_taken" = "Someone already has this username!",
}

## // FUNCTIONS // ##

func get_err_str(str):
	
	if str in error_to_str:
		return error_to_str[str]
	else:
		return str

func close_creation():
	$"CreateAccount".visible = false

func create_account():
	var request = {"Name" : $LoginInfo/Username.text, "Password" : $LoginInfo/Password.text}
	var creation = await networking.call("request", "carpet_ball/accounts/register", request)
	
	$"CreateAccount".visible = false
	
	if creation[1] != 200:
		$"LoginInfo/Error".text = get_err_str(creation[3])
		$"LoginInfo/Error".visible = true
		$LoginInfo/Username.editable = true
		$LoginInfo/Password.editable = true
		$LoginInfo/Login.disabled = false
	else:
		get_parent().set_meta("SessionId", creation[3])
		get_parent().call("open_main")

func login_attempt():
	
	$LoginInfo/Username.editable = false
	$LoginInfo/Password.editable = false
	$LoginInfo/Login.disabled = true
	
	var request = {"Name" : $LoginInfo/Username.text, "Password" : $LoginInfo/Password.text}
	var response = await networking.call("request", "carpet_ball/accounts/login", request)
	
	if response[1] == 400:
		print("Ok its joever")
		if response[3] == "user_not_found":
			$"CreateAccount".visible = true
		else:
			$"LoginInfo/Error".text = get_err_str(response[3])
			$"LoginInfo/Error".visible = true
			$LoginInfo/Username.editable = true
			$LoginInfo/Password.editable = true
			$LoginInfo/Login.disabled = false
	else: # Session created
		get_parent().set_meta("SessionId", response[3])
		var id_check = await networking.call("request", "carpet_ball/request", {"request_type" : "account", "type" : "session_to_id", "id_to_check" : response[3]})
		if id_check[1] == 400:
			$"LoginInfo/Error".text = get_err_str(id_check[3])
			$"LoginInfo/Error".visible = true
			$LoginInfo/Username.editable = true
			$LoginInfo/Password.editable = true
			$LoginInfo/Login.disabled = false
			return
		get_parent().set_meta("UserId", id_check[3])
		get_parent().call("open_main")
