--!strict
local module = {}



function module:FindPartsInBoxWithWhitelist(CFrame,Size,Table,MaxAmount:number|nil)
	local overlatParam = OverlapParams.new()
	overlatParam.FilterType = Enum.RaycastFilterType.Whitelist
	overlatParam.FilterDescendantsInstances = Table
	overlatParam.MaxParts = MaxAmount or 0
	return workspace:GetPartBoundsInBox(CFrame,Size,overlatParam)
end

function module:FindPartsInBoxWithIgnoreList(CFrame,Size,Table,MaxAmount)
	local overlatParam = OverlapParams.new()
	overlatParam.FilterType = Enum.RaycastFilterType.Whitelist
	overlatParam.FilterDescendantsInstances = Table
	overlatParam.MaxParts = MaxAmount or 0
	return workspace:GetPartBoundsInBox(CFrame,Size,overlatParam)
end

function module:FindPartsInPartWithWhitelist(Part,Table,MaxAmount)
	local overlatParam = OverlapParams.new()
	overlatParam.FilterType = Enum.RaycastFilterType.Blacklist
	overlatParam.FilterDescendantsInstances = Table
	overlatParam.MaxParts = MaxAmount or 0
	return workspace:GetPartBoundsInBox(Part,overlatParam::any)
end

function module:FindPartsInPartWithIgnoreList(Part,Table,MaxAmount)
	local overlatParam = OverlapParams.new()
	overlatParam.FilterType = Enum.RaycastFilterType.Blacklist
	overlatParam.FilterDescendantsInstances = Table
	overlatParam.MaxParts = MaxAmount or 0
	return workspace:GetPartBoundsInBox(Part,overlatParam::any)
end

module.RotatedRegion = require(script.Parent.RotatedRegion3)::any

function module:FindPartsInBallWithWhitelist(CFrame,Size,Table,MaxAmount)
	local ball = module.RotatedRegion.Ball(CFrame, Size)
	return ball:FindPartsInRegion3WithWhiteList(Table,MaxAmount)
end

function module:FindPartsInBallWithIgnoreList(CFrame,Size,Table,MaxAmount)
	local ball = module.RotatedRegion.Ball(CFrame, Size)
	return ball:FindPartsInRegion3WithIgnoreList(Table,MaxAmount)
end

return module