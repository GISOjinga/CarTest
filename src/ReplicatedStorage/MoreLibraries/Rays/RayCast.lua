--!strict

local Visualize = require(script.Parent.Visualize)
local Methods = {}

local function CastRay(Origin: Vector3, Direction: Vector3, RayInfo: RayInfo?)
	local RayParams = RaycastParams.new()
	if RayInfo then
		RayParams.FilterType = if RayInfo.Whitelist
			then Enum.RaycastFilterType.Whitelist
			elseif RayInfo.Blacklist then Enum.RaycastFilterType.Blacklist
			else RayParams.FilterType
		RayParams.FilterDescendantsInstances = RayInfo.Blacklist
			or RayInfo.Whitelist
			or RayParams.FilterDescendantsInstances
	end
	return workspace:Raycast(Origin, Direction, RayParams)
end

local function RequirementCheck(result: Results, Constraints: Constraints)
	if result.Instance then
		if Constraints.CustomCheck and (not Constraints.CustomCheck(result.Instance, Constraints)) then -->> Custom check didn't pass it
			return false
		end

		if Constraints.Size then -->> Size constraints didn't pass it
			local InstanceSize = (result.Instance :: BasePart).Size.Magnitude
			if Constraints.Size.Max and InstanceSize > Constraints.Size.Max then
				return false
			elseif Constraints.Size.Min and InstanceSize < Constraints.Size.Min then
				return false
			end
		end
	end

	return true
end

function Methods:CastRay(Origin: Vector3, Direction: Vector3, RayInfo2: RayInfo?)
	local RayInfo = RayInfo2 :: RayInfo

	local RayResult: Results

	local function Run()
		RayResult = (
			CastRay(Origin, Direction, RayInfo)
			or { Position = Origin + Direction, Normal = -Direction.Unit, Distance = Direction.Magnitude }
		) :: Results

		local Check
		do
			if RayInfo.Constraints then
				Check = RequirementCheck(RayResult, RayInfo.Constraints)
			end
		end

		if RayInfo and RayInfo.Visualize then
			local Color = if Check then Color3.new(0.262745, 1, 0.14902) else nil
			Visualize:VisualizeRay(Origin, RayResult.Position, 0.5, Color)
			Visualize:MarkPart(RayResult.Instance, 0.5, Color)
		end

		--print(RayResult.Instance)
		if RayInfo.Constraints then
			if not Check then
				if RayResult then
					Direction -= (Origin - RayResult.Position)
					Origin = RayResult.Position + Direction.Unit
				end
				RayResult = nil :: any
				Run()
			else
				return
			end
		else
			return
		end
	end
	Run()

	return RayResult
end

type Results = (RaycastResult) & { Position: Vector3, Normal: Vector3, Distance: number }
type Constraints = {
	CustomCheck: ((Instance: Instance, Constraints: Constraints) -> (boolean))?,
	Size: { Min: number?, Max: number? }?,
}

type RayInfo = {
	Whitelist: { Instance }?,
	Blacklist: { Instance }?,
	Visualize: boolean?,

	Constraints: Constraints?,
}

return Methods
