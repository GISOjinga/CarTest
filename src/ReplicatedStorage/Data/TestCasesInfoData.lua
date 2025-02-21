--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")


-- modules
local _types = require(ReplicatedStorage.Types)


-- variables
local module = {}

module.AlignOrientation = "Wheel turning: Wheel turn angle must hit both extremes to fully pass (Min: -90, Max: 90)\n\nExtreme turning: When a wheel turns past the max test case fails"

module.CylindricalConstraint = "Exceeding Cylinders max length: Fails if springs length exceeds Cylindrical constraints max or min length"

module.AngularVelocity = "Car wheels rotating: Fails if a car wheel doesn't turn on its x axis\n\nCar reversing: Fails if car never travels in reverse\n\nCars velocity speed: Fails if the linear speed of the car is too extreme"

module.AlignPosition = "Align Rigidiy: Fails if the constraint's attachments disconnect"

module.SpringConstraint = "Spring Changes: Fails if springs length never changes (highest, lowest)"

module.SevereTestCases = "Lap Completion: Fails if all 3 laps weren't completed successfully\n\nCar moved freely: Fails if the car stops moving within 5 studs of the previous position for 20 seconds\n\nTime off ground: Fails if the ray cast doesn't reach the floor (5 seconds duration)"




return module