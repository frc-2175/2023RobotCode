require("subsystems.drivetrain")
require("subsystems.lyon")
require("subsystems.brakes")
require("subsystems.intake")
require("utils.vector")
require("utils.DDPE")
require("utils.path")
require("utils.purepursuit")
require("wpilib.dashboard")
require("auto.coroutines")

leftStick = Joystick:new(0)
rightStick = Joystick:new(1)
gamepad = Joystick:new(2)

-----------------------------------


-- ramp for the drive controls, so drivers can think even less.
local driveRamp = Ramp:new(0.25, 0.4)

local encoderValueAtSubstation = 0

local inSubstation = false

local scoreDirection = "front"

field = Field2d:new()

navx = AHRS:new(4)

local shouldArmBalance = false

-----------------------------------

function Robot.robotInit()

	SmartDashboard:putBoolean("Brakes", true)

end

function Robot.robotPeriodic()
	local x, y, rot = Drivetrain:getPosition()

	field:setRobotPose(x, y, rot)
	SmartDashboard:putField(field)

	SmartDashboard:putString("scoreDirection", scoreDirection)

	if gamepad:getButtonPressed(XboxButton.Select) then
		Drivetrain:setPos(0, 0, 0)
	end

	Lyon:periodic()
	Drivetrain:periodic()
end

function Robot.autonomousInit()
	Lyon:slowdownWhenExtended(true)
	getSelectedAuto():reset()
end

function Robot.autonomousPeriodic()
	-- Just call auto periodic
	if not getSelectedAuto().done then
		getSelectedAuto():run()
	end
end

function Robot.teleopInit()
	Brakes:up()
	Lyon:slowdownWhenExtended(true)
end

function Robot.teleopPeriodic()
	Lyon:slowdownWhenExtended(true)
	Drivetrain:teleopDrive(driveRamp:ramp(signedPow(-leftStick:getY())), signedPow(rightStick:getX()))

	if gamepad:getLeftTriggerAmount() > 0.5 then
		Lyon:openGripper()
	elseif gamepad:getRightTriggerAmount() > 0.5 then
		Lyon:closeGripper()
	end

	reachedEncoderDisableFront = (encoderValueAtSubstation - 36 > Drivetrain:combinedPosition())
	-- reachedEncoderDisableRear = (scoreDirection == "rear" and (Drivetrain:combinedPosition() > encoderValueAtSubstation + 36))
	if reachedEncoderDisableFront then
		inSubstation = false
	end

	if not inSubstation then
		if gamepad:getButtonHeld(XboxButton.A) then
			local preset = scoreDirection == "front" and Lyon.LOW_PRESET or Lyon.LOW_REAR
			Lyon:setTargetPositionPreset(preset)
		elseif gamepad:getButtonHeld(XboxButton.X) then
			local preset = scoreDirection == "front" and Lyon.MID_PRESET or Lyon.MID_REAR
			Lyon:setTargetPositionPreset(preset)
		elseif gamepad:getButtonHeld(XboxButton.Y) then
			local preset = scoreDirection == "front" and Lyon.HIGH_PRESET or Lyon.HIGH_REAR
			Lyon:setTargetPositionPreset(preset)
		elseif gamepad:getButtonHeld(XboxButton.B) and scoreDirection == "front" then
			if gamepad:getButtonPressed(XboxButton.B) then
				Lyon:openGripper()
			end
			Lyon:setTargetAngle(Lyon.NEUTRAL_ANGLE)
			Lyon:setTargetExtension(Lyon.MAX_EXTENSION)
		elseif shouldArmBalance then
			ArmBalance:run()
		else
			Lyon:neutralPosition()
		end
	end

	if gamepad:getButtonHeld(XboxButton.LeftBumper) then
		if scoreDirection == "front" then
			Lyon:setTargetPositionPreset(Lyon.SUBSTATION_PRESET)
		end
		-- elseif scoreDirection == "rear" then
		-- 	Lyon:setTargetPositionPreset(Lyon.SUBSTATION_REAR)
		-- end

		if gamepad:getButtonPressed(XboxButton.LeftBumper) then
			Lyon:openGripper()
		end

		inSubstation = true
		encoderValueAtSubstation = Drivetrain:combinedPosition()
	elseif leftStick:getTriggerHeld() or gamepad:getButtonHeld(XboxButton.Select) then
		inSubstation = false
	end

	-- Switch score mode

	function toggleScoreDirection()
		if scoreDirection == "front" then
			scoreDirection = "rear"
		elseif scoreDirection == "rear" then
			scoreDirection = "front"
		end
	end

	if leftStick:getButtonPressed(2) or gamepad:getButtonPressed(XboxButton.Start) then
		toggleScoreDirection()
	end

	if gamepad:getPOV() == 0 or gamepad:getPOV() == 45 or gamepad:getPOV() == 315 then
		RollerBar:deploy()
		Lyon:openGripper()
	elseif gamepad:getPOV() == 180 or gamepad:getPOV() == 135 or gamepad:getPOV() == 225 then
		RollerBar:retract()
		RollerBar:rollIn()
	else
		RollerBar:retract()
		RollerBar:rollStop()
	end

	if rightStick:getButtonPressed(10) then
		Brakes:down()
	end

	if leftStick:getButtonPressed(10) then
		Brakes:up()
		shouldArmBalance = false
	end

	if rightStick:getButtonPressed(7) then
		ArmBalance:reset()
		shouldArmBalance = not shouldArmBalance
	end
end
