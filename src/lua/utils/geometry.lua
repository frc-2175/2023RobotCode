---@class Translate3d
---@field x number
---@field y number
---@field z number
Translate3d = {
	__add = function (a, b)
		return Translate3d:new(a.x + b.x, a.y + b.y, a.z + b.z)
	end
}

---@param x number
---@param y number
---@param z number
---@return Translate3d
function Translate3d:new(x, y, z)
	local instance = {
		x = x,
		y = y,
		z = z,
	}
	setmetatable(instance, self)
	self.__index = self

	return instance
end

---@class Rotate3d
---@field x number
---@field y number
---@field z number
Rotate3d = {}

---@param x number
---@param y number
---@param z number
---@return Rotate3d
function Rotate3d:new(x, y, z)
	local instance = {
		x = x,
		y = y,
		z = z,
	}
	setmetatable(instance, self)
	self.__index = self

	return instance
end

---@class Transform3d
---@field position Translate3d
---@field rotation Rotate3d
Transform3d = {}

---@param position Translate3d|nil
---@param rotation Rotate3d|nil
---@return Transform3d
function Transform3d:new(position, rotation)
	position = position or Translate3d:new(0, 0, 0)
	rotation = rotation or Rotate3d:new(0, 0, 0)
	
	local instance = {
		position = position,
		rotation = rotation,
	}
	setmetatable(instance, self)
	self.__index = self

	return instance
end

