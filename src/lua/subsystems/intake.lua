require("utils.teleopcoroutine")
require("utils.math")
require("wpilib.dashboard")

--[[

===============================================================================
                                2023 LYON SPEC
===============================================================================

The Lyon system needs to always respect physical limits so that it does not run
into the ground or into the robot. These constraints must be maintained no
matter what we tell it to do in robot.lua.

The following functions must all be implemented and tested on the simulator
before running on the actual robot. For each, check the corresponding boxes
only when you have performed the specified tests.

-------------------------------------------------------------------------------
OVERVIEW

All the core logic of the core Lyon system will be performed in Lyon:periodic.
This is to ensure that safety checks are always running - if safety checks are
only performed in specific functions, we risk bypassing checks because certain
functions were not called.

Only specific functions will be put on the Lyon global object. Functions on the
Lyon object are callable everywhere and should therefore be carefully crafted
so they are always safe to call.

The zero angle on Lyon is hanging straight down. Positive angle raises the arm
toward the front of the bot. Negative angle raises the arm toward the back of
the bot.

Any angle whose magnitude (absolute value) is less than THRESH is considered
inside the robot. Angles with magnitude greater than that threshold
are outside.

-------------------------------------------------------------------------------
IMPORTANT VALUES

These values were determined from the CAD and are defined as constants below.

- Inside/outside angle threshold: 34.2deg = 0.6rad
- Mid peg angle: 90deg = 1.57rad
- High peg angle: 102deg = 1.78rad
- Height of Lyon's axle from the ground: 40in
- Length of arm (axle to tip) when collapsed: 33in
- Length of arm (axle to tip) when fully extended: 57.875in
- Total arm extension (max - min): 24.875in

-------------------------------------------------------------------------------
CONSTRAINTS

Lyon must always respect the following constraints:

- The arm must never extend beyond ground level. (See extensionToGround.)
- When the arm angle is between -OUTSIDE_ANGLE and OUTSIDE_ANGLE, the arm must
  be fully retracted.
	- (There will be a small exception to this rule that we will handle later.)
- If the arm is extended past 35in, and 0 <= arm angle <= OUTSIDE_ANGLE, the
  arm angle motor speed must be greater than or equal to 0.
- If the arm is extended past 35in, and -OUTSIDE_ANGLE <= arm angle <= 0, the
  arm angle motor speed must be less than or equal to 0.
- The arm angle must never exceed 1.8rad in either direction.

--]]

local OUTSIDE_ANGLE = 0.6
local AXLE_HEIGHT = 40
local ANGLE_MOTOR_MAX_SPEED = 0.2
local TA_MOTOR_MAX_SPEED = 0.2

--TODO: refine values or figure out what they actually are
local TA_OUT_POSITION = 1
local TA_IN_POSITION = -1

local arm = CANSparkMax:new(23, SparkMaxMotorType.kBrushless)
---@type SparkMaxRelativeEncoder
local armEncoder = arm:getEncoder()
armEncoder:setPositionConversionFactor(1)
local telescopingArm = CANSparkMax:new(0, SparkMaxMotorType.kBrushless) -- TODO: not a real device id
---@type SparkMaxRelativeEncoder
local telescopingEncoder = telescopingArm:getEncoder()
local gripperSolenoid = Solenoid:new(0) --TODO: not a real device id

--TODO: refine values
local lyonUpSpeed = 0.2
local lyonMidSpeed = 0
local lyonDownSpeed = 0.2

local lyonUpPosition = math.pi / 4
local lyonMidPosition = 0
local lyonDownPosition = -math.pi / 4
-- so i wanna put smth here to just set various postions but idk the implementation so ima do it later

local targetExtension
local targetAngle

---Computes how far the arm should extend in order to reach the ground. Formula: 40" / cos(angle).
---@param angle number The angle of the arm, in radians. You should probably call `Lyon:getAngle()` to get this value.
---@return number
local function extensionToGround(angle)
	return 40 / math.cos(angle)
end

