local HttpService = game:GetService('HttpService')
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")


-- Initialize variables for session and player IDs
local sessionId = ""
local player_id = ""

-- URL for the external API endpoint
local url = 'https://MSTEST.bmohit.repl.co'

-- Get the current version of the Roblox engine
local RCC_version = version()

-- Define a function to handle player input and start a new session
local function enterText(playername, enteredText, clientVersion)
	-- Get the first player in the game (assuming only one player is playing at a time)
	local player = Players:GetPlayers()[1]

	-- Set the session ID and player ID based on the user input
	sessionId = enteredText
	print(sessionId)
	player_id = player.UserId

	-- Create a data table with information about the player and session
	local data = {
		player_id = player_id,
		player_name = player.Name,
		place_id = game.PlaceId,
		session_id = sessionId,
		RCC = RCC_version,
		Client = clientVersion
	}

	-- Send the data to the external API endpoint
	HttpService:PostAsync(url, HttpService:JSONEncode(data))
end

-- Connect the enterText function to the TextBoxEvent
ReplicatedStorage.Remotes:WaitForChild("TextBoxEvent").OnServerEvent:Connect(enterText)

-- Define a function to send status updates to the external API endpoint
local function send_status(player, status_msg)
	local data = {
		player_id = player_id,
		session_id = sessionId,
		status = status_msg
	}

	print(player, status_msg)
	HttpService:PostAsync(url, HttpService:JSONEncode(data))
end

-- Connects the send status to the text messaging event
ReplicatedStorage.Remotes:WaitForChild("TestMessages").OnServerEvent:Connect(send_status)

-- Define a function to get the current session ID
local function get_session_ID()
	return sessionId
end

-- Return the send_status and get_session_ID functions for use in other scripts
return {
	SendStatus = send_status,
	GetSessionID = get_session_ID
}
