require("utils.teleopcoroutine")
require("utils.math")
require("utils.pid")
require("wpilib.dashboard")
require("utils.vector")

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
Lyon.NODE_ANGLE_HIGH = 1.89
Lyon.MIN_EXTENSION = 31.5
Lyon.MAX_EXTENSION = 63
Lyon.EXTENSION_ANGLE_THRESHOLD_RADIANS = 0.2
Lyon.HIGH_PRESET = Vector:new(62, 73)
Lyon.MID_PRESET = Vector:new(43.75, 46)
Lyon.LOW_PRESET = Vector:new(34, 13)
Lyon.SUBSTATION_PRESET = Vector:new(27, ((3*12) + 9))
Lyon.NEUTRAL = Vector:new(6, 20)
Lyon.HIGH_REAR = Vector:new(-62, 73)
Lyon.MID_REAR = Vector:new(-43.75, 46)
Lyon.LOW_REAR = Vector:new(-34, 13)
Lyon.SUBSTATION_REAR = Vector:new(-29, ((3*12) + 10))

local OUTSIDE_ANGLE_FRONT = 0.1
local OUTSIDE_ANGLE_BACK = -0.6
local MAX_EXTENSION_WHEN_INSIDE = Lyon.MIN_EXTENSION
local ANGLE_MOTOR_MAX_SPEED = 1
local TA_MOTOR_MAX_SPEED = 1

local arm = CANSparkMax:new(23, SparkMaxMotorType.kBrushless)
local armEncoder = arm:getEncoder()
local telescopingArm = CANSparkMax:new(22, SparkMaxMotorType.kBrushless)
telescopingArm:setInverted(false)
local telescopingEncoder = telescopingArm:getEncoder()
gripperSolenoid = DoubleSolenoid:new(0, 1)

local anglePid = PIDController:new(1 / 0.2, 0.25, 0.35)
local telePid = PIDController:new(1 / 2, 0, 0)

local targetExtension = Lyon.MIN_EXTENSION
local targetAngle = 0

local overrideSlowdownWhenExtended = false

---Computes how far the arm should extend in order to reach the ground. Formula: 40" / cos(angle).
---@param angle number The angle of the arm, in radians. You should probably call `Lyon:getAngle()` to get this value.
---@return number
local function extensionToGround(angle)
	if math.cos(angle) <= 0 then
		return Lyon.MAX_EXTENSION
	end

	-- the arm sags. this is a dumb hack to keep the claw off the ground.
	local fudge = 16 * (-math.cos(angle) + 1) / 2
	SmartDashboard:putNumber("LyonExtensionFudge", fudge)

	return clamp((Lyon.AXLE_HEIGHT - 0.5) / math.cos(angle) - fudge, Lyon.MIN_EXTENSION, Lyon.MAX_EXTENSION)
end

---Computes the maximum length in inches to which the arm may extend.
---@param angle number The angle of the arm, in radians. You should probably call `Lyon:getAngle()` to get this value.
---@return number
local function maxSafeExtension(angle)
	local MAX_SAFE = MAX_EXTENSION_WHEN_INSIDE

	if angle < OUTSIDE_ANGLE_BACK or OUTSIDE_ANGLE_FRONT < angle then -- if outside frame
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
	local speedWhenExtended = 1 / 10
	local curviness = 10

	local relativeExtension = (extension - Lyon.MIN_EXTENSION) / Lyon.MAX_EXTENSION
	local armMultiplier = (1 - speedWhenExtended) * signedPow(1-relativeExtension, curviness) + speedWhenExtended
	if overrideSlowdownWhenExtended then
		armMultiplier = 1 -- be careful!!
	end

	local armSpeed = anglePid:pid(angle, target, 0.3, math.pi, ANGLE_MOTOR_MAX_SPEED * armMultiplier)

	if angle >= Lyon.NODE_ANGLE_HIGH then
		armSpeed = math.min(armSpeed, 0)
	elseif angle <= -Lyon.NODE_ANGLE_HIGH then
		armSpeed = math.max(armSpeed, 0)
	end

	if extension > Lyon.MIN_EXTENSION + 2 then
		if 0 < angle and  angle <= OUTSIDE_ANGLE_FRONT then
			armSpeed = math.max(armSpeed, 0)
		elseif OUTSIDE_ANGLE_BACK <= angle and angle < 0 then
			armSpeed = math.min(armSpeed, 0)
		end
	end

	return armSpeed * armMultiplier
