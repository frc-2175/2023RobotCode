require("utils.blendeddrive")


leftMotor = TalonFX:new(10)
rightMotor = TalonFX:new(12)

rightMotor:setInverted(CTREInvertType.InvertMotorOutput)
leftFollower = TalonFX:new(11)
leftFollower:follow(leftMotor)
leftFollower:setInverted(CTREInvertType.FollowMaster)

rightFollower = TalonFX:new(13)
rightFollower:follow(rightMotor)
rightFollower:setInverted(CTREInvertType.FollowMaster)

leftMotor:setNeutralMode(NeutralMode.Brake)
rightMotor:setNeutralMode(NeutralMode.Brake)

rightMotor:setInverted(CTREInvertType.InvertMotorOutput)


Drivetrain = {}

function Drivetrain:drive(speed, rotation)
	local leftSpeed, rightSpeed = getBlendedMotorValues(speed, rotation)

	leftMotor:set(leftSpeed)
	rightMotor:set(rightSpeed)
end

function Drivetrain:stop()
	Drivetrain:drive(0, 0)
end
