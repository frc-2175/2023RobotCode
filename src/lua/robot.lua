require("subsystems.drivetrain")
require("subsystems.intake")
require("utils.vector")
require("utils.DDPE")
require("wpilib.dashboard")

leftStick = Joystick:new(0)
rightStick = Joystick:new(1)
gamepad = Joystick:new(2)

navx = AHRS:new(4)

function Robot.robotInit()
end

function Robot.robotPeriodic()

	if gamepad:getRightStickY() > 0 then
		Lyon:setTargetAngle(Lyon.NODE_ANGLE_HIGH)
	elseif gamepad:getRightStickY() < 0 then
		Lyon:setTargetAngle(0.1)
	else
		Lyon:setTargetAngle(Lyon:getAngle())
	end
end

function Robot.autonomousInit()
end

function Robot.autonomousPeriodic()
end

function Robot.teleopInit() end

function Robot.teleopPeriodic()
	Drivetrain:drive(squareInput(leftStick:getY()) * 0.5, -squareInput(rightStick:getX()) * 0.5)

	if gamepad:getLeftTriggerAmount() > 0.5 then
		Lyon:gripperSolenoid(DoubleSolenoidValue.Forward)
	elseif gamepad:getRightTriggerAmount() > 0.5 then
		Lyon:gripperSolenoid(DoubleSolenoidValue.Reverse)
	else
		Lyon:gripperSolenoid(DoubleSolenoidValue.Off)
	end

	if gamepad:getRightStickY() > 0 then
		Lyon:setTargetAngle(Lyon.NODE_ANGLE_HIGH)
	elseif gamepad:getRightStickY() < 0 then
		Lyon:setTargetAngle(-Lyon.NODE_ANGLE_HIGH)
	else
		Lyon:setTargetAngle(Lyon:getAngle())
	end

	if gamepad:getPOV() == 0 then
	 	Lyon:setTargetExtension(Lyon.MAX_EXTENSION)
	elseif gamepad:getPOV() == 180 then
	 	Lyon:setTargetExtension(Lyon.MIN_EXTENSION)
	else
		Lyon:setTargetExtension(Lyon:getExtension())
	end

	Lyon:periodic()
end

