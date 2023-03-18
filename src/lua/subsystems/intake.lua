local leftBarPiston = DoubleSolenoid:new(2, 3)
local rightBarPiston = DoubleSolenoid:new(4, 5)

RollerBar = {}

function RollerBar:down()
	leftBarPiston:set(DoubleSolenoidValue.Forward)
	rightBarPiston:set(DoubleSolenoidValue.Forward)
end

function RollerBar:up()
	leftBarPiston:set(DoubleSolenoidValue.Reverse)
	rightBarPiston:set(DoubleSolenoidValue.Reverse)
end