end

---Computes the output speed of the telescope motor, respecting safety constraints.
---@param target number
---@param extension number
---@param angle number
---@param angleTarget number
local function teleMotorOutputSpeed(target, extension, angle, angleTarget)
	target = clamp(target, Lyon.MIN_EXTENSION, maxSafeExtension(angle))

	if math.abs(angleTarget - angle) > Lyon.EXTENSION_ANGLE_THRESHOLD_RADIANS then
		target = Lyon.MIN_EXTENSION
	end

	return clampMag(telePid:pid(extension, target, 1), 0, TA_MOTOR_MAX_SPEED)
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
	SmartDashboard:putNumber("LyonExtensionToGround", extensionToGround(Lyon:getAngle()))

	local armSpeed = angleMotorOutputSpeed(targetAngle, Lyon:getAngle(), Lyon:getExtension())

	SmartDashboard:putNumber("LyonArmSpeed", armSpeed)
	arm:set(armSpeed)

	local teleSpeed = teleMotorOutputSpeed(targetExtension, Lyon:getExtension(), Lyon:getAngle(), targetAngle)
	SmartDashboard:putNumber("LyonTeleSpeed", teleSpeed)
	telescopingArm:set(teleSpeed)

	anglePid:updateTime(Timer:getFPGATimestamp())
	telePid:updateTime(Timer:getFPGATimestamp())

	overrideSlowdownWhenExtended = false
end

---Gets the angle of the arm, in radians. Positive angle is toward the front of the robot; negative angle is toward the back.
---@return number
function Lyon:getAngle()
	return armEncoder:getPosition() * (math.pi / 155.4955)
end

---Gets the length of the arm in inches, from the center axle to the tip of the gripper.
---@return number
function Lyon:getExtension()
	return 1.25 * (telescopingEncoder:getPosition() / 14.2) * math.pi + Lyon.MIN_EXTENSION
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

function Lyon:openGripper()
	gripperSolenoid:set(DoubleSolenoidValue.Reverse)
end

function Lyon:closeGripper()
	gripperSolenoid:set(DoubleSolenoidValue.Forward)
end

---@param x number
---@param y number
function Lyon:setTargetPosition(x, y)
	local position = Vector:new(x, y) - Vector:new(0, Lyon.AXLE_HEIGHT)
	position = position:rotate(math.pi / 2)
	local angle = math.atan2(position.y, position.x)
	local extension = position:length()

	self:setTargetAngle(angle)
	self:setTargetExtension(extension)

	SmartDashboard:putNumber("LyonTargetX", x)
	SmartDashboard:putNumber("LyonTargetY", y)

	return angle, extension
end

---@param preset Vector
function Lyon:setTargetPositionPreset(preset)
	Lyon:setTargetPosition(preset.x, preset.y)
end

function Lyon:overrideSlowdownWhenExtendedThisTick()
	overrideSlowdownWhenExtended = true
end

test("Lyon setTarget", function (t)
	local angle, extension

	angle, extension = Lyon:setTargetPosition(0, 0)
	t:assertEqual(angle, 0, "straigt down angle")
	t:assertEqual(extension, 40, "straigt down extension")

	angle, extension = Lyon:setTargetPosition(40, 40)
	t:assertEqual(angle, math.pi / 2, "straigt forward angle")
	t:assertEqual(extension, 40, "straigt forward extension")

	angle, extension = Lyon:setTargetPosition(-40, 40)
	t:assertEqual(angle, -math.pi / 2, "straigt backward angle")
	t:assertEqual(extension, 40, "straigt backward extension")

	angle, extension = Lyon:setTargetPosition(40, 0)
	t:assertEqual(angle, math.pi / 4, "diagonal forward angle")
	t:assertEqual(extension, math.sqrt(40 ^ 2 + 40 ^ 2), "diagonal forward extension")

	angle, extension = Lyon:setTargetPosition(-40, 0)
	t:assertEqual(angle, -math.pi / 4, "diagonal forward angle")
	t:assertEqual(extension, math.sqrt(40 ^ 2 + 40 ^ 2), "diagonal forward extension")
end)

