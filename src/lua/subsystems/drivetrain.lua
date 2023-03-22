require("utils.blendeddrive")
require("utils.ramp")
require("mocks.navx")
require("mocks.motors")
require("wpilib.ahrs")
require("wpilib.motors")

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
leftFollower:follow(leftMotor)
leftFollower:setInverted(CTREInvertType.FollowMaster)

rightMotor:setInverted(CTREInvertType.None)
rightFollower:follow(rightMotor)
rightFollower:setInverted(CTREInvertType.FollowMaster)

leftMotor:setNeutralMode(NeutralMode.Brake)
rightMotor:setNeutralMode(NeutralMode.Brake)

local TICKS_TO_INCHES = (6 * math.pi) / (2048 * 11.71)

Drivetrain = {}

function Drivetrain:yaw()
	return -math.rad(navx:getYaw())
end

function Drivetrain:pitchDegrees()
	return navx:getPitch()
end

function Drivetrain:periodic()
	SmartDashboard:putNumber("leftPosition", Drivetrain:leftPosition())
	SmartDashboard:putNumber("rightPosition", Drivetrain:rightPosition())
	SmartDashboard:putNumber("yaw", Drivetrain:yaw())
end

function Drivetrain:autoDrive(speed, rotation)
	local leftSpeed, rightSpeed = getBlendedMotorValues(speed, -rotation)

	leftMotor:set(leftSpeed)
	rightMotor:set(rightSpeed)
end

function Drivetrain:teleopDrive(speed, rotation) 
	local leftSpeed, rightSpeed = getBlendedMotorValues(speed, -rotation, 0.1, 0.6, 0.5)

	leftMotor:set(leftSpeed)
	rightMotor:set(rightSpeed)
end

function Drivetrain:stop()
	Drivetrain:autoDrive(0, 0)
end

function Drivetrain:leftPosition()
	return -leftMotor:getSelectedSensorPosition() * TICKS_TO_INCHES
end

function Drivetrain:rightPosition()
	return -rightMotor:getSelectedSensorPosition() * TICKS_TO_INCHES
end

function Drivetrain:combinedPosition()
	return (Drivetrain:leftPosition() + Drivetrain:rightPosition()) / 2
end
