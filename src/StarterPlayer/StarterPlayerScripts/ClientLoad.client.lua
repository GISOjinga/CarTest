for _,v in ipairs(script.Parent:WaitForChild("Controllers"):GetDescendants()) do
	if v:IsA("ModuleScript") and v.Name:match("Controller$") then
		local required = require(v)
		
		if required.Init then
			task.spawn(required.Init,required)
		end
	end
end


for _,v in ipairs(script.Parent:WaitForChild("Controllers"):GetDescendants()) do
	if v:IsA("ModuleScript") and v.Name:match("Controller$") then
		local required = require(v)
		
		if required.Start then
			task.spawn(required.Start,required)
		end
	end
end
