--!strict

--[[
    * this module will prompt the car to follow way points
    * will register the constraint trackers
    * will register the start and pause test
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")


-- modules
local _types = require(ReplicatedStorage.Types)
local _messaging = require(ServerScriptService.SendMessage)
local vehicleMethods = require(ReplicatedStorage.Methods.VehicleMethods) -- to start the car up
local constraintMethods = require(ReplicatedStorage.Methods.ConstraintTrackMethods) -- to track the constrains on the car
local visualizeMethods = require(ReplicatedStorage.Methods.ConstraintVisualizeMethods) -- to visualize the constraints
local testingMethods = require(ReplicatedStorage.Methods.TestingMethods) -- allows for custom testing



-- variables
local module = {}






--[[
    * activated car
    * circles through all way points
]]
function module:Start()
    local blueCar:_types.Car = workspace:WaitForChild("BlueCar")::any -- the model of the blue car

    -- any time the start test attribute changes it will check to see if its true and if so will force car to start looping through waypoints
    workspace:GetAttributeChangedSignal("StartTest"):Connect(function()
        
        if workspace:GetAttribute("StartTest") then -- for setting up the visual and pausing the test
            task.spawn(constraintMethods.trackCar, blueCar::any) -- allows for the visualizer to know if constraint gets changed and tracks car
            task.spawn(function() -- allows for the visualizer to know if constraint gets changed and tracks car
                while vehicleMethods:isGameActive() do
                    vehicleMethods:updateCarLoop(blueCar::any)
                end
            end)
        end
    end)


    visualizeMethods:__clearAll() -- clears all previous visualizations
    testingMethods:loadTestReceiver() -- preloads the test buttons and receivers (yields till start test)
end

return module