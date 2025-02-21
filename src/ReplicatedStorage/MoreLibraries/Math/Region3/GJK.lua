--!strict

local MAX_TRIES = 20
local ZERO3 = Vector3.new(0, 0, 0)

-- Class

local GJK = {}
GJK.__index = GJK

-- Private Functions

local function tripleProduct(a:Vector3, b:Vector3, c:Vector3)
	return b * c:Dot(a) - a * c:Dot(b)
end

local function containsOrigin(self, simplex:{Vector3}, Direction):(boolean, Vector3|nil)
	local a = simplex[#simplex]
	local ao = -a

	if (#simplex == 4) then
		local b:Vector3, c:Vector3, d:Vector3 = simplex[3], simplex[2], simplex[1]
		local ab:Vector3, ac:Vector3, ad:Vector3 = b - a, c - a, d - a
		local abc, acd, adb = ab:Cross(ac), ac:Cross(ad), ad:Cross(ab)
		
		abc = abc:Dot(ad) > 0 and -abc or abc
		acd = acd:Dot(ab) > 0 and -acd or acd
		adb = adb:Dot(ac) > 0 and -adb or adb
		
		if (abc:Dot(ao) > 0) then
			table.remove(simplex, 1)
			Direction = abc
		elseif (acd:Dot(ao) > 0) then
			table.remove(simplex, 2)
			Direction = acd
		elseif (adb:Dot(ao) > 0) then
			table.remove(simplex, 3)
			Direction = adb
		else
			return true
		end
	elseif (#simplex == 3) then
		local b, c = simplex[2], simplex[1]
		local ab, ac = b - a, c - a
		
		local abc = ab:Cross(ac)
		local abPera = tripleProduct(ac, ab, ab).Unit
		local acPera = tripleProduct(ab, ac, ac).Unit
		
		if (abPera:Dot(ao) > 0) then
			table.remove(simplex, 1)
			Direction = abPera
		elseif (acPera:Dot(ao) > 0) then
			table.remove(simplex, 2)
			Direction = acPera
		else
			local isV3 = ((a - a) == ZERO3)
			if (not isV3) then
				return true
			else
				Direction = abc:Dot(ao) > 0 and abc or -abc
			end
		end
	else
		local b = simplex[1]
		local ab = b - a
		local bcPera = tripleProduct(ab, ao, ab).Unit
		Direction = bcPera
	end
	
	return false, Direction
end

-- Public Constructors

function GJK.new(SetA, SetB, CentroidA, CentroidB, SupportA, SupportB)
	local self = setmetatable({}, GJK)
	
	self.SetA = SetA
	self.SetB = SetB
	self.CentroidA = CentroidA
	self.CentroidB = CentroidB
	self.SupportA = SupportA
	self.SupportB = SupportB

	return self
end

-- Public Methods

function GJK:IsColliding()
	self = self::any
	local Direction = (self.CentroidA - self.CentroidB).Unit
	local simplex = {self.SupportA(self.SetA, Direction) - self.SupportB(self.SetB, -Direction)}
	
	Direction = -Direction
	
	for i = 1, MAX_TRIES do
		table.insert(simplex, self.SupportA(self.SetA, Direction) - self.SupportB(self.SetB, -Direction))
		
		if (simplex[#simplex]:Dot(Direction) <= 0) then
			return false
		else
			local passed, newDirection = containsOrigin(self, simplex, Direction)
			
			if (passed) then
				return true
			end
			
			Direction = newDirection
		end
	end
	
	return false
end

--

return GJK