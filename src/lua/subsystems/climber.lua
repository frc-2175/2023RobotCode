winchMotor = CANSparkMax:new(32, SparkMaxMotorType.kBrushless)
winchFollower = CANSparkMax:new(33, SparkMaxMotorType.kBrushless)

winchMotor:restoreFactoryDefaults()
winchFollower:restoreFactoryDefaults()

winchFollower:setInverted(true)

winchMotor:setIdleMode(IdleMode.kBrake)
winchFollower:setIdleMode(IdleMode.kBrake)

-- up == negative, down == positive
winchEncoder = winchMotor:getEncoder()

local speed = 1

---@class Winch
Winch = {}

function Winch:runIn()
	if winchEncoder:getPosition() < 0 then
		winchMotor:set(speed)
		winchFollower:set(speed)
	else
		self:stop()
	end
end

function Winch:runIn1()
	winchMotor:set(speed / 4)
end

function Winch:runIn2()
	winchFollower:set(speed / 4)
end



function Winch:runOut()
	if -212 < winchEncoder:getPosition() then
		winchMotor:set(-speed)
		winchFollower:set(-speed)
	else
		self:stop()
	end
end

function Winch:runOut1()
	winchMotor:set(-speed / 4)
end

function Winch:runOut2()
	winchFollower:set(-speed / 4)
end



function Winch:stop()
	winchMotor:set(0)
	winchFollower:set(0)
end

function Winch:stop1()
	winchMotor:set(0)
end

function Winch:stop2()
	winchFollower:set(0)
end

function Winch:get()
	return winchMotor:get()
end
