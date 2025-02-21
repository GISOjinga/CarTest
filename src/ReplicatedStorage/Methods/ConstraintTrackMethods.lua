--!strict
--[[
    * this module will track all active constraints on the car (non visually)
    * uses the changes in time to find significant changes to the constraints
    * will fire events to let others know of constraint registration or changes
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")


-- modules
local _types = require(ReplicatedStorage.Types)
local trackingAlgorithms = require(ReplicatedStorage.Methods.TrackingAlgorithms) -- functions used for tracking constraints changes


-- variables
local constraintChanged = Instance.new("BindableEvent") -- event for constraint changes
local constraintRegistered = Instance.new("BindableEvent") -- event for constraint registration

local module = {
    ConstraintRegistered = constraintRegistered.Event::_types.ConstraintEventParameters, -- fires when a constraint is registered
    ConstraintChanged = constraintChanged.Event::_types.ConstraintEventParameters, -- fires when a constraint is changed
}


-- allows the constraints info to save newly created info
function module:__savePreviousInfo(constraintInfo:_types.ConstraintTrackerInfo, isConstraintActive:boolean)
    local constraint:Constraint = constraintInfo.Constraint::any

    if constraint:IsA("SpringConstraint") and isConstraintActive then -- saves new wheel angle if the previous angular difference is significant
        constraintInfo.Info.OldLength = constraint.CurrentLength
        
    elseif constraint:IsA("AlignOrientation") and isConstraintActive then -- saves new wheel angle if the previous angular difference is significant
        constraintInfo.Info.OldWheelAngle = constraintInfo.Engine:GetAttribute("CurrentWheelAngle")

    elseif constraint:IsA("AngularVelocity") and isConstraintActive then -- saves new current speed if the previous current speed is significant
        constraintInfo.Info.OldSpeed = constraintInfo.Engine:GetAttribute("CurrentSpeed")

    elseif constraint:IsA("CylindricalConstraint") then  -- saves the wheels angle
        constraintInfo.Info.OldPosition = constraint.CurrentPosition
    end
end


--[[
    * determines if there was a change
    * if there is then fires the changed event
]]
function module:__track(car:_types.Car, constraintInfo:_types.ConstraintTrackerInfo)
    local newTime = os.clock()
    local timePassed = newTime - (constraintInfo.Info.ActivationTime or newTime) -- the time passed since the last check
    local constraint = constraintInfo.Constraint
    local isConstraintActive = trackingAlgorithms[constraint.ClassName](constraintInfo, timePassed) -- boolean telling you if the constraint is active

    if constraintInfo.Active ~= isConstraintActive then
        constraintInfo.Info.ActivationTime = os.clock() -- saves the new activation time
        constraintInfo.Active = isConstraintActive -- lets viewer know if constraint is active
        constraintChanged:Fire(car, constraintInfo, isConstraintActive, timePassed) -- fires when the constraint changed
    end

    self:__savePreviousInfo(constraintInfo, isConstraintActive)
end




-- finds all constraints and saves them into a table to be tracked
function module.trackCar(car:_types.Car)
    local validConstraints = {"AngularVelocity", "AlignPosition", "AlignOrientation", "CylindricalConstraint", "SpringConstraint"}
    local startTime = os.clock()
    local newTime = startTime
    local carDescendants:{Instance} = car:GetDescendants() -- all descendants of the car
    local constraints:{_types.ConstraintTrackerInfo} = {}
    
    for i = 1, #carDescendants do -- marks down all the constraints in the car
        local constraint:Constraint = carDescendants[i]::any -- the constraint instance (may not be a constraint put if statements)
        local constraintInfo:_types.ConstraintTrackerInfo

        if table.find(validConstraints, constraint.ClassName) then -- sees if the constraint is in the list of valid constraints

            constraintInfo = {Constraint = constraint, Engine = car.Engine, Active = false, Info = {}}
            constraints[#constraints+1] = constraintInfo -- adds the constraint to saved constraints
            module:__savePreviousInfo(constraintInfo, true)
            
            constraintRegistered:Fire(car, constraintInfo, constraintInfo.Active, 0)
        end
    end


    while car.Parent and workspace:GetAttribute("StartTest") do -- begins tracking the constraints
        newTime = os.clock()

        for i = 1, #constraints do
            local constraintInfo = constraints[i]

            module:__track(car, constraintInfo) -- runs the track function
        end

        startTime = newTime -- saves the new time
        task.wait()
    end

    return true
end




return module