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
	Drivetrain:drive(signedPow(leftStick:getY()) * 0.5, signedPow(rightStick:getX()) * 0.5)

	if gamepad:getLeftTriggerAmount() > 0.5 then
		Lyon:gripperSolenoid(DoubleSolenoidValue.Forward)
	elseif gamepad:getRightTriggerAmount() > 0.5 then
		Lyon:gripperSolenoid(DoubleSolenoidValue.Reverse)
	else
		Lyon:gripperSolenoid(DoubleSolenoidValue.Off)
	end

	if gamepad:getButtonHeld(XboxButton.A) then
		Lyon:setTargetPosition(34, 13)
	elseif gamepad:getButtonHeld(XboxButton.X) then
		Lyon:setTargetPosition(42.75, 46)
	elseif gamepad:getButtonHeld(XboxButton.Y) then
		Lyon:setTargetPosition(60, 59)
	elseif gamepad:getButtonHeld(XboxButton.B) then
		Lyon:setTargetPosition(20, 0)
	else
		Lyon:setTargetPosition(0,20)
	end

	Lyon:periodic()
end

