--!strict
--[[
    * will track cars
    * will activate the client sided uis
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")


-- modules
local constraintMethods = require(ReplicatedStorage.Methods.ConstraintTrackMethods) -- to track the constrains on the car
local visualizeMethods = require(ReplicatedStorage.Methods.ConstraintVisualizeMethods) -- to visualize the constraints
local testingMethods = require(ReplicatedStorage.Methods.TestingMethods) -- allows for custom testing


local _types = require(ReplicatedStorage.Types)




-- variables
local player = Players.LocalPlayer
local camera = workspace.Camera
local module = {}



--[[
    * moves camera
    * lerps it
]]
function module:lerpCamera(seat:BasePart, time:number): ()
    local yDistance, zDistance = 15, 30
    local seatCFrame = seat.CFrame
    local newCFramePosition = seatCFrame * CFrame.new(0, yDistance, zDistance)
    local newCFrame = CFrame.lookAt(newCFramePosition.Position, seatCFrame.Position)
    local deltaCFrame = camera.CFrame:Lerp(newCFrame, time)

    camera.CFrame = deltaCFrame
end



--[[
    * to set up the gui and to set up camera
    * prevents camera from clipping to car
]]
function module:setUpCamera(blueCar:_types.Car)
    local loggerGui = StarterGui.Logger:Clone()::any
    local messageGUI = StarterGui.MessageGUI:Clone()::any
    local carDescendants = blueCar:GetDescendants()

    loggerGui.Parent = player.PlayerGui -- places ui 
    messageGUI.Parent = player.PlayerGui -- places ui 
    camera.CameraType = Enum.CameraType.Scriptable -- allows camera to be scriptable
    camera.CameraSubject = blueCar.Seat -- makes camera follow the car

    for i = 1, #carDescendants do -- prevents clients camera from clipping to parts of the car
        local descendant:BasePart = carDescendants[i]::any

        if descendant:IsA("BasePart") then
            descendant.CanCollide = false
        end
    end
end

--[[
    * activated car tracker
    * places the logger gui in the player gui
]]
function module:Start()
    local blueCar:_types.Car = workspace:WaitForChild("BlueCar")::any -- the model of the blue car
    local seat = blueCar.Seat

    self:setUpCamera(blueCar) -- setup camera and ui

    task.spawn(function() -- lerps camera
        while seat.Parent do
            module:lerpCamera(seat, .1) -- places camera at lerped position
            task.wait()
        end
    end)

    -- when player wants to know when the test starts
    workspace:GetAttributeChangedSignal("StartTest"):Connect(function()
        if workspace:GetAttribute("StartTest") then -- for setting up the visual and pausing the test
            task.spawn(constraintMethods.trackCar, blueCar::any) -- allows for the visualizer to know if constraint gets changed and tracks car
        end
    end)


    visualizeMethods:__clearAll() -- clears all previous visualizations
    testingMethods:loadTestReceiver() -- preloads the test buttons and receivers (yields till start test)
end

return module