--!strict
--[[
    This module is used to hold the functions for each test
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")


-- modules
local _types = require(ReplicatedStorage.Types)
local testCaseData = require(ReplicatedStorage.Data.TestCasesData)
local rayCastMethods = require(ReplicatedStorage.Methods.RayCast.RayCastingMethods)



-- variables
local module = {}

--[[
    * will check align orientation constraint (mainly its attachment)
    * will check if the current wheel angles reached the maximum angle and the minimum angle
]]
module.AlignOrientation = function(car:_types.Car, constraints:_types.CarConstraints, testCaseInfo:{[Attachment]:{LowestAngle:boolean, HighestAngle:boolean}}, _timePassed:number):boolean
    local engine = car.Engine
    local maxTurnAngle:number = engine:GetAttribute("MaxTurnAngle") -- how far in degrees the wheels can turn on its axis
    local motors = constraints.Attachment
    local passed = true

    for i = 1, #motors do
        local motor = motors[i]
        local turnableAttachment = motor:GetAttribute("AllowRotation") -- only for attachments related to wheel turning
        
        if turnableAttachment then -- makes sure the attachment is used for turning wheels
            local motorAngle = motor.Orientation.Y
            local trackingInfo = testCaseInfo[motor]::any or { -- used for setting previous information
                LowestAngle = false,
                HighestAngle = false,
            }

            trackingInfo.LowestAngle = trackingInfo.LowestAngle or motorAngle <= -maxTurnAngle -- wheel hit the lowest turn angle
            trackingInfo.HighestAngle = trackingInfo.HighestAngle or motorAngle >= maxTurnAngle -- wheel hit the highest turn angle
            
            testCaseInfo[motor] = trackingInfo

            if math.abs(motorAngle) > math.abs(maxTurnAngle) then -- fails if the turn surpasses the max angle of the car wheels
                passed = false
                break
            end
        end
    end

    -- when test ends it will set the test as passed or failed if it reached both limits
    if not workspace:GetAttribute("StartTest") then
        for _, info in testCaseInfo do
            if not (info.LowestAngle and info.HighestAngle) then
                passed = false
                break
            end
        end
    end

    return passed
end


--[[
    * will check if springs length are within the cylinders limits
]]
module.CylindricalConstraint = function(_car:_types.Car, constraints:_types.CarConstraints, _testCaseInfo:{any}, _timePassed:number):boolean
    local springs = constraints.SpringConstraint
    local passed = true

    -- checks every spring
    for i = 1, #springs do
        local spring = springs[i]
        local assignedCylinder = (spring.Parent::Instance):FindFirstChildOfClass("CylindricalConstraint")
        local cylinderPosition = math.abs(assignedCylinder and assignedCylinder.CurrentPosition or 0) -- the position property of the cylinder
        local springLength = spring.CurrentLength -- the current length of the spring
        local upperLength = math.abs(assignedCylinder and assignedCylinder.UpperLimit or 0) -- the upper limit of the cylinder
        local lowerLength = math.abs(assignedCylinder and assignedCylinder.LowerLimit or 0) -- the lower limit of the cylinder
        local currentMaxLength = if (lowerLength-cylinderPosition) < (upperLength-cylinderPosition) then lowerLength else upperLength -- checks which limit is closest to the cylinders position then sets that as the length being check for
        
        if assignedCylinder and cylinderPosition ~= 0 then
            if springLength > currentMaxLength + 5 then -- checks if the cylinder exceeded the closest limit to it
                passed = false
                break
            end
        end
    end

    return passed
end


--[[
    * checks if the angular velocity changes
    * checks if the car drives in reverse
    * checks if car assembly velocity exceeds the extreme thresh hod
]]
module.AngularVelocity = function(car:_types.Car, constraints:_types.CarConstraints, testCaseInfo:{[AngularVelocity]:{Reversed:boolean, Traveled:boolean}}, _timePassed:number):boolean
    local velocities = constraints.AngularVelocity
    local carSeat = car.Seat
    local passed = true


    if carSeat.AssemblyLinearVelocity.Magnitude >= testCaseData.MaxLinearVelocity then -- checks if the linear velocity ever exceeds max velocity
        passed = false
        
    elseif not workspace:GetAttribute("StartTest") then -- when test ends will check if the car was in reverse and if it traveled at all
        for _, info in testCaseInfo do
            if not (info.Reversed and info.Traveled) then
                passed = false
                break
            end
        end

    else -- checks if the wheels are moving and if the wheels at anytime are put in reverse
        for i = 1, #velocities do
            local vectorVelocity = velocities[i]
            local invert:number = (vectorVelocity:GetAttribute("InvertSpeed") and -1) or 1 -- allows the speed of the car to be inverted
            local velocity:number = vectorVelocity.AngularVelocity.X * invert
            local trackingInfo = testCaseInfo[vectorVelocity]::any or {  -- used for setting previous information
                Traveled = false,
                Reversed = false,
            }

            trackingInfo.Traveled = trackingInfo.Traveled or velocity ~= 0 -- wheel moved in general
            trackingInfo.Reversed = trackingInfo.Reversed or velocity < 0 -- wheel moved backward
            testCaseInfo[vectorVelocity] = trackingInfo
        end
    end

    return passed
end


--[[
    * checks if Attachment 0 & 1 are active
]]
module.AlignPosition = function(_car:_types.Car, constraints:_types.CarConstraints, _testCaseInfo:{any}, _timePassed:number):boolean
    local alignPositions = constraints.AlignPosition
    local passed = true

    
    for i = 1, #alignPositions do
        local alignPosition = alignPositions[i]
        local attachment0 = alignPosition.Attachment0
        local attachment1 = alignPosition.Attachment1
        
        if (not alignPosition.Enabled) or (not attachment1) or (not attachment0) then
            
            passed = false
            break
        end
    end

    return passed
end


--[[
    * makes sure that the springs length has changed
]]
module.SpringConstraint = function(_car:_types.Car, constraints:_types.CarConstraints, testCaseInfo:{[SpringConstraint]:{Changed:boolean, OldLength:boolean}}, _timePassed:number):boolean
    local springConstraints = constraints.SpringConstraint
    local passed = true

    if not workspace:GetAttribute("StartTest") then -- when test ends; does final checks
        for _, info in testCaseInfo do
            if not info.Changed then
                passed = false
                break
            end
        end

    else -- checks if the wheels are moving and if the wheels at anytime are put in reverse
        for i = 1, #springConstraints do -- loops through each constraint
            local spring = springConstraints[i]
            local springLength = spring.CurrentLength -- the current length of the spring
            local trackingInfo = testCaseInfo[spring]::any or { -- used for setting previous information
                OldLength = springLength,
                Changed = false,
            }

            trackingInfo.Changed = trackingInfo.Changed or trackingInfo.OldLength ~= springLength -- when the springs length changes
            testCaseInfo[spring] = trackingInfo
        end
    end

    return passed
end



--[[
    * makes sure that the car inst flipped over for a duration of time
    * makes sure the car is touching the ground for a duration of time
    * checks if the car is stuck
    * checks if all laps were completed successfully without getting stuck
]]
module.SevereTestCases = function(car:_types.Car, _constraints:_types.CarConstraints, testCaseInfo:{Info:{TimeOffGround:number, OldPosition:Vector3, TimeStuck:number}}, _timePassed:number):boolean
    local seatCFrame = car.Seat.CFrame
    local laps:number = car:GetAttribute("Laps")
    local passed = true
    local trackingInfo = testCaseInfo.Info::any or {
        TimeOffGround = 0,
        OldPosition = seatCFrame.Position,
        TimeStuck = 0,
    }
    

    do -- fails if the car is stuck in a position for too long
        local distance = (trackingInfo.OldPosition - seatCFrame.Position).Magnitude

        if trackingInfo.TimeStuck < testCaseData.FreeMovementTime then -- checks if time stuck is less than max stuck time
            if distance < testCaseData.FreeMovement then -- if the distance has not changed passed the maximum distance
                trackingInfo.TimeStuck += _timePassed -- adds up the time it is stuck
            else -- resets it if the distance changed
                trackingInfo.OldPosition = seatCFrame.Position
                trackingInfo.TimeStuck = 0
            end
        else -- since its greater the test fails because it was stuck too long
            passed = false
        end
    end


    do -- fails if car is not touching the floor
        local rayCastToGroundResults = rayCastMethods:CastRay(seatCFrame.Position, Vector3.new(0, -testCaseData.RayCastingDistance, 0), {
            Include = {workspace.Terrain}
        }) -- a ray cast white listing the terrain

        if trackingInfo.TimeOffGround < testCaseData.TimeOffGround then -- checks if the car is off the ground under a time limit
            if not rayCastToGroundResults.Material then -- if there is no ground then add time
                trackingInfo.TimeOffGround += _timePassed
            else
                trackingInfo.TimeOffGround = 0 -- rests time if there is ground
            end

        else -- fails if it exceeds time limit
            passed = false
        end
    end


    if (not workspace:GetAttribute("StartTest")) and laps <= 3 then -- when test ends; does final checks
        passed = false
    end
    

    testCaseInfo.Info = trackingInfo -- saves previous test case info
    return passed
end


return module