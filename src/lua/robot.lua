require("subsystems.drivetrain")

local rollOffset = 3.5

function Robot.robotInit()
	leftStick = Joystick:new(0)
	rightStick = Joystick:new(1)
	---@type Joystick
	gamepad = Joystick:new(2)

	---@type AHRS
	navx = AHRS:new(4)
end

function Robot.robotPeriodic()
	putNumber("Roll", navx:getRoll() - rollOffset)

	if gamepad:getButtonPressed(XboxButton.A) then
		rollOffset = navx:getRoll()
	end
end

function Robot.autonomousInit()
end

local autoSpeed = 0.30
local angleThresh = 10

function Robot.autonomousPeriodic()
	if navx:getRoll() - rollOffset > angleThresh then
		Drivetrain:drive(autoSpeed, 0)
	elseif navx:getRoll() - rollOffset < -angleThresh then
		Drivetrain:drive(-autoSpeed, 0)
	else
		Drivetrain:stop()
	end
end

function Robot.teleopInit() end

function Robot.teleopPeriodic()
	Drivetrain:drive(squareInput(leftStick:getY()), squareInput(rightStick:getX()))
end
