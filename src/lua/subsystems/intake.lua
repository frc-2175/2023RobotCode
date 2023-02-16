require("utils.teleopcoroutine")
require("utils.math")
require("wpilib.dashboard")

local telescopingArm = CANSparkMax:new(0, SparkMaxMotorType.kBrushless) -- TODO: not a real device id
local gripperSolonoid = Solonoid:new(0) --TODO: not a real device id
local arm = CANSparkMax:new(23, SparkMaxMotorType.kBrushless)
---@type SparkMaxRelativeEncoder
local armEncoder = arm:getEncoder()
armEncoder:setPositionConversionFactor(1)

local testMotor = CANSparkMax:new(20, SparkMaxMotorType.kBrushless)
---@type SparkMaxRelativeEncoder
local testEncoder = testMotor:getEncoder()


--Note Telescoping Arm has been abrieviated to ta.
--TODO: refine values
local taOutSpeed = 0.2
local taMidSpeed = 0
local taInSpeed = 0.2
--TODO: refine values or figure out what they actually are
local taOutPosition = 1
local taMidPosition = 0
local taInPosition = -1

armPosition = 0

--TODO: refine values
local lyonUpSpeed = 0.2
local lyonMidSpeed = 0
local lyonDownSpeed = 0.2

local lyonUpPosition = math.pi / 4
local lyonMidPosition = 0
local lyonDownPosition = -math.pi / 4
-- so i wanna put smth here to just set various postions but idk the implementation so ima do it later

Lyon = {}

function telescopingArm:out()
	if self:getPosition() < taOutPosition then
		telescopingArm:set(taOutSpeed)
	else
		telescopingArm:set(0)
	end
end

function gripperSolonoid:open()
	gripperSolonoid:set(true)
end

function grip:close()
	gripperSolonoid:set(false)
end

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
	SmartDashboard:putNumber("LyonPos", Lyon:getPosition())
	SmartDashboard:putNumber("LyonRawPos", Lyon:getMotorRawPosition())
	SmartDashboard:putNumber("LyonOutput", arm:get())
	return armEncoder:getPosition()
end

function Lyon:up()
	if self:getPosition() < lyonUpPosition then
		arm:set(lyonUpSpeed)
	else
		arm:set(0)
	end
end

function Lyon:down()
	if self:getPosition() > lyonDownPosition then
		arm:set(-lyonDownSpeed)
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