test("Lyon safety constraints", function(t)
	-- hanging straight down
	anglePid:clear(Timer:getFPGATimestamp())
	t:assert(angleMotorOutputSpeed(math.pi/2, 0, 0) > 0, "straight down, not extended, swing forward")
	anglePid:clear(Timer:getFPGATimestamp())
	t:assert(angleMotorOutputSpeed(-math.pi/2, 0, 0) < 0, "straight down, not extended, swing backward")
	t:assertEqual(extensionToGround(0), Lyon.AXLE_HEIGHT - 2)
	t:assert(maxSafeExtension(0) < Lyon.MIN_EXTENSION + 3, "safe extension when inside the robot")
	telePid:clear(Timer:getFPGATimestamp())
	t:assert(teleMotorOutputSpeed(Lyon.MIN_EXTENSION, Lyon.MIN_EXTENSION + 2, 0, 0) <= 0, "retract when inside the robot")

	-- straight forward
	anglePid:clear(Timer:getFPGATimestamp())
	t:assert(angleMotorOutputSpeed(math.pi, math.pi/2, 0) > 0, "straight forward, not extended, swing forward")
	anglePid:clear(Timer:getFPGATimestamp())
	t:assert(angleMotorOutputSpeed(-math.pi/2, math.pi/2, 0) < 0, "straight forward, not extended, swing backward")
	t:assert(extensionToGround(math.pi/2) < 100, "no crazy extensionToGround (forward)")
	t:assertEqual(maxSafeExtension(math.pi/2), Lyon.MAX_EXTENSION, "safe extension when outside the robot, forward")
	telePid:clear(Timer:getFPGATimestamp())
	t:assert(teleMotorOutputSpeed(Lyon.MIN_EXTENSION, Lyon.MAX_EXTENSION, math.pi/2, math.pi/2) <= 0, "retract when outside the robot, forward")
	telePid:clear(Timer:getFPGATimestamp())
	t:assert(teleMotorOutputSpeed(Lyon.MAX_EXTENSION, Lyon.MIN_EXTENSION, math.pi/2, math.pi/2) >= 0, "extend when outside the robot, forward")

	-- straight backward
	anglePid:clear(Timer:getFPGATimestamp())
	t:assert(angleMotorOutputSpeed(math.pi/2, -math.pi/2, 0) > 0, "straight backward, not extended, swing forward")
	anglePid:clear(Timer:getFPGATimestamp())
	t:assert(angleMotorOutputSpeed(-math.pi, -math.pi/2, 0) < 0, "straight backward, not extended, swing backward")
	t:assert(extensionToGround(-math.pi/2) < 100, "no crazy extensionToGround (backward)")
	t:assertEqual(maxSafeExtension(-math.pi/2), Lyon.MAX_EXTENSION, "safe extension when outside the robot, backward")
	telePid:clear(Timer:getFPGATimestamp())
	t:assert(teleMotorOutputSpeed(Lyon.MIN_EXTENSION, Lyon.MAX_EXTENSION, -math.pi/2, -math.pi/2) <= 0, "retract when outside the robot, backward")
	telePid:clear(Timer:getFPGATimestamp())
	t:assert(teleMotorOutputSpeed(Lyon.MAX_EXTENSION, Lyon.MIN_EXTENSION, -math.pi/2, -math.pi/2) >= 0, "extend when outside the robot, backward")

	-- on the edge
	anglePid:clear(Timer:getFPGATimestamp())
	t:assert(angleMotorOutputSpeed(0, OUTSIDE_ANGLE_BACK, Lyon.MIN_EXTENSION) > 0, "arm entering frame retracted, forward")
	anglePid:clear(Timer:getFPGATimestamp())
	t:assertEqual(angleMotorOutputSpeed(0, OUTSIDE_ANGLE_BACK, Lyon.MAX_EXTENSION), 0, "arm entering frame extended, forward")
	anglePid:clear(Timer:getFPGATimestamp())
	t:assert(angleMotorOutputSpeed(0, OUTSIDE_ANGLE_FRONT, Lyon.MIN_EXTENSION) < 0, "arm entering frame retracted, backward")
	anglePid:clear(Timer:getFPGATimestamp())
	t:assertEqual(angleMotorOutputSpeed(0, OUTSIDE_ANGLE_FRONT, Lyon.MAX_EXTENSION), 0, "arm entering frame extended, backward")

	-- too far
	anglePid:clear(Timer:getFPGATimestamp())
	t:assertEqual(angleMotorOutputSpeed(0, Lyon.NODE_ANGLE_HIGH, Lyon.MIN_EXTENSION), -ANGLE_MOTOR_MAX_SPEED, "on the outer limit returning, forward")
	anglePid:clear(Timer:getFPGATimestamp())
	t:assertEqual(angleMotorOutputSpeed(0, -Lyon.NODE_ANGLE_HIGH, Lyon.MIN_EXTENSION), ANGLE_MOTOR_MAX_SPEED, "on the outer limit returning, backward")
	anglePid:clear(Timer:getFPGATimestamp())
	t:assertEqual(angleMotorOutputSpeed(Lyon.NODE_ANGLE_HIGH + 1, Lyon.NODE_ANGLE_HIGH, Lyon.MIN_EXTENSION), 0, "on the outer limit continuing, forward")
	anglePid:clear(Timer:getFPGATimestamp())
	t:assertEqual(angleMotorOutputSpeed(-Lyon.NODE_ANGLE_HIGH - 1, -Lyon.NODE_ANGLE_HIGH, Lyon.MIN_EXTENSION), 0, "on the outer limit continuing, backward")
	anglePid:clear(Timer:getFPGATimestamp())
	t:assertEqual(angleMotorOutputSpeed(0, Lyon.NODE_ANGLE_HIGH + 1, Lyon.MIN_EXTENSION), -ANGLE_MOTOR_MAX_SPEED, "past the outer limit returning, forward")
	anglePid:clear(Timer:getFPGATimestamp())
	t:assertEqual(angleMotorOutputSpeed(0, -Lyon.NODE_ANGLE_HIGH - 1, Lyon.MIN_EXTENSION), ANGLE_MOTOR_MAX_SPEED, "past the outer limit returning, backward")
	anglePid:clear(Timer:getFPGATimestamp())
	t:assertEqual(angleMotorOutputSpeed(Lyon.NODE_ANGLE_HIGH + 2, Lyon.NODE_ANGLE_HIGH + 1, Lyon.MIN_EXTENSION), 0, "past the outer limit continuing, forward")
	anglePid:clear(Timer:getFPGATimestamp())
	t:assertEqual(angleMotorOutputSpeed(-Lyon.NODE_ANGLE_HIGH - 2, -Lyon.NODE_ANGLE_HIGH - 1, Lyon.MIN_EXTENSION), 0, "past the outer limit continuing, backward")
end)

