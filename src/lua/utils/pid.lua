---@class PIDController
---@field kp number
---@field ki number
---@field kd number
---@field integral number
---@field previousError number
---@field previousOutput number
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
		kp = p or 0,
		ki = i or 0,
		kd = d or 0,
		integral = 0,
		previousError = nil,
		previousOutput = nil,
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
	self.previousOutput = nil
	self.shouldRunIntegral = false
end

---@param input number
---@param setpoint number
---@param thresh number
---@return number
function PIDController:pid(input, setpoint, thresh, maxChange, maxOutput)
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

	local output = p + i + d

	if self.previousOutput ~= nil and maxChange ~= nil then
		output = self.previousOutput + clampMag(output - self.previousOutput, 0, maxChange / 50)
	end

	if maxOutput ~= nil then
		output = clampMag(output, 0, maxOutput)
	end

	self.previousOutput = output

	return output
end

---@param time number
function PIDController:updateTime(time)
	self.dt = time - self.previousTime
	self.previousTime = time
end
