require("wpilib.solenoids")

brakeSolenoid = DoubleSolenoid:new(4, 5)

Brakes = {}

function Brakes:up()
	brakeSolenoid:set(DoubleSolenoidValue.Forward)

	SmartDashboard:putBoolean("Brakes", true)
end

function Brakes:down()
	brakeSolenoid:set(DoubleSolenoidValue.Reverse)

	SmartDashboard:putBoolean("Brakes", false)
end
