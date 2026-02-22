## // SPRITES // ##

extends Node2D

## // VARIABLES // ##

@onready var networking = self.get_parent().get_node("Networking")
@onready var master = self.get_parent()

@onready var session_id = str(master.get_meta("SessionId"))
@onready var user_id = str(master.get_meta("UserId"))

var rank_to_color = [Color("e3e300"), Color(0.537, 0.537, 0.537, 1.0), Color(0.595, 0.305, 0.0, 1.0)]

var error_to_str = {
	"pass_not_correct" = "Incorrect Password.",
	"user_not_found" = "Username not found.",
	"name_taken" = "Someone already has this username!",
	"game_already" = "A game is already active!",
	"plrs_not_valid" = "Someones name is incorrect."
}

var picked_winner = 0


## // FUNCTIONS // ##

func get_err_str(str):
	
	if str in error_to_str:
		return error_to_str[str]
	else:
		return str

# CREATE GAME

func cancel_game():
	await networking.call("request", "carpet_ball/request", 
		{"request_type" : "game_submit", "forced" : "true"}
	)

func submit_game():
	var loser_number = 0
	if picked_winner == 1:
		loser_number = 0
	else:
		loser_number = 1
	await networking.call("request", "carpet_ball/request", 
		{
			"request_type" : "game_submit", 
			"forced" : "false",
			"Winner" : str(picked_winner),
			"Loser" : str(loser_number),
			
			"Player1Remaining" : str(int($"RefVisual/RemainingPlayer1".value)),
			"Player2Remaining" : str(int($"RefVisual/RemainingPlayer2".value)),
			
			"Player1Fumbles" : str(int($"RefVisual/FumblesPlayer1".value)),
			"Player2Fumbles" : str(int($"RefVisual/FumblesPlayer2".value)),
			
			"Player1Combos" : str(int($"RefVisual/CombosPlayer1".value)),
			"Player2Combos" : str(int($"RefVisual/CombosPlayer2".value)),
		}
	)

func toggle_menu(open):
	$"CreateGame".visible = open

func create_game():
	
	var plr_1 = $"CreateGame/LoginInfo/Player1".text
	var plr_2 = $"CreateGame/LoginInfo/Player2".text
	
	var host = await networking.call("request", "carpet_ball/request", 
		{"request_type" : "game_host", "Player1" : plr_1, "Player2" : plr_2, "Ref" : user_id}
	)
	
	if host[1] != 200:
		$"CreateGame/LoginInfo/Error".visible = true
		$"CreateGame/LoginInfo/Error".text = get_err_str(host[3])
	else:
		$"CreateGame/LoginInfo/Error".visible = false
		$"CreateGame".visible = false
	


# MAIN

func reset_ranks():
	for asset : Node in $"Scroll/Container/PanelContainer/Container".get_children():
		if asset.name != "Template":
			asset.queue_free()
			
func handle_ref_update(info):
	$"RefVisual".visible = true
	
	$"RefVisual/Title".text = info["Name"]
	$"RefVisual/Player1Winner".text = info["Player1"]
	$"RefVisual/Player2Winner".text = info["Player2"]
	
func plr_1_picked_winner():
	$"RefVisual/Player1Selected".visible = true
	$"RefVisual/Player2Selected".visible = false
	$"RefVisual/Player1Selected".visible = true
	$"RefVisual/Player2Selected".visible = false
	picked_winner = 0
	
	$"RefVisual/RemainingPlayer1".editable = true
	$"RefVisual/RemainingPlayer2".editable = false
	$"RefVisual/RemainingPlayer2".value = 0.0
	
func plr_2_picked_winner():
	$"RefVisual/Player1Selected".visible = false
	$"RefVisual/Player2Selected".visible = true
	$"RefVisual/Player1Selected".visible = false
	$"RefVisual/Player2Selected".visible = true
	picked_winner = 1
	
	$"RefVisual/RemainingPlayer1".editable = false
	$"RefVisual/RemainingPlayer1".value = 0.0
	$"RefVisual/RemainingPlayer2".editable = true

func update_account_info():
	var table = await networking.call("request", "carpet_ball/request", {"request_type" : "flow"})
	if table[1] != 200:
		print("ERROR", table[3])
		return
	
	if "Is_Ref" in table[3]:
		handle_ref_update(table[3])
		return
	else:
		$"RefVisual".visible = false
	
	# Info tiles
	
	var account_info = table[3]["Info"]
	$PlayerTile/Name.text = account_info["Name"]
	$PlayerTile/HBoxContainer/Elo_count.text = str(int(account_info["Elo"]))
	$PlayerTile/HBoxContainer/GBucks_count.text = str(int(account_info["Gbucks"]))
	
	if account_info["Rank"] > 3:
		$Scroll/Container/GridHolder/Rank/RankSpecial.visible = false
		$Scroll/Container/GridHolder/Rank/RankNormal.visible = true
		$Scroll/Container/GridHolder/Rank/RankNormal.text = str(int(account_info["Rank"]))
	else:
		$Scroll/Container/GridHolder/Rank/RankNormal.visible = false
		$Scroll/Container/GridHolder/Rank/RankSpecial.visible = true
		$Scroll/Container/GridHolder/Rank/RankSpecial.text = str(int(account_info["Rank"]))
		$Scroll/Container/GridHolder/Rank/RankSpecial.add_theme_color_override("font_color", rank_to_color[int(account_info["Rank"]) - 1])
	
	# Game tiles
	
	var active_game = table[3]["CurrentGame"]
	
	if not active_game:
		
		$"Scroll/Container/GridHolder/ActiveGames/Scroll/Container/ActiveGame".visible = false
		$"Scroll/Container/GridHolder/ActiveGames/Scroll/Container/CreateGame".visible = true
	
	else:
		
		$"Scroll/Container/GridHolder/ActiveGames/Scroll/Container/ActiveGame".visible = true
		$"Scroll/Container/GridHolder/ActiveGames/Scroll/Container/CreateGame".visible = false
		
		$"Scroll/Container/GridHolder/ActiveGames/Scroll/Container/ActiveGame/Name".text = active_game["Name"]
		
	
	# Rank tiles
	
	reset_ranks()
	
	var leaderboard_info = table[3]["Leaderboard"]
	var holder = $"Scroll/Container/PanelContainer/Container"
	
	for rank in leaderboard_info:
		var new_template : Panel = holder.get_node("Template").duplicate()
		
		holder.add_child(new_template)
		new_template.visible = true
		new_template.get_node("RankInfo/Name").text = leaderboard_info[rank]["Name"].to_upper()
		
		if int(rank) <= len(rank_to_color):
			
			var text : Label = new_template.get_node("RankInfo/RankSpecial")
			text.visible = true
			text.text = rank
			text.add_theme_color_override("font_color", rank_to_color[int(rank) - 1])
			
		else:
			new_template.get_node("RankInfo/RankNormal").visible = true
			new_template.get_node("RankInfo/RankNormal").text = rank
			
		new_template.get_node("EloCount").text = str(int(leaderboard_info[rank]["Elo"]))

func _ready():
	
	while true:
		update_account_info()
		await get_tree().create_timer(1).timeout
	
	
