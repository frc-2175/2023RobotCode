require("subsystems.drivetrain")
require("subsystems.intake")
require("utils.vector")
require("wpilib.dashboard")

-- local camera1 = PhotonCamera:new("HD_USB_Camera")
-- local poseEst1 = PhotonPoseEstimator:new(getDeployDirectory() .. "/fakefield.json", PoseStrategy.AVERAGE_BEST_TARGETS, camera1, Transform3d:new(Translate3d:new(18, 0, 10), Rotate3d:new(0, 0, 0)))
-- local field = Field2d:new()

leftStick = Joystick:new(0)
rightStick = Joystick:new(1)
gamepad = Joystick:new(2)

navx = AHRS:new(4)

function Robot.robotInit()
end

function Robot.robotPeriodic()
	SmartDashboard:putNumber("position", Lyon:getAngle())
end

function Robot.autonomousInit()
	print(SmartDashboard:getBooleanArray("strtest")[1])
end

function Robot.autonomousPeriodic()
end

function Robot.teleopInit() end

function Robot.teleopPeriodic()
	Drivetrain:drive(squareInput(leftStick:getY()) * 0.5, squareInput(rightStick:getX()) * 0.5)

	if gamepad:getLeftTriggerAmount() > 0.5 then
		Lyon:gripperSolenoid(DoubleSolenoidValue.Forward)
	elseif gamepad:getRightTriggerAmount() > 0.5 then
		Lyon:gripperSolenoid(DoubleSolenoidValue.Reverse)
	else
		Lyon:gripperSolenoid(DoubleSolenoidValue.Off)
	end

	if leftStick:getButtonHeld(3) or rightStick:getButtonHeld(3) then --TODO these button values are probably not correct
		autoEngage:run(
	end

	if gamepad:getRightStickY() > 0 then
		Lyon:setTargetAngle(Lyon.NODE_ANGLE_HIGH)
	elseif gamepad:getRightStickY() < 0 then
		Lyon:setTargetAngle(0.1)
	else
		Lyon:setTargetAngle(Lyon:getAngle())
	end

	print(gamepad:getPOV())

	if gamepad:getPOV() == 0 then
	 	Lyon:setTargetExtension(Lyon.MAX_EXTENSION)
	elseif gamepad:getPOV() == 180 then
	 	Lyon:setTargetExtension(Lyon.MIN_EXTENSION)
	else
		Lyon:setTargetExtension(Lyon:getExtension())
	end

	Lyon:periodic()
end

