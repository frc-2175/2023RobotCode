require("subsystems.drivetrain")
require("utils.vector")
require("utils.DDPE")
require("wpilib.dashboard")

leftStick = Joystick:new(0)
rightStick = Joystick:new(1)
gamepad = Joystick:new(2)

navx = AHRS:new(4)

local camera = PhotonCamera:new("FrontCam")
local poseEst = PhotonPoseEstimator:new(getDeployDirectory() .. "/fakefield.json", PoseStrategy.MULTI_TAG_PNP, camera, Transform3d:new(Translate3d:new(-19, 0, 10.5), Rotate3d:new(0, 0, math.pi)))
local camera2 = PhotonCamera:new("HD_USB_Camera")
local poseEst2 = PhotonPoseEstimator:new(getDeployDirectory() .. "/fakefield.json", PoseStrategy.MULTI_TAG_PNP, camera2, Transform3d:new(Translate3d:new(18.5, 0, 14), Rotate3d:new(math.pi, 0, 0)))
local field = Field2d:new()
local leftEncoder = leftMotor:getEncoder()
local rightEncoder = rightMotor:getEncoder()
local REVS_TO_INCHES = (12 / 40) * (18 / 42) * (6 * math.pi) * -0.895
local pe = DDPE:new(-math.rad(navx:getYaw()), leftEncoder:getPosition() * REVS_TO_INCHES, rightEncoder:getPosition() * REVS_TO_INCHES, 0, 0, 0)

local function leftPosition()
	return leftEncoder:getPosition() * REVS_TO_INCHES
end

local function rightPosition()
	return rightEncoder:getPosition() * REVS_TO_INCHES
end

local function yaw()
	return -math.rad(navx:getYaw())
end

local function resetPE()
	pe:ResetPosition(yaw(), leftPosition(), rightPosition(), 174, 130, 0)
end

function Robot.robotInit()
end

function Robot.robotPeriodic()
	local x, y , rot = pe:Update(yaw(), leftPosition(), rightPosition())
	SmartDashboard:putNumber("left", leftPosition())
	SmartDashboard:putNumber("right", rightPosition())
	SmartDashboard:putNumber("yaw", yaw())
	SmartDashboard:putNumber("X", x)
	SmartDashboard:putNumber("Y", y)
	SmartDashboard:putNumber("Rot", rot)

	field:setRobotPose(x, y, rot)
	SmartDashboard:putField(field)
	
	if gamepad:getButtonPressed(XboxButton.A) then
		resetPE()
	end
	
	if leftStick:getButtonHeld(3) then --TODO these button values are probably not correct
		coroutine.resume(autoEngage)
		if leftStick:getButtonReleased(3)then
			coroutine.yield(autoEngage)
		end
	elseif rightStick:getButtonHeld(3) then
		coroutine.resume(autoEngage)
		if rightStick:getButtonReleased(3) then
			coroutine.yield(autoEngage)
		end
	end

	if gamepad:getRightStickY() > 0 then
		Lyon:setTargetAngle(Lyon.NODE_ANGLE_HIGH)
	elseif gamepad:getRightStickY() < 0 then
		Lyon:setTargetAngle(0.1)
	else
		Lyon:setTargetAngle(Lyon:getAngle())
	end

	local pose, timestamp = poseEst:update()

	if pose ~= nil then
		pe:AddVisionMeasurement(pose.position.x, pose.position.y, pose.rotation.z, timestamp)
	end

	pose, timestamp = poseEst2:update()

	if pose ~= nil then
		pe:AddVisionMeasurement(pose.position.x, pose.position.y, pose.rotation.z, timestamp)
	end
end

function Robot.autonomousInit()
end

function Robot.autonomousPeriodic()
end

function Robot.teleopInit() end

function Robot.teleopPeriodic()
	Drivetrain:drive(squareInput(leftStick:getY()) * 0.5, -squareInput(rightStick:getX()) * 0.5)
end

