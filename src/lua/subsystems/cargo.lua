require("utils.teleopcoroutine")
require("utils.math")

intakeMotor = TalonSRX:new(26)

---@type CANSparkMax
arm = CANSparkMax:new(31, SparkMaxMotorType.kBrushless)
arm:restoreFactoryDefaults()
arm:setIdleMode(IdleMode.kBrake)
armEncoder = arm:getEncoder()
armPosition = 0

local upPosition = 1
local midPosition = 14
local downPosition = 20

local upSpeed = 1
local midSpeed = 0.3
local downSpeed = 0.2

local armDown = false -- false is up true is down

---@class Intake
Intake = {}

function Intake:periodic()
	if armDown then
		if armPosition < downPosition then
			arm:set(-downSpeed)
		else
			arm:set(0)
		end
	else
		if armPosition > midPosition then
			arm:set(upSpeed)
		elseif armPosition > upPosition then
			arm:set(midSpeed)
		else
			arm:set(0)
		end
	end
end

function Intake:up()
	armDown = false
end

function Intake:down()
	armDown = true
end

function Intake:stopArm()
	arm:set(0)
end

function Intake:rollIn()
	intakeMotor:set(-1)
end

function Intake:rollOut()
	intakeMotor:set(1)
end

function Intake:stop()
	intakeMotor:set(0)
end
