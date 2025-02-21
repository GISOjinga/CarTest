--!strict
--[[
    * this module will connect the tracker to the ui
    * can clear all previous notifications and connections
    * connects the flip car tracker to the F key bind
    
    * Total Time Passed: tracks the total time that the constraint was used (adds all duration of time together)
    * Activated/DeActivated Notifications: notifies the watcher that a constraint was activated or deactivated
    * Time Duration: tracks the time of when a constraint has been activated and deactivated
]]
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")


-- modules
local _types = require(ReplicatedStorage.Types)
--local constraintMethods = require(ReplicatedStorage.Methods.ConstraintTrackMethods)
local testCaseTracker = require(ReplicatedStorage.Methods.TestCaseTracker)
local testCaseDataInfo = require(ReplicatedStorage.Data.TestCasesInfoData)

-- variables
local startTime = 0
local assets:typeof(ReplicatedStorage.Assets) = ReplicatedStorage:WaitForChild("Assets")::any
local uiFolder:typeof(assets.UI) = assets:WaitForChild("UI")::any

local activationExampleUI = uiFolder.Activation -- example ui for when a constraint is registered for time duration
local guiHolder:typeof(game.StarterGui) = (RunService:IsClient() and Players.LocalPlayer.PlayerGui) or StarterGui::any -- for if client or server





local module = {}

-- clears previous notifications
function module:__clearAll()
    local function clear(testCaseHolderUI)
        local logHolderChildren = testCaseHolderUI.ActivationTracker:GetChildren() -- gets all loggers

        for logHolderChildIndex = 1, #logHolderChildren do
            local log = logHolderChildren[logHolderChildIndex] -- logs child

            if log:IsA("GuiObject") then -- if logger is gui object
                log:Destroy()
            end
        end
    end
    
    --clear(mainGui.RedCar) -- clears logs for red car
    clear(guiHolder.Logger.TestCases) -- clears log for blue car
end



-- adds the highlights of a active constraint
function module:__visualizeHighLights(_car:_types.Car, constraintInfo:_types.ConstraintTrackerInfo, isMotorActive: boolean)
    local constraint = constraintInfo.Constraint
    local highLight = (constraint.Parent::Instance):FindFirstChild("Highlight")::Highlight
    local red = Color3.fromRGB(255, 68, 68)
    local green = Color3.fromRGB(107, 255, 70)

    highLight.FillColor = ((isMotorActive and green) or red)::Color3
    highLight.Enabled = workspace:GetAttribute("Highlights")
end



-- prevents too many ui objects for the Time duration ui
function module:__visualizeRegisteredPreventOverFlow(maxObjects:number, constraints:{{UI:typeof(activationExampleUI), Constraint:Constraint}})
    if #constraints >= maxObjects then
        constraints[1].UI:Destroy()
        table.remove(constraints, 1)
    end
end


