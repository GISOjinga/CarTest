--!strict
--[[
    * this module contains functions useful for tracking constraint changes
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")


-- modules
local _types = require(ReplicatedStorage.Types)


-- types
type track = {[string]:(constraintInfo:_types.ConstraintTrackerInfo, timePassed:number)->(boolean)}

-- variables
local requiredAngularDifference = 5 -- the required angular difference for it to be registered as a change (in degrees)
local requiredSpeedDifference = 10 -- the required speed difference to be seen as a change (in studs per second)
local module:track = {}




-- measures the change in current length
module.SpringConstraint = function(constraintInfo:_types.ConstraintTrackerInfo, _timePassed:number):boolean
    local constraint = constraintInfo.Constraint::SpringConstraint
    local oldLength = constraintInfo.Info.OldLength or constraint.CurrentLength -- the active/old angle on a cylinder constraint
    
    return constraint.CurrentLength ~= oldLength
end



-- measures if the constraint is rotating (driving) or if it is steering (moving the wheels)
module.CylindricalConstraint = function(constraintInfo:_types.ConstraintTrackerInfo, _timePassed:number):boolean
    local hinge = constraintInfo.Constraint::CylindricalConstraint
    local oldPosition = constraintInfo.Info.OldPosition or hinge.CurrentPosition -- the active/old angle on a cylinder constraint
    
    return hinge.CurrentPosition ~= oldPosition
end


-- measures if the change in speed has passed the threshold
module.AngularVelocity = function(constraintInfo:_types.ConstraintTrackerInfo, _timePassed:number):boolean
    local engine = constraintInfo.Engine
    local speedDifference = math.abs(constraintInfo.Info.OldSpeed - engine:GetAttribute("CurrentSpeed")) -- difference between old and new speed
    
    return speedDifference > requiredSpeedDifference -- returns true if the new difference breaks the threshold
end

-- measures if the constraints attachments are evenly positioned
module.AlignPosition = function(constraintInfo:_types.ConstraintTrackerInfo, _timePassed:number):boolean
    local constraint = constraintInfo.Constraint::CylindricalConstraint
    local attachment0 = constraint.Attachment0
    local attachment1 = constraint.Attachment1
    
    return (attachment0 and attachment1 and attachment0.WorldPosition ~= attachment1.WorldPosition)::boolean -- checks if the positions are aligned
end


-- measures how long the wheels angles have exceeded the required angular difference
module.AlignOrientation = function(constraintInfo:_types.ConstraintTrackerInfo, _timePassed:number):boolean
    local engine = constraintInfo.Engine
    local constraint = constraintInfo.Constraint::AlignOrientation
    local wheelAngle = engine:GetAttribute("CurrentWheelAngle")
    

    if constraint.Mode == Enum.OrientationAlignmentMode.OneAttachment then -- for if the attachment is active on one constraint
        return true
    end

    return math.abs(wheelAngle) > requiredAngularDifference -- if the wheels old angle exceeds the required angular difference
end




return module