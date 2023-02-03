require("subsystems.drivetrain")
require("utils.vector")

local camera = PhotonCamera:new("2175cam")
local poseEst = PhotonPoseEstimator:new(AprilTagField.k2023ChargedUp, PoseStrategy.LOWEST_AMBIGUITY, camera, Transform3d:new())
local field = Field2d:new()

function Robot.robotInit()
	leftStick = Joystick:new(0)
	rightStick = Joystick:new(1)
	---@type Joystick
	gamepad = Joystick:new(2)

	---@type AHRS
	navx = AHRS:new(4)
end

function Robot.robotPeriodic()
	local pose = poseEst:update()
	
	if pose ~= nil then
		field:setRobotPose(pose.position.x, pose.position.y, pose.rotation.z);
		putField(field)
	end
end

function Robot.autonomousInit()
end

function Robot.autonomousPeriodic()
end

function Robot.teleopInit() end

function Robot.teleopPeriodic()
	Drivetrain:drive(squareInput(leftStick:getY()), squareInput(rightStick:getX()))
end
