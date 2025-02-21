--!strict
--[[
    * module will calculate distance from time to speed (disFromTimeSpeed)
    * will use dot products to calculate the appropriate turn angle to target (turnWheelsToTarget)
    * will allow for car to accelerate (driveToTarget)
    * puts car in drive and reverse (setCarSpeed, driveToTarget)
    * return all constraints being used in the car (getAllConstraints)
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")


-- carMethods
local _types = require(ReplicatedStorage.Types)


-- variables
local motorMethods = {}

function motorMethods:disFromTimeSpeed(time:number,speed:number): number
	return time*speed
end

--[[
    * Returns vector2's of the cars cframe using the X and Z axis
    * The vectors table also contains the vector from the cars position to the target position

    * returns the dot products of the right vector and left vector relative to the vector from the car position to the target position
    * this is for determining the closest angle/vector to turn to
]]
function motorMethods:getTargetToCarDotProduct(seatCFrame:CFrame, targetPosition:Vector3)
    local vectorToTarget = targetPosition-seatCFrame.Position -- direction from the seats position to the target position

    local Vectors = {
        PositionToTarget = Vector2.new(vectorToTarget.X, vectorToTarget.Z), -- vector 2 angle of the direction between the seat and target using the X and Z axis
        LookVector = Vector2.new(seatCFrame.LookVector.X, seatCFrame.LookVector.Z), -- the vector 2 of the seats cframe's lookVector using only the X and Z axis
        RightVector = Vector2.new(seatCFrame.RightVector.X, seatCFrame.RightVector.Z), -- the vector 2 of the seats cframe's rightVector using only the X and Z axis
    }

    return {
        SeatCFrame = seatCFrame,
        Vectors = Vectors, -- used to get the vector 2's of the car to the target and to get the vector 2's of the cars Cframe's Vector3's into Vector2's
        VectorsToTargetProducts = { -- now creates the dot product
            LookVector = Vectors.LookVector:Dot(Vectors.PositionToTarget), -- determines the angle between the look vector and the seat to target vector
            RightAngle = Vectors.RightVector:Dot(Vectors.PositionToTarget), -- determines the angle between the right vector and the seat to target vector
            LeftAngle = (-Vectors.RightVector):Dot(Vectors.PositionToTarget), -- gets the opposite vector of the right vector and determines the new angle 
        },
    }
end


--[[
    finds the desired total angle and max angle between the cars cframe to the target position
]]
function motorMethods:getDesiredAngle(seatCFrame:CFrame, targetPosition:Vector3, maxTurnAngle:number)
    local products = self:getTargetToCarDotProduct(seatCFrame, targetPosition)
    local carLookVector:Vector2 = products.Vectors.LookVector -- the vector 2 of the seats cframe's lookVector using only the X and Z axis
    local vectorToTarget:Vector2 = products.Vectors.PositionToTarget -- vector 2 angle of the direction between the seat and target using the X and Z axis
    local angleToTheLeft:number = products.VectorsToTargetProducts.LeftAngle -- gets the opposite vector of the right vector and determines the new angle
    local angleToTheRight:number = products.VectorsToTargetProducts.RightAngle -- determines the angle between the right vector and the seat to target vector
    local angleToTheFront:number = products.VectorsToTargetProducts.LookVector -- determines the angle between the look vector and the seat to target vector

    local angle = math.clamp(angleToTheFront/(carLookVector.Magnitude*vectorToTarget.Magnitude), -1, 1)
    local vectorAngle = math.acos(angle) -- gets the angle from cars CFrame lookVector and seat to target vector
    local absoluteAngle = math.abs(math.deg(vectorAngle)) -- absolute angle in degrees of the vector angle
    local normalDirection = ((angleToTheRight < angleToTheLeft and -1) or 1)::number -- which side of the 2D vector it is on
    local MaxTurnAngle = ((maxTurnAngle<absoluteAngle) and maxTurnAngle) or absoluteAngle -- gets the minimum turn angle from the max turn angle and the absolute angle
    
    
    return {
        MaxTurnAngle = (MaxTurnAngle ~= MaxTurnAngle and 0) or MaxTurnAngle, -- prevents nan and is the current max angle (weighs which angle is the least)
        Angle = (absoluteAngle*normalDirection) -- converts the absolute angle to the desired angle
    }
end


--[[
    * get optimal angle between target and car
    * turns wheel to the optimal angle relative to the time passed
]]
function motorMethods:turnWheelsToTarget(car:_types.Car, motors:{Attachment}, timePassed:number)
    local engine = car.Engine
    local seat = car.Seat

    local targetPosition:Vector3 = engine:GetAttribute("Target") -- position of the target
    local maxTurnAngle:number = engine:GetAttribute("MaxTurnAngle") -- how far in degrees the wheels can turn on its axis
    local turnSpeed:number  = engine:GetAttribute("TurnAngleSpeed") -- the turn speed of the wheels
    local wheelAngles:number = engine:GetAttribute("CurrentWheelAngle") -- the active current angle of the wheels

    local seatCFrame = seat.CFrame

    local angles = self:getDesiredAngle(seatCFrame, targetPosition, maxTurnAngle)

    local translatedDistance:number = self:disFromTimeSpeed(timePassed, turnSpeed) -- the total distance that the angle can travel in the time that passed
	local desiredAngle = ((angles.Angle == 0 and translatedDistance) or angles.Angle)::number -- prevents angle from being zero
    local percentileAngle = translatedDistance/math.abs(desiredAngle) -- the percentile difference of the desired angle to the max distance that can be traveled
    local deltaAngle = wheelAngles+((angles.Angle::number) *percentileAngle) -- the new angle relative to the time passed
    local clampedAngle = math.clamp(deltaAngle,-angles.MaxTurnAngle, angles.MaxTurnAngle) -- makes sure the angle doesn't exceed the max angle


    for i = 1, #motors do -- begins turning the wheels to the approximate angle
        local motor = motors[i]
        local invert:number = (motor:GetAttribute("InvertYAxis") and -1) or 1 -- inverts any motors with this attribute
        local turnableAttachment = motor:GetAttribute("AllowRotation")
        local fullAngle = clampedAngle * invert

        if fullAngle == fullAngle then
            if motor:IsA("Attachment") and turnableAttachment then -- rotates the attachments y axis to simulate the wheels turning
                motor.Orientation = Vector3.new(0, -fullAngle, 180) -- turns attachment to the appropriate angle for wheels 
            end
        end
    end

    
    engine:SetAttribute("CurrentWheelAngle", clampedAngle) -- saves the current angle of the wheels
end


--[[
    * sets current speed for all motors for driving the car
]]
function motorMethods:setCarSpeed(engine:Configuration, motors:{AngularVelocity}, speed: number)
    for i = 1, #motors do
        local motor = motors[i]
        local invert:number = (motor:GetAttribute("InvertSpeed") and -1) or 1 -- allows the speed of the car to be inverted


        if motor:IsA("AngularVelocity") then
            motor.AngularVelocity = Vector3.new(speed*invert, 0, 0) -- angular velocity constraint only takes vector3
        end
    end

    engine:SetAttribute("CurrentSpeed", speed) -- adjusts the current speed of the car
end


--[[
    * returns all constraints in the car
    * returns all attachments within the car
]]
function motorMethods:getAllConstraints(car:_types.Car):_types.CarConstraints
    local carDescendants = car:GetDescendants() -- all descendants of the car
    local constraints = { -- the variables follow the names of the constraints class name
        AlignPosition = {},
        AlignOrientation = {},
        AngularVelocity = {},
        Attachment = {},
        CylindricalConstraint = {},
        SpringConstraint = {},
    }

    
    for i = 1, #carDescendants do
        local descendant = carDescendants[i]
        local constraintTable = constraints[descendant.ClassName] -- checks to see if the class is valid in the table

        if constraintTable then
            constraintTable[#constraintTable+1] = descendant -- adds the descendant to its respective constraint table
        end
    end

    return constraints
end



--[[
    * determines which direction to drive in (forward or backward)
    * also determines the speed effected by acceleration
    * translates the calculated speed relative to the time passed
    * sets car's new speed
]]
function motorMethods:driveToTarget(car:_types.Car, motors:{AngularVelocity}, passedTime:number)
    local engine = car.Engine
    local seat = car.Seat

    local targetPosition:Vector3 = engine:GetAttribute("Target")
    local acceleration:number = engine:GetAttribute("AccelerationSpeed") -- the acceleration speed in seconds
    local maxSpeed:number = engine:GetAttribute("MaxSpeed") -- the max speed able to be driven
    local currentSpeed:number = engine:GetAttribute("CurrentSpeed")

    local seatCFrame = seat.CFrame
    local directionToTarget = (targetPosition-seatCFrame.Position).Unit -- the direction from seats position to the target
    local direction:number = seatCFrame.LookVector:Dot(directionToTarget)+.75 -- the .25 is to make the angle closer to the back vector and give a more forward FOV (+45 more degrees)
    local driveMode = ((direction < 0 and -1) or 1)::number -- tells if the car should move forward or backward
    
    local newSpeedTranslation:number = self:disFromTimeSpeed(passedTime, acceleration) -- the max distance needed to be traveled
    local deltaSpeed = currentSpeed + (newSpeedTranslation * driveMode) -- the current speed relative to time passed
    local speed:number = math.clamp(deltaSpeed, -maxSpeed, maxSpeed) -- prevents speed from exceeding the max speed
    
    self:setCarSpeed(engine, motors,  speed) -- finally sets the cars speed
end





return motorMethods