test("Lyon: traverse from back to inside", function(t)
	--------------------------------------------------------
	-- moving from out back of robot to inside frame - requiring us to go up and over the electronics

	local targetAngle = 0.2
	local targetExtension = extensionToGround(0) - 1
	t:assert(targetExtension > MAX_EXTENSION_WHEN_INSIDE)
	t:assert(targetExtension < extensionToGround(0))

	-- step 1: out back of robot
	anglePid:clear(Timer:getFPGATimestamp())
	t:assert(angleMotorOutputSpeed(targetAngle, OUTSIDE_ANGLE_BACK - 0.5, 40) > 0)
	telePid:clear(Timer:getFPGATimestamp())
	t:assert(teleMotorOutputSpeed(targetExtension, targetExtension, OUTSIDE_ANGLE_BACK - 0.5, targetAngle) <= 0)

	-- step 2: at the wall, extended
	anglePid:clear(Timer:getFPGATimestamp())
	t:assertEqual(angleMotorOutputSpeed(targetAngle, OUTSIDE_ANGLE_BACK + 0.01, 40), 0)
	telePid:clear(Timer:getFPGATimestamp())
	t:assert(teleMotorOutputSpeed(targetExtension, targetExtension, OUTSIDE_ANGLE_BACK + 0.01, targetAngle) < 0)

	-- step 3: at the wall, retracted
	anglePid:clear(Timer:getFPGATimestamp())
	t:assert(angleMotorOutputSpeed(targetAngle, OUTSIDE_ANGLE_BACK + 0.01, Lyon.MIN_EXTENSION) > 0)
	t:assertEqual(maxSafeExtension(OUTSIDE_ANGLE_BACK + 0.01), MAX_EXTENSION_WHEN_INSIDE)
	telePid:clear(Timer:getFPGATimestamp())
	t:assertEqual(teleMotorOutputSpeed(targetExtension, MAX_EXTENSION_WHEN_INSIDE, OUTSIDE_ANGLE_BACK + 0.01, targetAngle), 0)

	-- step 4: at front wall, retracted
	anglePid:clear(Timer:getFPGATimestamp())
	t:assert(angleMotorOutputSpeed(targetAngle, OUTSIDE_ANGLE_FRONT + 0.01, MAX_EXTENSION_WHEN_INSIDE) > 0)
	telePid:clear(Timer:getFPGATimestamp())
	t:assert(teleMotorOutputSpeed(targetExtension, MAX_EXTENSION_WHEN_INSIDE, OUTSIDE_ANGLE_FRONT + 0.01, targetAngle) > 0)

	-- step 5: at front wall, extended
	anglePid:clear(Timer:getFPGATimestamp())
	t:assert(angleMotorOutputSpeed(targetAngle, OUTSIDE_ANGLE_FRONT + 0.01, 50) > 0)
	telePid:clear(Timer:getFPGATimestamp())
	t:assertEqual(teleMotorOutputSpeed(targetExtension, targetExtension, OUTSIDE_ANGLE_FRONT + 0.01, targetAngle), 0)
end)

