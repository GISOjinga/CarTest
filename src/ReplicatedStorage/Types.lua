-- the ui that holds test cases
export type TestCaseHolder = typeof(game.StarterGui.Logger.TestCases)


-- the physical vehicle
export type Car = typeof(workspace.BlueCar)


-- the info that is being tracked
export type ConstraintTrackerInfo = {Constraint:Constraint, Engine:Configuration, Info:{[any]:any}, Active:boolean}

-- the function for the connection of the event
export type ConstraintEventFunction = (
    car:Car,
    constraintInfo:ConstraintTrackerInfo,
    isMotorActive:boolean,
    timePassed:number
)->()

-- when connecting to the event changed for the constraint
export type ConstraintEventParameters = RBXScriptConnection & {Connect:(ConstraintEventParameters, ConstraintEventFunction)->(RBXScriptConnection)}


-- car constraints type
export type CarConstraints = {
    AlignPosition:{AlignPosition},
    AlignOrientation:{AlignOrientation},
    AngularVelocity:{AngularVelocity},
    Attachment:{Attachment},
    CylindricalConstraint:{CylindricalConstraint},
    SpringConstraint:{SpringConstraint},
}

return {}