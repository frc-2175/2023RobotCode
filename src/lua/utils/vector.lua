---@class Vector
---@field x number
---@field y number
Vector = {
	__add = function(a, b)
		if type(b) == "number" then
			return Vector:new(a.x + b, a.x + b)
		elseif type(a) == "number" then
			return Vector:new(a + b.x, a + b.y)
		else
			return Vector:new(a.x + b.x, a.y + b.y)
		end
	end,
	__sub = function(a, b)
		if type(b) == "number" then
			return Vector:new(a.x - b, a.x - b)
		elseif type(a) == "number" then
			return Vector:new(a - b.x, a - b.y)
		else
			return Vector:new(a.x - b.x, a.y - b.y)
		end
	end,
	__mul = function(a, b)
		if type(a) == "number" then
			return Vector:new(a * b.x, a * b.y)
		else
			return Vector:new(a.x * b, a.y * b)
		end
	end,
	__div = function(a, b)
		return Vector:new(a.x / b, a.y / b)
	end,
	__unm = function(a)
		return Vector:new(-a.x, -a.y)
	end,
	__eq = function(a, b)
		return a.x == b.x and a.y == b.y
	end,
	__newindex = function(a, b, c)
		error("You cannot mutate a vector, it breaks stuff")
	end,
	__tostring = function(a)
		return "Vector: {" .. a.x .. ", " .. a.y .. "}"
	end,
}

--- Creates a new vector, with two values. The parameters `x` and `y` are
--- used to represent a point/vector of the form `(x,y)`
---
--- Examples:
---  - `myVector = Vector:new(3, 4)` creates a new vector, `(3, 4)`.
---  - `myVector.x` is `3`.
---  - `myVector.y` is `4`.
---@param x number
---@param y number
---@return Vector
function Vector:new(x, y)
	local v = {
		x = x,
		y = y,
	}
	setmetatable(v, self)
	self.__index = self

	return v
end

--- Returns the length of the vector.
---
--- Examples:
---  - `myVector = Vector:new(3, 4)` creates a new vector, `(3, 4)`.
---  - `myVector:length()` is `5.0`.
---@return number Length
function Vector:length()
	return math.sqrt(self.x * self.x + self.y * self.y)
end

--- Returns the vector, except scaled so that its length is 1
---
--- Examples:
---  - `myVector = Vector:new(3, 4)` creates a new vector, `(3, 4)`.
---  - `myVector:normalized()` returns a new vector, `(0.6, 0.8)`.
---  - `myVector:normalized():length()` will always be 1.
---@return Vector
function Vector:normalized()
	return self / self:length()
end

--- Returns the vector rotated `radAng` radians
---
--- Examples:
---  - `myVector = Vector:new(3, 4)` creates a new vector, `(3, 4)`.
---  - `myVector:rotate(math.rad(180))` returns a new vector, `(-3, -4)`.
---@param radAng number
---@return Vector
function Vector:rotate(radAng)
	return Vector:new(
	    (self.x * math.cos(radAng)) - (self.y * math.sin(radAng)),
	    (self.x * math.sin(radAng)) + (self.y * math.cos(radAng))
	)
end

---@param vec Vector
---@return number
function Vector:dot(vec)
	return self.x * vec.x + self.y * vec.y
end

test("Vector Tests :D", function(t)
	t:assertEqual(Vector:new(1, 2) + Vector:new(3, 4), Vector:new(4, 6))
	t:assertEqual(Vector:new(1, 2) - Vector:new(3, 4), Vector:new(-2, -2))
	t:assertEqual(Vector:new(1, 2) * 3, Vector:new(3, 6))
	t:assertEqual(3 * Vector:new(1, 2), Vector:new(3, 6))
	t:assertEqual(Vector:new(4, 6) / 2, Vector:new(2, 3))
	t:assertEqual(-Vector:new(1, 2), Vector:new(-1, -2))
	t:assertEqual(Vector:new(3, 4) == Vector:new(3, 4), true)
	t:assertEqual(Vector:new(3, 4):length(), 5)
	t:assertEqual(Vector:new(3, 4):normalized(), Vector:new(0.6, 0.8))

	-- strict equality is not what we want for this test
	do
		local actual = Vector:new(1, 2):rotate(math.pi / 2)
		t:assertEqual(actual.x, -2)
		t:assertEqual(actual.y, 1)
	end
end)
