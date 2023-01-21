function Robot.robotInit()
	leftStick = Joystick:new(0)
	rightStick = Joystick:new(1)
	gamepad = Joystick:new(2)
end

function Robot.robotPeriodic() end

function Robot.autonomousInit() end

function Robot.autonomousPeriodic() end

function Robot.teleopInit() end

function Robot.teleopPeriodic() end
