require("subsystems.drivetrain")
require("subsystems.intake")
require("utils.vector")
require("utils.DDPE")
require("utils.path")
require("utils.purepursuit")
require("wpilib.dashboard")

leftStick = Joystick:new(0)
rightStick = Joystick:new(1)
gamepad = Joystick:new(2)

navx = AHRS:new(4)

-----------------------------------

local camera = PhotonCamera:new("HD_USB_Camera")
local poseEst = PhotonPoseEstimator:new(getDeployDirectory() .. "/fakefield.json", PoseStrategy.MULTI_TAG_PNP, camera, Transform3d:new(Translate3d:new(10.75, 7, 21), Rotate3d:new(0, 0, 0)))

local pe = DDPE:new(Drivetrain:yaw(), Drivetrain:leftPosition(), Drivetrain:rightPosition(), 0, 0, 0)

local path = Path:new("Test")
local pp = PurePursuit:new(path, 0.1, 0, 0)

local field = Field2d:new()

local speed, turn

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
end

function Robot.autonomousPeriodic()
	Drivetrain:drive(clamp(-speed, -0.2, 0.2),clamp(-turn, -0.2, 0.2))
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
		Lyon:setTargetPosition(60, 64)
	elseif gamepad:getButtonHeld(XboxButton.B) then
		Lyon:setTargetPosition(20, 0)
	else
		Lyon:setTargetPosition(0,20)
	end

end

