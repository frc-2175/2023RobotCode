require("utils.blendeddrive")
require("mocks.navx")
require("mocks.motors")

leftMotor = TalonFX:new(10)
rightMotor = TalonFX:new(12)

navx = AHRS:new(4)

leftMotor:setInverted(CTREInvertType.InvertMotorOutput)
leftFollower = TalonFX:new(11)
leftFollower:follow(leftMotor)
leftFollower:setInverted(CTREInvertType.FollowMaster)

rightMotor:setInverted(CTREInvertType.None)
rightFollower = TalonFX:new(13)
rightFollower:follow(rightMotor)
rightFollower:setInverted(CTREInvertType.FollowMaster)

leftMotor:setNeutralMode(NeutralMode.Brake)
rightMotor:setNeutralMode(NeutralMode.Brake)

local TICKS_TO_INCHES = (6 * math.pi) / (2048 * 11.71)

Drivetrain = {}

function Drivetrain:yaw()
	return -math.rad(navx:getYaw())
end

function Drivetrain:periodic()
	SmartDashboard:putNumber("leftPosition", Drivetrain:leftPosition())
	SmartDashboard:putNumber("rightPosition", Drivetrain:rightPosition())
	SmartDashboard:putNumber("yaw", Drivetrain:yaw())
end

function Drivetrain:drive(speed, rotation)
	local leftSpeed, rightSpeed = getBlendedMotorValues(speed, -rotation)

	leftMotor:set(leftSpeed * 0.5)
	rightMotor:set(rightSpeed * 0.5)
end

function Drivetrain:stop()
	Drivetrain:drive(0, 0)
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

if isTesting() then
	navx = MockNavX
	leftMotor = MockTalonFX
	rightMotor = MockTalonFX
end