---Computes the maximum length in inches to which the arm may extend.
---@param angle number The angle of the arm, in radians. You should probably call `Lyon:getAngle()` to get this value.
---@return number
local function maxSafeExtension(angle)
	local MAX_SAFE
	if angle > 30 then
		MAX_SAFE = 40 / math.cos(angle)
	else
		MAX_SAFE = 0
	end
	return MAX_SAFE
end

---Computes the output speed of the angle motor, respecting safety constraints.
---@param target number
---@param angle number
---@param extension number
---@return number
local function angleMotorOutputSpeed(target, angle, extension)
	local armSpeed = 0
	if math.abs(target - angle) > 0.05 then -- 0.05 radians is roughly 3 degrees
		armSpeed = -sign(target - angle) * ANGLE_MOTOR_MAX_SPEED
	end

	if Lyon:getAngle() >= 1.8 then
		armSpeed = math.min(armSpeed, 0)
	elseif Lyon:getAngle() <= -1.8 then
		armSpeed = math.max(armSpeed, 0)
	end

	if Lyon:getAngle() <= OUTSIDE_ANGLE and Lyon:getAngle() > 0 then
		armSpeed = math.max(armSpeed, 0)
	elseif Lyon:getAngle() >= -OUTSIDE_ANGLE and Lyon:getAngle() < 0 then
		armSpeed = math.min(armSpeed, 0)
	end

	return armSpeed
end

---Gets the raw encoder position from the arm angle motor. Unit: revolutions.
---@return number
local function getAngleMotorRawPosition()
	return armEncoder:getPosition()
end

---Gets the raw encoder position from the telescoping arm motor. Unit: revolutions.
---@return number
local function getExtensionMotorRawPosition()
	return telescopingEncoder:getPosition()
end

-- Everything below this point is public and must be safe to call at all times.

Lyon = {}

Lyon.NODE_ANGLE_MID = 1.57
Lyon.NODE_ANGLE_HIGH = 1.78

function Lyon:periodic()
	SmartDashboard:putNumber("LyonPos", Lyon:getAngle())
	SmartDashboard:putNumber("LyonRawPos", getAngleMotorRawPosition())
	SmartDashboard:putNumber("LyonOutput", arm:get())
	local armSpeed
	-- TODO: Drive all the motors

	armSpeed = angleMotorOutputSpeed(targetAngle, Lyon:getAngle(), targetExtension)


	arm:set(armSpeed)

	
	local extension = targetExtension

	if Lyon:getExtension() >= 35 and (0 <= Lyon:getAngle() <= OUTSIDE_ANGLE) then
		armSpeed = math.max(armSpeed, 0)
		telescopingArm = math.max(TA_MOTOR_MAX_SPEED, 0)
	end

	if Lyon:getExtension() >= 35 and (-OUTSIDE_ANGLE <= Lyon:getAngle() <= 0) then
		armSpeed = math.min(armSpeed, 0)
		telescopingArm = math.min(TA_MOTOR_MAX_SPEED, 0)
	end

end

---Gets the angle of the arm, in radians. Positive angle is toward the front of the robot; negative angle is toward the back.
---@return number
function Lyon:getAngle()
	return armEncoder:getPosition() * (math.pi / 155.4955)
end

---Gets the length of the arm in inches, from the center axle to the tip of the gripper.
---@return number
function Lyon:getExtension()
	return (telescopingEncoder:getPosition() / 18) * math.pi + 35
end

---Sets the desired arm angle, in radians.
---@param target number
function Lyon:setTargetAngle(target)
	targetAngle = target
end

---Sets the desired arm extension, in inches. This is the distance from the axle to the tip of the gripper.
---@param target number
function Lyon:setTargetExtension(target)
	targetExtension = target
end

---Opens or closes the gripper.
---@param doGrip boolean
function Lyon:gripperSolenoid(doGrip)
	gripperSolenoid:set(doGrip)
end

test("angleMotorOutputSpeed", function(t)
	t:assert(angleMotorOutputSpeed(math.pi/2, 0, 0) > 0)
	t:assert(angleMotorOutputSpeed(-math.pi/2, 0, 0) < 0)
end)
