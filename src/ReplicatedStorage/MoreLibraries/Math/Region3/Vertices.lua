--!strict

-- CONSTANTS

local PI2 = math.pi*2
local PHI = (1 + math.sqrt(5)) / 2

local RIGHT 	= Vector3.new(1, 0, 0)
local UP 		= Vector3.new(0, 1, 0)
local LEFT 		= Vector3.new(-1, 0, 0)


local CORNERS = {
	Vector3.new(1, 1, 1);
	Vector3.new(-1, 1, 1);
	Vector3.new(-1, 1, -1);
	Vector3.new(1, 1, -1);
	Vector3.new(1, -1, 1);
	Vector3.new(-1, -1, 1);
	Vector3.new(-1, -1, -1);
	Vector3.new(1, -1, -1);
}

-- VERTICES INDEX ARRAYS

local BLOCK = {1, 2, 3, 4, 5, 6, 7, 8}
local WEDGE = {1, 2, 5, 6, 7, 8}
local CornerWedge = {4, 5, 6, 7, 8}

-- VERTICES FUNCTIONS

local function fromIndexArray(array)
	local output = {}
	for i = 1, #array do
		output[i] = CORNERS[array[i]]
	end
	return output
end

local function cylinder(n)
	local output = {}
	local arc = PI2 / n
	for i = 1, n do
		local vi = CFrame.fromAxisAngle(RIGHT, i*arc) * UP
		output[i] = RIGHT + vi
		output[n + i] = LEFT + vi
	end
	return output
end

local function icoSphere(n)
	local vectors = {
		Vector3.new(-1,  PHI, 0),
		Vector3.new(1,  PHI, 0),
		Vector3.new(-1, -PHI, 0),
		Vector3.new(1, -PHI, 0),
		
		Vector3.new(0, -1,  PHI),
		Vector3.new(0,  1,  PHI),
		Vector3.new(0, -1, -PHI),
		Vector3.new(0,  1, -PHI),
		
		Vector3.new(PHI, 0, -1),
		Vector3.new(PHI, 0,  1),
		Vector3.new(-PHI, 0, -1),
		Vector3.new(-PHI, 0,  1)
	}
	
	local indices = {
		1, 12, 6,
		1, 6, 2,
		1, 2, 8,
		1, 8, 11,
		1, 11, 12,
		
		2, 6, 10,
		6, 12, 5,
		12, 11, 3,
		11, 8, 7,
		8, 2, 9,
		
		4, 10, 5,
		4, 5, 3,
		4, 3, 7,
		4, 7, 9,
		4, 9, 10,
		
		5, 10, 6,
		3, 5, 12,
		7, 3, 11,
		9, 7, 8,
		10, 9, 2
	}
	
	local splits = {}
	
	local function split(i:any, j)
		local key = i < j and (i .. "," .. j) or (j .. "," .. i)
		
		if (not splits[key]) then
			vectors[#vectors+1] = (vectors[i] + vectors[j]) / 2
			splits[key] = #vectors
		end
		
		return splits[key]
	end
	
	for _ = 1, n do
		for  i = #indices, 1, -3 do
			local v1, v2, v3 = indices[i - 2], indices[i - 1], indices[i]
			local a = split(v1, v2)
			local b = split(v2, v3)
			local c = split(v3, v1)
			
			indices[#indices+1] = v1
			indices[#indices+1] = a
			indices[#indices+1] = c
			
			indices[#indices+1] = v2
			indices[#indices+1] = b
			indices[#indices+1] = a
			
			indices[#indices+1] = v3
			indices[#indices+1] = c
			indices[#indices+1] = b
			
			indices[#indices+1] = a
			indices[#indices+1] = b
			indices[#indices+1] = c
			
			table.remove(indices, i)
			table.remove(indices, i - 1)
			table.remove(indices, i - 2)
		end
	end
	
	-- normalize
	for i = 1, #vectors do
		vectors[i] = vectors[i].Unit
	end
	
	return vectors
end

-- Useful functions

local function vectorShape(cf, size2:any, array:any)
	local output = {}
	for i = 1, #array do
		output[i] = cf:PointToWorldSpace(array[i] * size2)
	end
	return output
end

local function getCentroidFromSet(set:any)
	local sum = set[1]
	for i = 2, #set do
		sum = sum + set[2]
	end
	return sum / #set
end

local function classify(part):string|nil
	if (part.ClassName == "Part") then
		if (part.Shape == Enum.PartType.Block) then
			return "Block"
		elseif (part.Shape == Enum.PartType.Cylinder) then
			return "Cylinder"
		elseif (part.Shape == Enum.PartType.Ball) then
			return "Ball"
		end;
	elseif (part.ClassName == "WedgePart") then
		return "Wedge"
	elseif (part.ClassName == "CornerWedgePart") then
		return "CornerWedge"
	elseif (part:IsA("BasePart")) then -- mesh, CSG, truss, etc... just use block
		return "Block"
	end
	
	return nil
end

-- 

local BLOCK_ARRAY = fromIndexArray(BLOCK)
local WEDGE_ARRAY = fromIndexArray(WEDGE)
local CornerWedge_ARRAY = fromIndexArray(CornerWedge)
local CYLINDER_ARRAY = cylinder(20)
local SPHERE_ARRAY = icoSphere(2)

return {
	Block = function(cf, size2) return vectorShape(cf, size2, BLOCK_ARRAY) end;
	Wedge = function(cf, size2) return vectorShape(cf, size2, WEDGE_ARRAY) end;
	CornerWedge = function(cf, size2) return vectorShape(cf, size2, CornerWedge_ARRAY) end;
	Cylinder = function(cf, size2) return vectorShape(cf, size2, CYLINDER_ARRAY) end;
	Ball = function(cf, size2) return vectorShape(cf, size2, SPHERE_ARRAY) end;
	
	GetCentroid = getCentroidFromSet;
	Classify = classify;
}