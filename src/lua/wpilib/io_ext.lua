local ffi = require("ffi")
require("utils.math")

local deadvalue = 0.01

---@return number
function Joystick:getX()
	return deadband(ffi.C.Joystick_GetX(self._this), deadvalue)
end

---@return number
function Joystick:getY()
	return -deadband(ffi.C.Joystick_GetY(self._this), deadvalue)
end

---@return number
function Joystick:getZ()
	return deadband(ffi.C.Joystick_GetZ(self._this), deadvalue)
end

---@return number
function Joystick:getThrottle()
	local x = ffi.C.Joystick_GetThrottle(self._this)
	return -0.5 * x + 0.5
end

---@return number
function Joystick:getLeftStickX()
	return deadband(ffi.C.Joystick_GetRawAxis(self._this, 0))
end

---@return number
function Joystick:getLeftStickY()
	return -deadband(ffi.C.Joystick_GetRawAxis(self._this, 1))
end

---@return number
function Joystick:getRightStickX()
	return deadband(ffi.C.Joystick_GetRawAxis(self._this, 4))
end

---@return number
function Joystick:getRightStickY()
	return -deadband(ffi.C.Joystick_GetRawAxis(self._this, 5))
end

---@return number
function Joystick:getLeftTriggerAmount()
	return ffi.C.Joystick_GetRawAxis(self._this, 2)
end

---@return number
function Joystick:getRightTriggerAmount()
	return ffi.C.Joystick_GetRawAxis(self._this, 3)
end
