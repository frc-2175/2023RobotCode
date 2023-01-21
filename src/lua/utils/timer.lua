require("wpilib.time")

---@class Timer
---@field startTime number
Timer = {}

---@return Timer
function Timer:new()
	local o = {}
	setmetatable(o, self)
	self.__index = self

	return o
end

function Timer:start()
	self.startTime = getFPGATimestamp()
	return self
end

---@return number
function Timer:getElapsedTimeSeconds()
	local elapsed = 0
	if self.startTime then
		elapsed = getFPGATimestamp() - self.startTime
	end
	return elapsed
end
