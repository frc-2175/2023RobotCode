require("subsystems.drivetrain")
require("subsystems.intake")
require("utils.vector")
require("wpilib.dashboard")

-- local camera1 = PhotonCamera:new("HD_USB_Camera")
-- local poseEst1 = PhotonPoseEstimator:new(getDeployDirectory() .. "/fakefield.json", PoseStrategy.AVERAGE_BEST_TARGETS, camera1, Transform3d:new(Translate3d:new(18, 0, 10), Rotate3d:new(0, 0, 0)))
-- local field = Field2d:new()

function Robot.robotInit()
	leftStick = Joystick:new(0)
	rightStick = Joystick:new(1)
	---@type Joystick
	gamepad = Joystick:new(2)

	---@type AHRS
	navx = AHRS:new(4)
end

function Robot.robotPeriodic()
	
	putNumber("position", Lyon:getPosition())
	putNumber("testPosition", Lyon:getTestPosition())

	-- local pose1 = poseEst1:update()
	
	-- if pose1 ~= nil then
	-- 	field:setRobotPose(pose1.position.x, pose1.position.y, pose1.rotation.z)
	-- 	putField(field)
	-- end
	
end

function Robot.autonomousInit()
end

function Robot.autonomousPeriodic()
end

function Robot.teleopInit() end

function Robot.teleopPeriodic()
	Drivetrain:drive(squareInput(leftStick:getY()), squareInput(rightStick:getX()))
	if gamepad:getButtonHeld(XboxButton.A) then
		Lyon:up()
	elseif gamepad:getButtonHeld(XboxButton.Y) then 
		Lyon:down()	
	elseif gamepad:getButtonHeld(XboxButton.B) then
		Lyon:zero()
	else
		Lyon:stop()
	end
	Lyon:periodic()
end

