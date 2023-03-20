local leftBarPiston = DoubleSolenoid:new(2, 3)
local rightBarPiston = DoubleSolenoid:new(4, 5)
local barNeo = CANSparkMax:new(22, SparkMaxMotorType.kBrushless)

RollerBar = {}

function RollerBar:down()
	leftBarPiston:set(DoubleSolenoidValue.Forward)
	rightBarPiston:set(DoubleSolenoidValue.Forward)
end

function RollerBar:up()
	leftBarPiston:set(DoubleSolenoidValue.Reverse)
	rightBarPiston:set(DoubleSolenoidValue.Reverse)
end

function RollerBar:rollOut()
	barNeo:set(0.2) --TODO: finetune value
end

function RollerBar:rollStop()
	barNeo:set(0)
end

function RollerBar:rollIn()
	barNeo:set(-0.2) --TODO: finetune value
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
