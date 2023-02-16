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
local armEncoder = arm:getEncoder()
armEncoder:setPositionConversionFactor(1)
local telescopingArm = CANSparkMax:new(0, SparkMaxMotorType.kBrushless) -- TODO: not a real device id
local gripperSolonoid = Solonoid:new(0) --TODO: not a real device id

--TODO: refine values
local lyonUpSpeed = 0.2
local lyonMidSpeed = 0
local lyonDownSpeed = 0.2

local lyonUpPosition = math.pi / 4
local lyonMidPosition = 0
local lyonDownPosition = -math.pi / 4
-- so i wanna put smth here to just set various postions but idk the implementation so ima do it later

---Computes how far the arm should extend in order to reach the ground. Formula: 40" / cos(angle).
---@param angle number The angle of the arm, in radians. You should probably call `Lyon:getAngle()` to get this value.
---@return number
local function extensionToGround(angle)
	error("not implemented")
end

---Computes the maximum length in inches to which the arm may extend.
---@param angle number The angle of the arm, in radians. You should probably call `Lyon:getAngle()` to get this value.
---@return number
local function maxSafeExtension(angle)
	error("not implemented")
end

---Computes the output speed of the angle motor, respecting safety constraints.
---@param targetAngle number
---@param angle number
---@param extension number
---@return number
local function angleMotorOutputSpeed(targetAngle, angle, extension)
	error("not implemented")
end

---Gets the raw encoder position from the arm angle motor. Unit: revolutions.
---@return number
local function getAngleMotorRawPosition()
	return armEncoder:getPosition()
end

---Gets the raw encoder position from the telescoping arm motor. Unit: revolutions.
---@return number
local function getExtensionMotorRawPosition()
	error("not implemented")
end

-- Everything below this point is public and must be safe to call at all times.

Lyon = {}

Lyon.NODE_ANGLE_MID = 1.57
Lyon.NODE_ANGLE_HIGH = 1.78

function Lyon:periodic()
	SmartDashboard:putNumber("LyonPos", Lyon:getAngle())
	SmartDashboard:putNumber("LyonRawPos", getAngleMotorRawPosition())
	SmartDashboard:putNumber("LyonOutput", arm:get())

	-- TODO: Drive all the motors
end

---Gets the angle of the arm, in radians. Positive angle is toward the front of the robot; negative angle is toward the back.
---@return number
function Lyon:getAngle()
	-- return armEncoder:getPosition() * (2.5 * 2 * math.pi) / (50 * 13)
	return armEncoder:getPosition() * (math.pi / 155.4955)
end

---Gets the length of the arm in inches, from the center axle to the tip of the gripper.
---@return number
function Lyon:getExtension()
	error("not implemented")
end

---Sets the desired arm angle, in radians.
---@param angle number
function Lyon:setTargetAngle(angle)
	error("not implemented")
end

---Sets the desired arm extension, in inches. This is the distance from the axle to the tip of the gripper.
---@param extension number
function Lyon:setTargetExtension(extension)
	error("not implemented")
end

---Opens or closes the gripper.
---@param doGrip boolean
function Lyon:grip(doGrip)
	error("not implemented")
end

function telescopingArm:out()
	if self:getPosition() < TA_OUT_POSITION then
		telescopingArm:set(TA_MOTOR_MAX_SPEED)
	else
		telescopingArm:set(0)
	end
end

function gripperSolonoid:open()
	gripperSolonoid:set(true)
end

function grip:close()
	gripperSolonoid:set(false)
end

test("angleMotorOutputSpeed", function(t)
	t:assert(angleMotorOutputSpeed(math.pi/2, 0, 0) > 0)
	t:assert(angleMotorOutputSpeed(-math.pi/2, 0, 0) < 0)
end)
