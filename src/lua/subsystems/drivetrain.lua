require("utils.blendeddrive")


---@type TalonFX
leftMotor = TalonFX:new(1)
rightMotor = TalonFX:new(6)

rightMotor:setInverted(CTREInvertType.InvertMotorOutput)

leftMotor:setNeutralMode(0)
rightMotor:setNeutralMode(0)


Drivetrain = {}

function Drivetrain:drive(speed, rotation)
	local leftSpeed, rightSpeed = getBlendedMotorValues(speed, rotation)

	leftMotor:set(leftSpeed)
	rightMotor:set(rightSpeed)
end

function Drivetrain:stop()
	Drivetrain:drive(0, 0)
end
