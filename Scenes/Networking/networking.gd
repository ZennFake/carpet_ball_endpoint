## // SPRITE // ##

extends Node2D

## // VARIABLES // ##

var master_url : String = "https://9ff0-72-24-143-199.ngrok-free.app/"

## // FUNCTIONS // ##

func request(url : String, args : Dictionary):
	
	var api_headers = ["api-key: gary_is_fat"]
	var headers = PackedStringArray(api_headers)
	
	var arg_to_string = "?"
	
	args["session_id"] = get_parent().get_meta("SessionId")
	
	for arg in args:
		if len(arg_to_string) > 1:
			arg_to_string += "&"
		arg_to_string += arg + "=" + args[arg]
	
	#print(master_url + url + arg_to_string)
	
	print($HTTPRequest.get_http_client_status())
	
	while $HTTPRequest.get_http_client_status() != 0:
		await get_tree().create_timer(.1).timeout
	
	$HTTPRequest.request(master_url + url + arg_to_string, headers, HTTPClient.METHOD_GET)
	
	var result = await $HTTPRequest.request_completed
	var result_header : String = result[2][1]
	print(result_header)
	if result_header.begins_with("Content-Type: text/html"):
		var response = PackedByteArray(result[3])
		result[3] = response.get_string_from_utf8()
	if result_header.begins_with("Content-Type: application/json"):
		var response = PackedByteArray(result[3])
		result[3] = response.get_string_from_utf8()
		result[3] = JSON.parse_string(result[3])
		
	print(result)
	
	return result
