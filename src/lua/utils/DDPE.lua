require("utils.vector")
local ffi = require("ffi")

ffi.cdef[[
void *DDPE_new(double angleRad, double leftDistance, double rightDistance, double x, double y, double rotationRad);
void DDPE_SetVisionMeasurementStdDevs(void *_this, double x, double y, double headingRad);
void DDPE_ResetPosition(void *_this, double angleRad, double leftDistance, double rightDistance, double x, double y, double rotationRad);
double DDPE_GetEstimatedX(void *_this);
double DDPE_GetEstimatedY(void *_this);
double DDPE_GetEstimatedRotationRad(void *_this);
void DDPE_AddVisionMeasurement(void *_this, double x, double y, double angleRad, double timestampSeconds);
void DDPE_Update(void *_this, double angleRad, double leftDistance, double rightDistance);
]]

---@class DDPE
---@field _this DDPE
DDPE = {}

---@param angleRad number
---@param leftDistance number
---@param rightDistance number
---@param x number
---@param y number
---@param rotationRad number
---@return DDPE
function DDPE:new(angleRad, leftDistance, rightDistance, x, y, rotationRad)
	leftDistance = leftDistance or 0
	rightDistance = rightDistance or 0
	x = x or 0
	y = y or 0
	rotationRad = rotationRad or 0

    local instance = {
        _this = ffi.C.DDPE_new(angleRad, leftDistance, rightDistance, x, y, rotationRad),
    }
    setmetatable(instance, self)
    self.__index = self
    return instance
end

---@param x number
---@param y number
---@param headingRad number
function DDPE:SetVisionMeasurementStdDevs(x, y, headingRad)
	ffi.C.DDPE_SetVisionMeasurementStdDevs(self._this, x, y, headingRad)
end

---@param angleRad number
---@param leftDistance number
---@param rightDistance number
---@param x number
---@param y number
---@param rotationRad number
function DDPE:ResetPosition(angleRad, leftDistance, rightDistance, x, y, rotationRad)
	ffi.C.DDPE_ResetPosition(self._this, angleRad, leftDistance, rightDistance, x, y, rotationRad)
end

---@return number x, number y, number rotationRad
function DDPE:GetEstimatedPosition()
	return ffi.C.DDPE_GetEstimatedX(self._this), ffi.C.DDPE_GetEstimatedY(self._this), ffi.C.DDPE_GetEstimatedRotationRad(self._this)
end

---@param x number
---@param y number
---@param angleRad number
---@param timestampSeconds number
function DDPE:AddVisionMeasurement(x, y, angleRad, timestampSeconds)
	ffi.C.DDPE_AddVisionMeasurement(self._this, x, y, angleRad, timestampSeconds)
end

-- call this every loop
---@return number x, number y, number rotationRad
function DDPE:Update(angleRad, leftDistance, rightDistance)
	ffi.C.DDPE_Update(self._this, angleRad, leftDistance, rightDistance)

	return self:GetEstimatedPosition()
end