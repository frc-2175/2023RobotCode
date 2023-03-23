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


local camera = PhotonCamera:new("HD_USB_Camera")
local poseEst = PhotonPoseEstimator:new(getDeployDirectory() .. "/fakefield.json", PoseStrategy.MULTI_TAG_PNP, camera, Transform3d:new(Translate3d:new(10.75, 7, 21), Rotate3d:new(0, 0, 0)))

local pe = DDPE:new(Drivetrain:yaw(), Drivetrain:leftPosition(), Drivetrain:rightPosition(), 0, 0, 0)

local path = Path:new("Test", {
	testEvent = function()
		print("TEST PATH TEST PATH TEST PATH")
	end,
})
local pp = PurePursuit:new(path, 0.1, 0, 0)

local field = Field2d:new()

local speed, turn

local autoSeconds = 3000

local autoLoopCount = 0

local encoderValueAtSubstation = 0

local inSubstation = false

local scoreDirection = "front"

navx = AHRS:new(4)

-----------------------------------

function Robot.robotInit()
end

function Robot.robotPeriodic()
	local pose, timestamp = poseEst:update()
	
	if pose ~= nil then
		pe:AddVisionMeasurement(pose.position.x, pose.position.y, pose.rotation.z, timestamp)
	end
	
	local x, y , rot = pe:Update(Drivetrain:yaw(), Drivetrain:leftPosition(), Drivetrain:rightPosition())
	
	SmartDashboard:putNumber("X", x)
	SmartDashboard:putNumber("Y", y)
	SmartDashboard:putNumber("Rot", rot)
	
	field:setRobotPose(x, y, rot)
	SmartDashboard:putField(field)
	
	speed, turn = pp:run(Vector:new(x, y), rot)
	
	SmartDashboard:putNumber("speed", speed)
	SmartDashboard:putNumber("turn", turn)
	SmartDashboard:putString("scoreDirection", scoreDirection)
	SmartDashboard:putNumber("roll", navx:getRoll())
	SmartDashboard:putNumber("pitch", navx:getPitch())
	
	Lyon:periodic()
	Drivetrain:periodic()
	
	SmartDashboard:putNumber("Solenoid", brakeSolenoid:get())
end

function Robot.autonomousInit()
	getSelectedAuto():reset()
end

function Robot.autonomousPeriodic()
	-- Just call auto periodic
	getSelectedAuto():run()
end

function Robot.teleopInit() end

function Robot.teleopPeriodic()
	Drivetrain:teleopDrive(driveRamp:ramp(signedPow(-leftStick:getY())), signedPow(rightStick:getX()))
	
	if gamepad:getLeftTriggerAmount() > 0.5 then
		Lyon:openGripper()
	elseif gamepad:getRightTriggerAmount() > 0.5 then
		Lyon:closeGripper()
	end

	reachedEncoderDisableFront = (encoderValueAtSubstation + 36 < Drivetrain:combinedPosition())
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
	elseif leftStick:getTriggerHeld() or gamepad:getButtonHeld(XboxButton.RightBumper) then
		inSubstation = false
	end

	-- Nick, I expected better
	-- if gamepad:getButtonHeld(XboxButton.RightBumper) then
	-- 	inSubstation = false
	-- end
		
	-- Switch score mode
	if leftStick:getButtonPressed(2) then
		scoreDirection = "front"
	end
	if rightStick:getButtonPressed(2) then
		scoreDirection = "rear"
	end
	
	if gamepad:getPOV() == 0 or gamepad:getPOV() == 45 or gamepad:getPOV() == 315 then
		RollerBar:deploy()
		Lyon:openGripper()
	else
		RollerBar:retract()
	end

	if gamepad:getPOV() == 180 or gamepad:getPOV() == 135 or gamepad:getPOV() == 225 then
		RollerBar:rollIn()
	else 
		RollerBar:rollStop()
	end

	if rightStick:getButtonPressed(10) then
		Brakes:forward()
	end

	if leftStick:getButtonPressed(10) then
		Brakes:reverse()
	end
end
