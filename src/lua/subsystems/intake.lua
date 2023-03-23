local intakePiston = DoubleSolenoid:new(2, 3)
local barNeo = CANSparkMax:new(22, SparkMaxMotorType.kBrushless)
local barSpeed = 1/3 --TODO: finetune value

RollerBar = {}

function RollerBar:down()
	intakePiston:set(DoubleSolenoidValue.Forward)
end

function RollerBar:up()
	intakePiston:set(DoubleSolenoidValue.Reverse)
end

function RollerBar:rollOut()
	barNeo:set(-barSpeed)
end

function RollerBar:rollStop()
	barNeo:set(0)
end

function RollerBar:rollIn()
	barNeo:set(barSpeed)
end

--- Puts the bar down and starts the motor
function RollerBar:deploy()
	RollerBar:down()
	RollerBar:rollIn()
end

--- Brings the bar up and stops the motor
function RollerBar:retract()
	RollerBar:up()
	RollerBar:rollStop()
end
