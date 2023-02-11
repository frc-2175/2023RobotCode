require("utils.teleopcoroutine")
require("utils.math")
require("wpilib.dashboard")

local arm = CANSparkMax:new(23, SparkMaxMotorType.kBrushless)
---@type SparkMaxRelativeEncoder
local armEncoder = arm:getEncoder()
armEncoder:setPositionConversionFactor(1)

local testMotor = CANSparkMax:new(20, SparkMaxMotorType.kBrushless)
---@type SparkMaxRelativeEncoder
local testEncoder = testMotor:getEncoder()

armPosition = 0


--add values
local upSpeed = 0.2
local midSpeed = 0
local downSpeed = 0.2

--add values
local upPosition = math.pi / 4
local midPosition = 0
local downPosition = -math.pi / 4
-- so i wanna put smth here to just set various postions but idk the implementation so ima do it later

Lyon = {}

function Lyon:getMotorRawPosition()
	return armEncoder:getPosition()
end

function Lyon:getPosition()
	-- return armEncoder:getPosition() * (2.5 * 2 * math.pi) / (50 * 13)
	return armEncoder:getPosition() * (math.pi / 155.4955)
end

function Lyon:getTestPosition()
	return testEncoder:getPosition()
end

function Lyon:periodic()
	putNumber("LyonPos", Lyon:getPosition())
	putNumber("LyonRawPos", Lyon:getMotorRawPosition())
	putNumber("LyonOutput", arm:get())
	return armEncoder:getPosition()
end

function Lyon:up()
	if self:getPosition() < upPosition then
		arm:set(upSpeed)
	else
		arm:set(0)
	end
end

function Lyon:down()
	if self:getPosition() > downPosition then
		arm:set(-downSpeed)
	else
		arm:set(0)
	end
end

function Lyon:zero()
	if self:getPosition() < -0.1 or 0.1 < self:getPosition() then
		if self:getPosition() < 0 then
			Lyon:up()
		else 
			Lyon:down()
		end
	end
end

function Lyon:stop()
	arm:set(0)
end