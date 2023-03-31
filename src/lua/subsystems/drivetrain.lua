require("utils.blendeddrive")
require("utils.ramp")
require("utils.DDPE")
require("mocks.navx")
require("mocks.motors")
require("wpilib.motors")
require("wpilib.ahrs")

leftMotor = TalonFX:new(10)
rightMotor = TalonFX:new(12)
leftFollower = TalonFX:new(11)
rightFollower = TalonFX:new(13)

navx = AHRS:new(4)

if isTesting() then
	navx = MockNavX
	leftMotor = MockTalonFX
	rightMotor = MockTalonFX
	leftFollower = MockTalonFX
	rightFollower = MockTalonFX
end

leftMotor:setInverted(CTREInvertType.InvertMotorOutput)
leftFollower:setInverted(CTREInvertType.InvertMotorOutput)

rightMotor:setInverted(CTREInvertType.None)
rightFollower:setInverted(CTREInvertType.None)

leftMotor:setNeutralMode(NeutralMode.Brake)
leftFollower:setNeutralMode(NeutralMode.Brake)

rightMotor:setNeutralMode(NeutralMode.Brake)
rightFollower:setNeutralMode(NeutralMode.Brake)

local TICKS_TO_INCHES = (6 * math.pi) / (2048 * 11.71)

Drivetrain = {}

function Drivetrain:yaw()
	return -math.rad(navx:getYaw())
end

function Drivetrain:pitchDegrees()
	return navx:getPitch() + 0.349999994039536
end

function Drivetrain:leftPosition()
	return leftMotor:getSelectedSensorPosition() * TICKS_TO_INCHES
end

function Drivetrain:rightPosition()
	return rightMotor:getSelectedSensorPosition() * TICKS_TO_INCHES
end

function Drivetrain:combinedPosition()
	return (Drivetrain:leftPosition() + Drivetrain:rightPosition()) / 2
end

local pe = DDPE:new(Drivetrain:yaw(), Drivetrain:leftPosition(), Drivetrain:rightPosition(), 0, 0, 0)

function Drivetrain:periodic()
	SmartDashboard:putNumber("leftPosition", Drivetrain:leftPosition())
	SmartDashboard:putNumber("rightPosition", Drivetrain:rightPosition())
	SmartDashboard:putNumber("yaw", Drivetrain:yaw())
	SmartDashboard:putNumber("pitch", Drivetrain:pitchDegrees())


	pe:Update(Drivetrain:yaw(), Drivetrain:leftPosition(), Drivetrain:rightPosition())
end

---@return number x, number y, number angle
function Drivetrain:getPosition()
	return pe:GetEstimatedPosition()
end

function Drivetrain:autoDrive(speed, rotation)
	local leftSpeed, rightSpeed = getBlendedMotorValues(speed, -rotation)

	leftMotor:set(leftSpeed)
	leftFollower:set(leftSpeed)
	rightMotor:set(rightSpeed)
	rightFollower:set(rightSpeed)
end

function Drivetrain:teleopDrive(speed, rotation)
	local leftSpeed, rightSpeed = getBlendedMotorValues(speed, -rotation, 0.1, 0.8, 0.3)

	leftMotor:set(leftSpeed)
	leftFollower:set(leftSpeed)
	rightMotor:set(rightSpeed)
	rightFollower:set(rightSpeed)
end

function Drivetrain:setPos(x, y, rot)
	pe:ResetPosition(Drivetrain:yaw(), Drivetrain:leftPosition(), Drivetrain:rightPosition(), x, y, rot)
end

function Drivetrain:stop()
	Drivetrain:autoDrive(0, 0)
end
