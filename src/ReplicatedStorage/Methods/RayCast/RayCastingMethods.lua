--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Visualize = require(ReplicatedStorage.Methods.RayCast.RayVisualizeMethods)
local Methods = {}

local function CastRay(Origin: Vector3, Direction: Vector3, RayInfo: RayInfo?)
	local RayParams = RaycastParams.new()
	local rayCastFilterTypes = Enum.RaycastFilterType

	if RayInfo then
		RayParams.FilterType = if RayInfo.Include
			then rayCastFilterTypes.Include
			elseif RayInfo.Exclude then rayCastFilterTypes.Exclude
			else RayParams.FilterType

				
		RayParams.FilterDescendantsInstances = RayInfo.Exclude
			or RayInfo.Include
			or RayParams.FilterDescendantsInstances
	end
	return workspace:Raycast(Origin, Direction, RayParams)
end


function Methods:CastRay(Origin: Vector3, Direction: Vector3, RayInfo2: RayInfo?)
	local RayInfo = RayInfo2 :: RayInfo
	local RayResult: Results

	local function Run()
		RayResult = (
			CastRay(Origin, Direction, RayInfo)
			or { Position = Origin + Direction, Normal = -Direction.Unit, Distance = Direction.Magnitude }
		) :: Results

		if RayInfo and RayInfo.Visualize then
			Visualize:VisualizeRay(Origin, RayResult.Position, 0.5)
			Visualize:MarkPart(RayResult.Instance, 0.5)
		end

		return
	end

	Run()
	return RayResult
end



type Results = (RaycastResult) & { Position: Vector3, Normal: Vector3, Distance: number }
type RayInfo = {
	Include: { any }?,
	Exclude: { any }?,
	Visualize: boolean?,
}

return Methods
