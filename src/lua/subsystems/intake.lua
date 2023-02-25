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

Any angle whose magnitude (absolute value) is less than OUTSIDE_ANGLE is
considered inside the robot. Angles with magnitude greater than that threshold
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
- The arm must never extend beyond 57.875in.
- When the arm angle is between -OUTSIDE_ANGLE and OUTSIDE_ANGLE, the arm must
  be fully retracted.
	- (There will be a small exception to this rule that we will handle later.)
- If the arm is extended past 35in, and 0 <= arm angle <= OUTSIDE_ANGLE, the
  arm angle motor speed must be greater than or equal to 0.
- If the arm is extended past 35in, and -OUTSIDE_ANGLE <= arm angle <= 0, the
  arm angle motor speed must be less than or equal to 0.
- The arm angle must never exceed 1.8rad in either direction.

--]]

Lyon = {}

Lyon.AXLE_HEIGHT = 40
Lyon.NODE_ANGLE_MID = 1.57
Lyon.NODE_ANGLE_HIGH = 1.78
Lyon.MIN_EXTENSION = 35
Lyon.MAX_EXTENSION = 57.875

local OUTSIDE_ANGLE = 0.6
local ANGLE_MOTOR_MAX_SPEED = 0.2
local TA_MOTOR_MAX_SPEED = 0.5

local arm = CANSparkMax:new(20, SparkMaxMotorType.kBrushless)
---@type SparkMaxRelativeEncoder
local armEncoder = arm:getEncoder()
armEncoder:setPositionConversionFactor(1)
local telescopingArm = CANSparkMax:new(23, SparkMaxMotorType.kBrushless) -- TODO: not a real device id
telescopingArm:setInverted(true)
---@type SparkMaxRelativeEncoder
local telescopingEncoder = telescopingArm:getEncoder()
gripperSolenoid = DoubleSolenoid:new(0, 1) --TODO: not a real device id

local targetExtension = Lyon.MIN_EXTENSION
local targetAngle = 0

---Computes how far the arm should extend in order to reach the ground. Formula: 40" / cos(angle).
---@param angle number The angle of the arm, in radians. You should probably call `Lyon:getAngle()` to get this value.
---@return number
local function extensionToGround(angle)
	if math.cos(angle) <= 0 then
		return Lyon.MAX_EXTENSION
	end

	return math.min(40 / math.cos(angle), Lyon.MAX_EXTENSION)
end

---Computes the maximum length in inches to which the arm may extend.
---@param angle number The angle of the arm, in radians. You should probably call `Lyon:getAngle()` to get this value.
---@return number
local function maxSafeExtension(angle)
	local MAX_SAFE = Lyon.MIN_EXTENSION + 2

	if math.abs(angle) > OUTSIDE_ANGLE then -- if outside frame
		MAX_SAFE = extensionToGround(angle)
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
		armSpeed = sign(target - angle) * ANGLE_MOTOR_MAX_SPEED
	end

	if angle >= Lyon.NODE_ANGLE_HIGH then
		armSpeed = math.min(armSpeed, 0)
	elseif angle <= -Lyon.NODE_ANGLE_HIGH then
		armSpeed = math.max(armSpeed, 0)
	end

	if extension > Lyon.MIN_EXTENSION + 2 then
		if 0 < angle and  angle <= OUTSIDE_ANGLE then
			armSpeed = math.max(armSpeed, 0)
		elseif -OUTSIDE_ANGLE <= angle and angle < 0 then
			armSpeed = math.min(armSpeed, 0)
		end
	end

	-- temporary
	
	if angle < 0.1 then
		armSpeed = math.max(armSpeed, 0)
	end

	return armSpeed
end

---Computes the output speed of the telescope motor, respecting safety constraints.
---@param target number
---@param extension number
---@param angle number
local function teleMotorOutputSpeed(target, extension, angle)
	target = math.min(target, maxSafeExtension(angle))

	local outSpeed = 0

	if math.abs(target - extension) > 1 then
		outSpeed = sign(target - extension) * TA_MOTOR_MAX_SPEED
	end

	return outSpeed
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

function Lyon:periodic()
	SmartDashboard:putNumber("LyonAngleTarget", targetAngle)
	SmartDashboard:putNumber("LyonTeleTarget", targetExtension)
	SmartDashboard:putNumber("LyonAnglePos", Lyon:getAngle())
	SmartDashboard:putNumber("LyonRawAnglePos", getAngleMotorRawPosition())
	SmartDashboard:putNumber("LyonTelePos", Lyon:getExtension())
	SmartDashboard:putNumber("LyonRawTelePos", getExtensionMotorRawPosition())

	local armSpeed = angleMotorOutputSpeed(targetAngle, Lyon:getAngle(), Lyon:getExtension())
	SmartDashboard:putNumber("LyonArmSpeed", armSpeed)
	arm:set(armSpeed)
	
	local teleSpeed = teleMotorOutputSpeed(targetExtension, Lyon:getExtension(), Lyon:getAngle())
	SmartDashboard:putNumber("LyonTeleSpeed", teleSpeed)
	telescopingArm:set(teleSpeed)
end

---Gets the angle of the arm, in radians. Positive angle is toward the front of the robot; negative angle is toward the back.
---@return number
function Lyon:getAngle()
	return armEncoder:getPosition() * (math.pi / 155.4955)
end

---Gets the length of the arm in inches, from the center axle to the tip of the gripper.
---@return number
function Lyon:getExtension()
	return (telescopingEncoder:getPosition() / 18) * math.pi + Lyon.MIN_EXTENSION
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
function Lyon:gripperSolenoid(doGrip)
	gripperSolenoid:set(doGrip)
