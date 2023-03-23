require("wpilib.solenoids")

brakeSolenoid = DoubleSolenoid:new(4, 5)

Brakes = {}

function Brakes:forward()
	brakeSolenoid:set(DoubleSolenoidValue.Forward)
	
end

function Brakes:reverse()
	brakeSolenoid:set(DoubleSolenoidValue.Reverse)
end

function Brakes:toggleBrakes()
	if brakeSolenoid:get() ~= DoubleSolenoidValue.Reverse then
		brakeSolenoid:set(DoubleSolenoidValue.Reverse)
	else
		brakeSolenoid:set(DoubleSolenoidValue.Forward)
	end
end
