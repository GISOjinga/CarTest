--!strict
--[[
    * will connect the start and stop test button
    * connects the changes in tests modes to a key bind
    * registers the remote events
]]
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")


-- modules
local _types = require(ReplicatedStorage.Types)
local testCaseTracker = require(ReplicatedStorage.Methods.TestCaseTracker)
local visualizeMethods = require(ReplicatedStorage.Methods.ConstraintVisualizeMethods) -- to visualize the constraints

-- remotes
local remotes = ReplicatedStorage.Remotes
local startTest = remotes.StartTest

-- variables
local guiHolder = (RunService:IsClient() and Players.LocalPlayer.PlayerGui) or StarterGui
local module = {}


-- changes ui text and and color and does a tween effect
function module.flipUI()
    local testButtonUI = guiHolder.Logger.ActiveButtons.Test
    local originalSize = UDim2.fromScale(0.054, 0.093)
    local playingColor = Color3.fromRGB(47, 255, 0)
    local stoppedColor = Color3.fromRGB(255, 128, 0)

    if testButtonUI.BackgroundColor3 == stoppedColor then
        testButtonUI.Titles.Text = "Start Test"
        testButtonUI.BackgroundColor3 = playingColor
    else
        testButtonUI.Titles.Text = "Pause Test"
        testButtonUI.BackgroundColor3 = stoppedColor
    end

    testButtonUI.Size = UDim2.new() -- sets the size to 0 for the effects to be seen

    TweenService:Create(testButtonUI,
            TweenInfo.new(math.random(1,2), Enum.EasingStyle.Elastic),
            {
            Size = originalSize
        }
    ):Play() -- elasticizes the animation of the size
end



-- changes ui text and and color and does a tween effect for highlight button
function module.loadHighlightButton(onOrOff:boolean)
    local testButtonUI = guiHolder.Logger.ActiveButtons.Highlight
    local originalSize = UDim2.fromScale(0.314, 0.68)
    local playingColor = Color3.fromRGB(47, 255, 0)
    local stoppedColor = Color3.fromRGB(255, 128, 0)

    if onOrOff then
        testButtonUI.Titles.Text = "Highlights On"
        testButtonUI.BackgroundColor3 = playingColor
    else
        testButtonUI.Titles.Text = "Highlights Off"
        testButtonUI.BackgroundColor3 = stoppedColor
    end

    testButtonUI.Size = UDim2.new() -- sets the size to 0 for the effects to be seen

    TweenService:Create(testButtonUI,
            TweenInfo.new(math.random(1,2), Enum.EasingStyle.Elastic),
            {
            Size = originalSize
        }
    ):Play() -- elasticizes the animation of the size
end


-- sets start test attribute in workspace to true effectively starting the test run
function module.startTest()
    --module.flipUI() -- ui effect

    if guiHolder.Logger.ActiveButtons.Test.Visible then -- allows you to start a test and not pause a test
        if RunService:IsClient() then
            startTest:FireServer() -- tells server to start the test
        else
            workspace:SetAttribute("StartTest", not workspace:GetAttribute("StartTest"))  -- if server then starts test
        end
    
        guiHolder.Logger.ActiveButtons.Test.Visible = false -- hides button after toggled once
    end
end


-- changes the highligh
function module.adjustHighlight()
    local carDescendants = workspace.BlueCar:GetDescendants()
    workspace:SetAttribute("Highlights", not workspace:GetAttribute("Highlights"))
    module.loadHighlightButton(workspace:GetAttribute("Highlights"))

    for i = 1, #carDescendants do -- adjusts all highlights of the cars motors
        local descendant = carDescendants[i]::any

        if descendant:IsA("Highlight") then
            descendant.Enabled = workspace:GetAttribute("Highlights")
        end
    end
end

--[[
    * loads receiver for server event
    * loads receiver for if the button is pressed
    * loads receiver for if the v key is pressed
]]
function module:loadTestReceiver()
    local blueCar:_types.Car = workspace:WaitForChild("BlueCar")::any

    -- for when the client fires to server to start test
    if RunService:IsServer() then
        startTest.OnServerEvent:Connect(module.startTest)
    end

    -- loads in the start test button for the server and client
    guiHolder.Logger.ActiveButtons.Test.MouseButton1Click:Connect(module.startTest)

    -- turns highlight on and off
    guiHolder.Logger.ActiveButtons.Highlight.MouseButton1Click:Connect(self.adjustHighlight)

    -- when v key is pressed the test should start and decipher if it is on the server or client
    UserInputService.InputBegan:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.V then
            module.startTest()
        end
    end)

    -- when v key is pressed the test should start and decipher if it is on the server or client
    UserInputService.InputBegan:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.H then
            self.adjustHighlight()
        end
    end)

    -- to load the highlight button
    self.loadHighlightButton(workspace:GetAttribute("Highlights"))

    -- yields test until the start test attribute is set to true
    while not workspace:GetAttribute("StartTest") do
        workspace:GetAttributeChangedSignal("StartTest"):Wait()
    end

    visualizeMethods:visualize() -- yields till the visualize handler is ready (for the ui and highlight)
    if workspace:GetAttribute("StartTest") then
        task.spawn(testCaseTracker.startTracking, blueCar::any)
    end
end




return module