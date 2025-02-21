--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")


-- modules
local _types = require(ReplicatedStorage.Types)


-- variables
local module = {}

module.MaxLinearVelocity = 500

module.RayCastingDistance = 15
module.TimeOffGround = 5

module.FreeMovement = 5
module.FreeMovementTime = 20


return module