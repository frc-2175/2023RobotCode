require("subsystems.cargo")
require("subsystems.climber")
require("subsystems.drivetrain")
require("utils.logger")
require("utils.blendeddrive")
require("utils.slideshow")
require("utils.purepursuit")
require("utils.path")
require("auto.coroutines")

local selectedAuto = doNothingAuto



function Robot.robotInit()
	leftStick = Joystick:new(0)
	rightStick = Joystick:new(1)
	gamepad = Joystick:new(2)
	resetTracking()
	navx:reset()
	autoChooser = SendableChooser:new()
	autoChooser:putChooser({
		{ name = "doNothing", value = doNothingAuto },
		{ name = "taxi", value = taxiAuto },
		{ name = "oneBallAuto", value = oneBallAuto },
		{ name = "test", value = testAuto}
	})

	-- testSlides = Slideshow:new({ "lemon", "*chomp chomp*", "OoOOOooOoOoOOoooO" })
	startAutomaticCapture()
end

function Robot.robotPeriodic()
	-- we make armPosition negative because i hate you.
	-- no, go build a shed
	-- no, go spend 25 hours a day playing kerbal space program - Elizabeth
	armPosition = -armEncoder:getPosition()
	putNumber("arm", armPosition)
	putNumber("armSpeed", arm:get())
	putNumber("left", leftMotor:getSelectedSensorPosition())
	putNumber("right", rightMotor:getSelectedSensorPosition())
	putNumber("X", position.x)
	putNumber("Y", position.y)
	putNumber("Rotation", navx:getAngle())
	putNumber("Winch", winchEncoder:getPosition())
end

function Robot.autonomousInit()
	navx:reset()
	resetTracking()
	selectedAuto = autoChooser:getSelected()
	selectedAuto:reset()
	testPursuit = PurePursuit:new(
		orientPath(readPath("p")),
		false,
		0.015, 0, 0.002
	)
end

function Robot.autonomousPeriodic()
	Intake:periodic()
	trackLocation(leftMotor, rightMotor)
	selectedAuto:run()
end

function Robot.teleopInit()
	navx:reset()
	resetTracking()
end

function Robot.teleopPeriodic()
	Intake:periodic()

	
	



	

	-- joystick driving
	Drivetrain:drive(squareInput(leftStick:getY()), squareInput(rightStick:getX()))


	if gamepad:getButtonPressed(XboxButton.RightBumper) or rightStick:getTriggerPressed() then
		Intake:down()
	end

	if gamepad:getButtonReleased(XboxButton.RightBumper) or rightStick:getTriggerReleased() then
		Intake:up()
	end

	if gamepad:getButtonHeld(XboxButton.Start) then
		Winch:runIn()
		Intake:down()
	elseif gamepad:getButtonHeld(XboxButton.Select) then
		Winch:runOut()
		Intake:down()
	else
		Winch:stop()
	end

	if gamepad:getButtonHeld(XboxButton.B) then
		Winch:runIn1()
	elseif gamepad:getButtonHeld(XboxButton.X) then
		Winch:runIn2()
	end

	
	if rightStick:getTriggerHeld() then
		Intake:rollIn()
	else
		Intake:stop()
		intakeMotor:set(gamepad:getLeftTriggerAmount() - gamepad:getRightTriggerAmount())
	end
end
