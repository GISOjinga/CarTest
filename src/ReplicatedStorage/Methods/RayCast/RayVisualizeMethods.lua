--!strict
local Debris = game:GetService("Debris")
local Visualize = {}

function Visualize:VisualizeRay(origin: Vector3, position: Vector3, time: number, color2: Color3?)
	local color = color2 or Color3.fromRGB(255, 0, 0)

	local distance = (origin - position).Magnitude

	local function ballE(name: string)
		local ball = Instance.new("Part")
		ball.Name = name
		ball.Shape = Enum.PartType.Ball
		ball.Anchored = true
		ball.CanCollide = false
		ball.Color = color
		ball.Material = Enum.Material.Neon
		ball.Position = Vector3.new(-6.75, 18.5, -1.34)
		ball.Size = Vector3.new(0.25, 0.25, 0.25)

		return ball
	end

	local ray = Instance.new("Part")
	ray.Name = "Ray"
	ray.Anchored = true
	ray.CanCollide = false
	ray.Size = Vector3.new(0.1, 0.1, distance)
	ray.CFrame = CFrame.lookAt(position, origin)*CFrame.new(0, 0, -distance/2)
	ray.Color = color
	ray.Transparency = 0.7
	ray.Material = Enum.Material.Neon
	ray.Parent = workspace:WaitForChild("IgnoreFolder"):WaitForChild("Trash")

	local positionBall = ballE("Position")
	positionBall.Position = position
	positionBall.Parent = ray

	Debris:AddItem(ray, time)

	return ray
end

--[=[
    Marks a part for a set amount of time using [Highlights](https://create.roblox.com/docs/reference/engine/classes/Highlight).

    @param inst Instance
    @param time number
    @param color Color3? -- Defaults to RGB(255, 0, 0)
    @return Highlight
]=]
function Visualize:MarkPart(inst: Instance?, time: number, color2: Color3?)
	if not inst then return end
	local color = color2 or Color3.fromRGB(255, 0, 0)
	
	local highlight = Instance.new("Highlight")
	highlight.Name = "Highlight"
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.OutlineColor = color
	highlight.FillColor = color
	highlight.OutlineTransparency = 0.5
	highlight.Adornee = inst
	highlight.Parent = workspace:WaitForChild("IgnoreFolder"):WaitForChild("Trash")
	Debris:AddItem(highlight, time)

	return highlight
end


return Visualize