-- adds the notifications for the duration of time from when the constraint was changed
function module:__visualizeRegisteredConstraints(testCaseHolderUI):_types.ConstraintEventFunction
    local activationTrackerUI = testCaseHolderUI:WaitForChild("ActivationTracker")
    local constraints:{{UI:typeof(activationExampleUI), Constraint:Constraint}} = {}
    

    local changed:_types.ConstraintEventFunction = function(_car:_types.Car, constraintInfo:_types.ConstraintTrackerInfo, isMotorActive: boolean)
        local constraint = constraintInfo.Constraint
        local activationUI = activationExampleUI:Clone() -- notification for when a constraint is activated or deactivated (due to duration)

        -->> sets ui up to its respective mode (start)
        if isMotorActive then
            activationUI.Duration.TextColor3 = Color3.fromRGB(0, 255, 13)
            activationUI.Title.TextColor3 = Color3.fromRGB(0, 255, 13)
        else
            activationUI.Duration.TextColor3 = Color3.fromRGB(255, 0, 0)
            activationUI.Title.TextColor3 = Color3.fromRGB(255, 0, 0)
        end

        activationUI.Duration.Text = tostring(math.floor((os.clock()-startTime)*10)/10)::string
        activationUI.Title.Text = constraint.Name
        activationUI.Parent = activationTrackerUI
        -->> sets ui up to its respective mode (end)

        self:__visualizeRegisteredPreventOverFlow(30, constraints) -- max amount of gui objects for the duration of the constraint UI
        constraints[#constraints+1] = {UI = activationUI, Constraint = constraint}
    end

    return changed
end




--[[
    * allows tester to see the speed, acceleration, and lap of the car
]]
function module:updateSpeedAndLaps()
    local car:_types.Car = workspace:WaitForChild("BlueCar")::any
    local engine = car.Engine
    -- car info
    local accelerationSpeed:number = engine:GetAttribute("AccelerationSpeed") -- sets the cars acceleration speed
    local maxSpeed:number = engine:GetAttribute("MaxSpeed") -- sets the cars max speed
    local currentLap:number = car:GetAttribute("Laps") -- current lap the car is on
    -- ui
    local lapsUI = guiHolder.Logger.Titles.Laps
    local accelerationUI = guiHolder.Logger.Titles.Acceleration
    local maxSpeedUI = guiHolder.Logger.Titles.MaxSpeed
    
    -- sets the text for the uis
    lapsUI.Text = "Current Lap: "..(currentLap)
    maxSpeedUI.Text = "Max Speed: "..maxSpeed
    accelerationUI.Text = "Acceleration: "..accelerationSpeed

end




--[[
    * will connect to the registered event and the changed event
    * will clear all previous notifications
    * will log to total time passed and any time difference from the time of start test to pause test
    *
]]
function module:__visualize(testCaseHolderUI)
    --[[
        local registeredUIConnectors = self:__visualizeRegisteredConstraints(testCaseHolderUI) -- gets the connectors for registered constraints

    self:__clearAll(testCaseHolderUI) -- clears all previous notifications

    -- notifies the connectors that there was a changed for the exact UI relative to the car
    local changedConnection = constraintMethods.ConstraintChanged:Connect(function(car:_types.Car, constraintTrackerInfo)
        registeredUIConnectors(car, ...)
        self:__visualizeHighLights(car, ...)-- allows you to visualize the highlights on a car
    end)
    ]]
    

    task.spawn(function()
        local durationTimer = guiHolder.Logger.Titles.Duration -- duration ui

        while workspace:GetAttribute("StartTest") do -- while the game is active it will keep clicking the start time
            self:updateSpeedAndLaps() -- updates the laps and current car speed ui
            durationTimer.Text = "Duration: "..tonumber(math.floor(os.clock()-startTime))::number
            task.wait()
        end

        --changedConnection:Disconnect() -- disconnects changed connections
        
    end)
end


-- will allow you to visualize the test cases
function module:__activateTest(testCaseHolderUI:_types.TestCaseHolder)
    local car = workspace:WaitForChild("BlueCar")
    local testCaseUIs = testCaseHolderUI.TestsPassed:GetChildren()::any
    local testCaseInfoUI = testCaseHolderUI.TestCaseInfo
    local passedColor = Color3.fromRGB(0, 255, 8)
    local failedColor = Color3.fromRGB(255, 0, 0)
    local testCasesStates = {}

    -- whenever a test case changes it sets the background color of the test case
    testCaseTracker.Changed:Connect(function(testCaseName, passed)
        local testCaseTextInfoUI = testCaseHolderUI.TestsPassed:FindFirstChild(testCaseName)::TextLabel

        testCaseTextInfoUI.BackgroundColor3 = (passed and passedColor) or failedColor
        testCasesStates[testCaseName] = passed
    end)
    
    
    --[[
        * tracks completed laps
        * fires to server for each completed lap
    ]]
    car:GetAttributeChangedSignal("Laps"):Connect(function()
        local currentLap:number = car:GetAttribute("Laps")-1
        local failedTest:{string} = {}
        local passed = true
        
        -- checks to see if any test case states are false
        for testCaseName, testPassed in pairs(testCasesStates) do
            if testPassed == false then -- means the lap didn't complete with no errors
                passed = false
                failedTest[#failedTest+1] = testCaseName
            end
        end

        -- if test passed or failed
        if RunService:IsClient() then -- fires the event 
            local message = "Lap: "..tostring(currentLap)

            -- adds the acceleration
            message = message.." | Acceleration: "..0

            -- adds the max speed
            message = message.." | Speed: "..0

            -- adds the passed or failed
            message = message.." | Lap Completion: " .. ((passed and "Passed") or "Failed")


            -- adds this message if test failed
            if passed == false then
                -- adds the failed test cases 
                message = message.." (".. table.concat(failedTest, ", ") ..")"
            end

            -- fires wether the lap completed or not
            ReplicatedStorage.Remotes.TestMessages:FireServer(message)
        end
    end)

    -- when the test case tracker ends it will turn the check mark visible and show all test cases
    testCaseTracker.Ended:Connect(function(_passedTestCases, failedTestCases)
        local testCasePassedTextInfoUI = testCaseHolderUI.TestCasePassedText
        local passed = #failedTestCases <= 0
        local textMessage = (passed and "All Test Cases Passed") or "Test Cases Failed: "

        testCaseHolderUI.TestsPassed.Visible = true
        testCaseHolderUI.CheckMark.Visible = passed
        testCasePassedTextInfoUI.TextColor3 = (passed and passedColor) or failedColor

        if not passed then -- adds the failed test cases to the message
            for i = 1, #failedTestCases do
                local failedTestCaseName = failedTestCases[i]
                textMessage = textMessage..failedTestCaseName..((#failedTestCases > i and ", ") or "")
            end
        end

        testCasePassedTextInfoUI.Text = textMessage -- sets the text message for passed or failed
        testCasePassedTextInfoUI.Visible = true

        if RunService:IsClient() then -- fires the event 
            ReplicatedStorage.Remotes.TestMessages:FireServer(textMessage)
        end
    end)


    -- this will allow you to over over each test case and see the info inside each case
    for i = 1, #testCaseUIs do
        local testCaseUI:TextLabel = testCaseUIs[i]

        if testCaseUI:IsA("TextLabel") then
            testCaseUI.MouseEnter:Connect(function()
                testCaseInfoUI.Text = testCaseDataInfo[testCaseUI.Name] -- the info for each test case
                testCaseInfoUI.Visible = true
            end)

            testCaseUI.MouseLeave:Connect(function()
                testCaseInfoUI.Visible = false
            end)
        end
    end
end




-- the surface level initializer for the visualizer
function module:visualize()
    local carsFrameHolder:_types.TestCaseHolder = guiHolder.Logger:WaitForChild("TestCases")::any
    startTime = os.clock()

    
    self:__activateTest(carsFrameHolder)
    self:__visualize(carsFrameHolder)
end



return module