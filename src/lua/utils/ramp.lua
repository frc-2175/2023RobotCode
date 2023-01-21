require("utils.math")

---@class Ramp
---@field currentSpeed number
---@field maxAccel number
---@field maxDecel number
Ramp = {}

--- Creates a new ramp, with a time in seconds to accelerate, `timeToMax`,
--- and a time in seconds to stop, `timeToStop`.
---
--- Examples:
---  - `myRamp = NewRamp(0.5, 1)` creates a new ramp setup that takes
---&nbsp;0.5 seconds to accelerate to max and 1 second to decelerate to stop.
---@param timeToMax number
---@param timeToStop number
---@return Ramp
function Ramp:new(timeToMax, timeToStop)
	local r = {
		currentSpeed = 0,
		maxAccel = 1 / (50 * timeToMax),
		maxDecel = 1 / (50 * timeToStop),
	}
	setmetatable(r, self)
	self.__index = self

	return r
end

---@param curr number
---@param targ number
---@param accel number
---@param decel number
---@return number rampedValue
function doGrossRampStuff(curr, targ, accel, decel)
	if curr == 0 or (curr > 0 and targ > curr) or (curr < 0 and targ < curr) then
		-- accelerating
		change = math.min(math.abs(curr - targ), accel) * sign(targ - curr)
		curr = curr + change
	elseif (curr > 0 and targ < curr) or (curr < 0 and targ > curr) then
		-- decelerating
		change = math.min(math.abs(curr - targ), decel) * sign(targ - curr)
		curr = curr + change
	end

	return curr
end

--- Updates and returns the new speed, limited by the maximum acceleration and deceleration.
---@param targetSpeed number
---@return number Speed
function Ramp:ramp(targetSpeed)
	self.currentSpeed = doGrossRampStuff(self.currentSpeed, targetSpeed, self.maxAccel, self.maxDecel)
	return self.currentSpeed
end