test("Lyon: traverse from front to back", function(t)
	--------------------------------------------------------
	-- moving from out back of robot to inside frame - requiring us to go up and over the electronics

	local targetAngle = -0.8
	local targetExtension = extensionToGround(0) - 1
	t:assert(targetExtension > MAX_EXTENSION_WHEN_INSIDE)
	t:assert(targetExtension < extensionToGround(0))

	-- step 1: out front of robot
	anglePid:clear(Timer:getFPGATimestamp())
	t:assert(angleMotorOutputSpeed(targetAngle, OUTSIDE_ANGLE_FRONT + 0.5, 40) < 0)
	telePid:clear(Timer:getFPGATimestamp())
	t:assert(teleMotorOutputSpeed(targetExtension, targetExtension, OUTSIDE_ANGLE_FRONT + 0.5, targetAngle) <= 0)

	-- step 2: at the wall, extended
	anglePid:clear(Timer:getFPGATimestamp())
	t:assertEqual(angleMotorOutputSpeed(targetAngle, OUTSIDE_ANGLE_FRONT - 0.01, 40), 0)
	telePid:clear(Timer:getFPGATimestamp())
	t:assert(teleMotorOutputSpeed(targetExtension, targetExtension, OUTSIDE_ANGLE_FRONT - 0.01, targetAngle) < 0)

	-- step 3: at the wall, retracted
	anglePid:clear(Timer:getFPGATimestamp())
	t:assert(angleMotorOutputSpeed(targetAngle, OUTSIDE_ANGLE_FRONT - 0.01, Lyon.MIN_EXTENSION) < 0)
	t:assertEqual(maxSafeExtension(OUTSIDE_ANGLE_FRONT - 0.01), MAX_EXTENSION_WHEN_INSIDE)
	telePid:clear(Timer:getFPGATimestamp())
	t:assertEqual(teleMotorOutputSpeed(targetExtension, MAX_EXTENSION_WHEN_INSIDE, OUTSIDE_ANGLE_FRONT - 0.01, targetAngle), 0)

	-- step 4: at back wall, retracted
	anglePid:clear(Timer:getFPGATimestamp())
	t:assert(angleMotorOutputSpeed(targetAngle, OUTSIDE_ANGLE_BACK - 0.01, MAX_EXTENSION_WHEN_INSIDE) < 0)
	telePid:clear(Timer:getFPGATimestamp())
	t:assert(teleMotorOutputSpeed(targetExtension, MAX_EXTENSION_WHEN_INSIDE, OUTSIDE_ANGLE_BACK - 0.01, targetAngle) > 0)

	-- step 5: at back wall, extended
	anglePid:clear(Timer:getFPGATimestamp())
	t:assert(angleMotorOutputSpeed(targetAngle, OUTSIDE_ANGLE_BACK - 0.01, 50) < 0)
	telePid:clear(Timer:getFPGATimestamp())
	t:assertEqual(teleMotorOutputSpeed(targetExtension, targetExtension, OUTSIDE_ANGLE_BACK - 0.01, targetAngle), 0)
end)
