--!strict


--[[
    * This module is to allow for you to activate the vehicle
    * Allows you to see if the car is at its target using the method "isAtTarget"
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")


-- carMethods
local _types = require(ReplicatedStorage.Types)
local newMotorMethods = require(ReplicatedStorage.Methods.MotorMethods)::any


-- variables
local maxLaps = 3 -- max laps to take
local wayPoints = workspace.WayPoints
local carMethods = {}


--[[
    * gets target and cars position
    * converts it to 2D using the X and Z coordinates
    * checks if car is at the target within a radius
]]
function carMethods:isCarAtTarget(car:_types.Car):boolean
    local engine = car.Engine
    local hitBoxRadius:number = engine:GetAttribute("HitBoxRadius") -- in studs, determines the cars hit box

    local carPosition:Vector3 = car.Seat.Position -- position of the car
    local targetPosition:Vector3 = engine:GetAttribute("Target")

    local car2DPosition:Vector2 = Vector2.new(carPosition.X, carPosition.Z)
    local target2DPosition:Vector2 = Vector2.new(targetPosition.X, targetPosition.Z)

    if (car2DPosition-target2DPosition).Magnitude <= hitBoxRadius then
        return true
    end

    return false
end





-- yields thread till game is in action
function carMethods:isGameActive()
    return workspace:GetAttribute("StartTest")
end


--[[
    * creates a loop for car
    * loop puts car in auto drive to target
    * loop ends when car ends
    * loop ends when car is at the target
]]
function carMethods.startEngine(car:_types.Car)
    local startTime = os.clock()
    local passedTime = 0 -- delta time passed since end of the loop
    local engine = car.Engine -- cars engine
    local constraints = newMotorMethods:getAllConstraints(car) -- gets all constraints on the car
    local cylindricalAttachments = constraints.Attachment
    local cylindricalAngularVelocity = constraints.AngularVelocity
    
	engine:SetAttribute("Active", true) -- Starts engine
	
    while car:IsDescendantOf(workspace) and engine:GetAttribute("Active") and (not carMethods:isCarAtTarget(car)) and carMethods:isGameActive() do
        passedTime = os.clock() - startTime

        newMotorMethods:turnWheelsToTarget(car, cylindricalAttachments, passedTime) -- turns wheel to most approximate angle
        newMotorMethods:driveToTarget(car, cylindricalAngularVelocity, passedTime) -- pushes car in a linear fashion for driving
        
        startTime = os.clock() -- resets StartTime
        task.wait()
    end

    -->> resets targets position to cars position
    engine:SetAttribute("Active", false)

    -->> hits the breaks
    newMotorMethods:setCarSpeed(engine, cylindricalAngularVelocity, 0)
end





-- automatically turns on engine to move car to location
function carMethods:moveTo(car:_types.Car, position:Vector3)
    local engine = car.Engine
    
    engine:SetAttribute("Target", position)
    
    if not engine:GetAttribute("Active") then
        task.spawn(self.startEngine,car)
    end
end




--[[
    * adjusts cars speed & acceleration
    * relative to laps
    * for 3 laps
]]
function carMethods:updateCarToLap(car:_types.Car)
    local engine = car.Engine
    local currentLap:number = car:GetAttribute("Laps")
    local speed = {25, 50, 100, 0}
    local acceleration = {5, 8, 10, 0}

    engine:SetAttribute("AccelerationSpeed", acceleration[currentLap]) -- sets the cars acceleration speed
    engine:SetAttribute("MaxSpeed", speed[currentLap]) -- sets the cars max speed
end



--[[
    * updates which lap the car is on
    * updates the resets way point after full lap
]]
function carMethods:updateWayPoints(car:_types.Car)
    local totalWayPoints = #wayPoints:GetChildren()
    local currentWaypoint:number = car:GetAttribute("CurrentWayPoint")
    local currentLap:number = car:GetAttribute("Laps")
    
    if currentWaypoint >= totalWayPoints then -- checks if the car fully circled the waypoints
        car:SetAttribute("CurrentWayPoint", 1) -- fully resets the saved way point

        car:SetAttribute("Laps", currentLap + 1) -- adds one point to the laps
    end
    
    if currentLap + 1 > maxLaps then
        workspace:SetAttribute("StartTest", false)
    end
end



--[[
    * moves car to each waypoint
]]
function carMethods:moveCar(car:_types.Car, wayPoint:BasePart, activeWayPoint:number):boolean
    self:moveTo(car, wayPoint.Position) -- moves the new car model

    repeat
        task.wait()
    until (not self:isGameActive()) or self:isCarAtTarget(car)::boolean -- waits until the old car reached the waypoint or game paused

    if self:isCarAtTarget(car) then -- only moves to the next way point if the car makes it to the target
        car:SetAttribute("CurrentWayPoint", activeWayPoint+1) -- sets the current way Point
    end

    return self:isGameActive()
end




-- to keep the car going in a circle around the track
function carMethods:updateCarLoop(car:_types.Car)
    local totalWayPoints = #wayPoints:GetChildren()


    self:updateWayPoints(car)
    self:updateCarToLap(car)

    
    for i = 1, totalWayPoints do -- moves car to each way point and back
        local activeWayPoint:number = car:GetAttribute("CurrentWayPoint") or i -- the saved wayPoint
        local wayPoint = wayPoints:FindFirstChild("Point"..i)::BasePart -- current way point
        

        if i == activeWayPoint then -- if active way point is or greater than saved wayPoint
            local gameIsActive = self:moveCar(car, wayPoint, activeWayPoint)

            if not gameIsActive then
                break
            end
        end
    end
end


return carMethods