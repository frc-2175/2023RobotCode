require("subsystems.drivetrain")
require("subsystems.lyon")
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

local nudgePosition = 10

local nudgeSpeed = 16 -- inches per second

local autoSeconds = 3000

local autoLoopCount = 0

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

	Lyon:periodic()
	Drivetrain:periodic()
end

function Robot.autonomousInit()
	getSelectedAuto():reset()
end

function Robot.autonomousPeriodic()
	-- Drivetrain:drive(clamp(-speed, -0.2, 0.2),clamp(-turn, -0.2, 0.2))
	-- Just call auto periodic
	getSelectedAuto():run()
end

function Robot.teleopInit() end

function Robot.teleopPeriodic()
	Drivetrain:drive(signedPow(-leftStick:getY()), signedPow(rightStick:getX()))

	if gamepad:getLeftTriggerAmount() > 0.5 then
		Lyon:openGripper()
	elseif gamepad:getRightTriggerAmount() > 0.5 then
		Lyon:closeGripper()
	end

	nudgeChange = gamepad:getLeftStickY() / 50 * nudgeSpeed
	nudgePosition = clamp(nudgePosition + nudgeChange, 6, 48)

	if gamepad:getButtonHeld(XboxButton.A) then
		Lyon:setTargetPositionPreset(Lyon.LOW_PRESET)
	elseif gamepad:getButtonHeld(XboxButton.X) then
		Lyon:setTargetPositionPreset(Lyon.MID_PRESET)
	elseif gamepad:getButtonHeld(XboxButton.Y) then
		Lyon:setTargetPositionPreset(Lyon.HIGH_PRESET)
	elseif gamepad:getButtonHeld(XboxButton.B) then
		if gamepad:getButtonPressed(XboxButton.B) then
			Lyon:openGripper()
		end

		Lyon:setTargetPosition(nudgePosition, 0)
	else
		Lyon:setTargetPositionPreset(Lyon.NEUTRAL)
	end
end

