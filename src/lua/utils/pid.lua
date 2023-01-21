---@class PIDController
---@field kp number
---@field ki number
---@field kd number
---@field integral number
---@field previousError number
---@field previousTime number
---@field dt number
---@field shouldRunIntegral boolean
PIDController = {}

---@param p number
---@param i number
---@param d number
---@return PIDController
function PIDController:new(p, i, d)
	local pid = {
		kp = p,
		ki = i,
		kd = d,
		integral = 0,
		previousError = nil,
		previousTime = 0,
		dt = 0,
		shouldRunIntegral = false,
	}
	setmetatable(pid, self)
	self.__index = self

	return pid
end

---@param time number
function PIDController:clear(time)
	self.dt = 0
	self.previousTime = time
	self.integral = 0
	self.previousError = nil
	self.shouldRunIntegral = false
end

---@param input number
---@param setpoint number
---@param thresh number
---@return number
function PIDController:pid(input, setpoint, thresh)
	local threshold = thresh or 0
	local error = setpoint - input
	local p = error * self.kp
	local i = 0
	
	if self.shouldRunIntegral then
		if threshold == 0 or (input < (threshold + setpoint) and input > (setpoint - threshold)) then
			self.integral = self.integral + self.dt * error
		else
			self.integral = 0
		end
	else
		self.shouldRunIntegral = true
	end

	local d

	if self.previousError == nil or self.dt == 0 then
		d = 0
	else
		d = ((error - self.previousError) / self.dt) * self.kd
	end

	self.previousError = error

	return p + i + d
end

---@param time number
function PIDController:updateTime(time)
	self.dt = time - self.previousTime
	self.previousTime = time
end
