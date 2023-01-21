local ffi = require("ffi")

local function toSpeedController(motor)
	if getmetatable(motor) == VictorSPX then
		return ffi.C.VictorSPX_ToSpeedController(motor._this)
	elseif getmetatable(motor) == TalonSRX then
		return ffi.C.TalonSRX_ToSpeedController(motor._this)
	elseif getmetatable(motor) == TalonFX then
		return ffi.C.TalonFX_ToSpeedController(motor._this)
	else
		error("could not convert " .. tostring(motor) .. " to SpeedController")
	end
end

local function toIMotorController(motor)
	if getmetatable(motor) == VictorSPX then
		return ffi.C.VictorSPX_ToIMotorController(motor._this)
	elseif getmetatable(motor) == TalonSRX then
		return ffi.C.TalonSRX_ToIMotorController(motor._this)
	elseif getmetatable(motor) == TalonFX then
		return ffi.C.TalonFX_ToIMotorController(motor._this)
	else
		error("could not convert " .. tostring(motor) .. " to IMotorController")
	end
end

function VictorSPX:follow(masterToFollow)
	ffi.C.VictorSPX_Follow(self._this, toIMotorController(masterToFollow))
end

function TalonSRX:follow(masterToFollow)
	ffi.C.TalonSRX_Follow(self._this, toIMotorController(masterToFollow))
end

function TalonFX:follow(masterToFollow)
	ffi.C.TalonFX_Follow(self._this, toIMotorController(masterToFollow))
end

function DifferentialDrive:new(leftMotor, rightMotor)
	local instance = {
		_this = ffi.C.DifferentialDrive_new(toSpeedController(leftMotor), toSpeedController(rightMotor)),
	}
	setmetatable(instance, self)
	self.__index = self
	return instance
end

function DifferentialDrive:curvatureDriveIK(xSpeed, zRotation, allowTurnInPlace)
	xSpeed = AssertNumber(xSpeed)
	zRotation = AssertNumber(zRotation)
	local left = ffi.new("double[1]")
	local right = ffi.new("double[1]")
	ffi.C.CurvatureDriveIK(xSpeed, zRotation, allowTurnInPlace, left, right)
	return left[0], right[0]
end

function DifferentialDrive:blendedDrive(desiredSpeed, rotation, inputThreshold)
	local left, right = getBlendedMotorValues(desiredSpeed, rotation, inputThreshold);
	self:tankDrive(left, right)
end

DummyMotor = {}

function DummyMotor:new(...)
	local t = {}
	setmetatable(t, self)
	self.__index = self
	return t
end

function DummyMotor:set(...) end

function DummyMotor:follow(...) end

function DummyMotor:setInverted(...) end

---@param leader CANSparkMax
---@param invert boolean
function CANSparkMax:follow(leader, invert)
	invert = invert or false
	ffi.C.CANSparkMax_Follow(self._this, leader._this, invert)
end

function SparkMaxRelativeEncoder:wrap(cppEncoder)
    local instance = {
        _this = cppEncoder, -- no need to call a C++ constructor; we always get one of these from getEncoder()
    }
    setmetatable(instance, self)
    self.__index = self
    return instance
end

---@param countsPerRev? integer
---@return any
function CANSparkMax:getEncoder(countsPerRev)
    countsPerRev = countsPerRev or 42
    countsPerRev = AssertInt(countsPerRev)

	if not self.encoder then
		local luaEncoder = SparkMaxRelativeEncoder:wrap(ffi.C.CANSparkMax_GetEncoder(self._this, countsPerRev))
		self.encoder = luaEncoder
	end
	
	return self.encoder
end