end

test("Lyon safety constraints", function(t)
	-- hanging straight down
	t:assert(angleMotorOutputSpeed(math.pi/2, 0, 0) > 0, "straight down, not extended, swing forward")
	t:assert(angleMotorOutputSpeed(-math.pi/2, 0, 0) < 0, "straight down, not extended, swing backward")
	t:assertEqual(extensionToGround(0), Lyon.AXLE_HEIGHT)
	t:assert(maxSafeExtension(0) < Lyon.MIN_EXTENSION + 3, "safe extension when inside the robot")
	t:assert(teleMotorOutputSpeed(Lyon.MIN_EXTENSION, Lyon.MIN_EXTENSION + 2, 0) <= 0, "retract when inside the robot")

	-- straight forward
	t:assert(angleMotorOutputSpeed(math.pi, math.pi/2, 0) > 0, "straight forward, not extended, swing forward")
	t:assert(angleMotorOutputSpeed(-math.pi/2, math.pi/2, 0) < 0, "straight forward, not extended, swing backward")
	t:assert(extensionToGround(math.pi/2) < 100, "no crazy extensionToGround (forward)")
	t:assertEqual(maxSafeExtension(math.pi/2), Lyon.MAX_EXTENSION, "safe extension when outside the robot, forward")
	t:assert(teleMotorOutputSpeed(Lyon.MIN_EXTENSION, Lyon.MAX_EXTENSION, math.pi/2) <= 0, "retract when outside the robot, forward")
	t:assert(teleMotorOutputSpeed(Lyon.MAX_EXTENSION, Lyon.MIN_EXTENSION, math.pi/2) >= 0, "extend when outside the robot, forward")

	-- straight backward
	t:assert(angleMotorOutputSpeed(math.pi/2, -math.pi/2, 0) > 0, "straight backward, not extended, swing forward")
	t:assert(angleMotorOutputSpeed(-math.pi, -math.pi/2, 0) < 0, "straight backward, not extended, swing backward")
	t:assert(extensionToGround(-math.pi/2) < 100, "no crazy extensionToGround (backward)")
	t:assertEqual(maxSafeExtension(-math.pi/2), Lyon.MAX_EXTENSION, "safe extension when outside the robot, backward")
	t:assert(teleMotorOutputSpeed(Lyon.MIN_EXTENSION, Lyon.MAX_EXTENSION, -math.pi/2) <= 0, "retract when outside the robot, backward")
	t:assert(teleMotorOutputSpeed(Lyon.MAX_EXTENSION, Lyon.MIN_EXTENSION, -math.pi/2) >= 0, "extend when outside the robot, backward")

	-- on the edge
	t:assertEqual(angleMotorOutputSpeed(0, -OUTSIDE_ANGLE, Lyon.MIN_EXTENSION), ANGLE_MOTOR_MAX_SPEED, "arm entering frame retracted, forward")
	t:assertEqual(angleMotorOutputSpeed(0, -OUTSIDE_ANGLE, Lyon.MAX_EXTENSION), 0, "arm entering frame extended, forward")
	t:assertEqual(angleMotorOutputSpeed(0, OUTSIDE_ANGLE, Lyon.MIN_EXTENSION), -ANGLE_MOTOR_MAX_SPEED, "arm entering frame retracted, backward")
	t:assertEqual(angleMotorOutputSpeed(0, OUTSIDE_ANGLE, Lyon.MAX_EXTENSION), 0, "arm entering frame extended, backward")

	-- too far
	t:assertEqual(angleMotorOutputSpeed(0, Lyon.NODE_ANGLE_HIGH, Lyon.MIN_EXTENSION), -ANGLE_MOTOR_MAX_SPEED, "on the outer limit returning, forward")
	t:assertEqual(angleMotorOutputSpeed(0, -Lyon.NODE_ANGLE_HIGH, Lyon.MIN_EXTENSION), ANGLE_MOTOR_MAX_SPEED, "on the outer limit returning, backward")
	t:assertEqual(angleMotorOutputSpeed(Lyon.NODE_ANGLE_HIGH + 1, Lyon.NODE_ANGLE_HIGH, Lyon.MIN_EXTENSION), 0, "on the outer limit continuing, forward")
	t:assertEqual(angleMotorOutputSpeed(-Lyon.NODE_ANGLE_HIGH - 1, -Lyon.NODE_ANGLE_HIGH, Lyon.MIN_EXTENSION), 0, "on the outer limit continuing, backward")
	t:assertEqual(angleMotorOutputSpeed(0, Lyon.NODE_ANGLE_HIGH + 1, Lyon.MIN_EXTENSION), -ANGLE_MOTOR_MAX_SPEED, "past the outer limit returning, forward")
	t:assertEqual(angleMotorOutputSpeed(0, -Lyon.NODE_ANGLE_HIGH - 1, Lyon.MIN_EXTENSION), ANGLE_MOTOR_MAX_SPEED, "past the outer limit returning, backward")
	t:assertEqual(angleMotorOutputSpeed(Lyon.NODE_ANGLE_HIGH + 2, Lyon.NODE_ANGLE_HIGH + 1, Lyon.MIN_EXTENSION), 0, "past the outer limit continuing, forward")
	t:assertEqual(angleMotorOutputSpeed(-Lyon.NODE_ANGLE_HIGH - 2, -Lyon.NODE_ANGLE_HIGH - 1, Lyon.MIN_EXTENSION), 0, "past the outer limit continuing, backward")
end)
