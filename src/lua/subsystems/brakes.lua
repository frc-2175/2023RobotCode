require("wpilib.solenoids")

local brakeSolenoid = DoubleSolenoid:new(6, 7)

Brakes = {}

function Brakes:toggleBrakes()
	if brakeSolenoid:get() ~= DoubleSolenoidValue.Reverse then
		brakeSolenoid:set(DoubleSolenoidValue.Reverse)
	else
		brakeSolenoid:set(DoubleSolenoidValue.Forward)
	end
end
