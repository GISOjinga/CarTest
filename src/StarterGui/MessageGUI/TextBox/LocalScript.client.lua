-- Import necessary services and objects
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remoteEvent = ReplicatedStorage.Remotes:WaitForChild("TextBoxEvent")
local statusEvent = ReplicatedStorage.Remotes:WaitForChild("StatusEvent")
-- Get the version of the Roblox client
local ClientVersion = version()

-- Define constants for the action name and the name of the TextBox event
local ACTION_NAME = "FocusTheTextBox"

-- Get a reference to the TextBox object
local textBox = script.Parent

-- Initialize a variable for the entered text
local enteredText = ""

-- Define a function to handle the "FocusTheTextBox" action
local function handleAction(actionName, inputState, _inputObject)
	if actionName == ACTION_NAME and inputState == Enum.UserInputState.Begin then
		-- Capture the focus of the TextBox object when the action is triggered
		textBox:CaptureFocus()
	end
end

-- Bind the "FocusTheTextBox" action to the handleAction function
ContextActionService:BindAction(ACTION_NAME, handleAction, false, Enum.KeyCode.LeftAlt)

-- Define a function to handle the "FocusLost" event of the TextBox object
local function onTextBoxFocusLost(enterPressed)
	if enterPressed then
		-- Get the entered text from the TextBox object and hide it
		enteredText = textBox.Text
		textBox.Visible = false
		print(enteredText)
		-- Fire a remote event to send the entered text to the server
		remoteEvent:FireServer(enteredText, ClientVersion)
	end
end

-- Connect the onTextBoxFocusLost function to the "FocusLost" event of the TextBox object
textBox.FocusLost:Connect(onTextBoxFocusLost)

function fire_send_status(player, status_msg)
	statusEvent.FireServer(player,status_msg)
end

return {
	send_msg = fire_send_status
}