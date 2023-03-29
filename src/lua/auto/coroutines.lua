require("mocks.dashboard")
require("subsystems.drivetrain")
require("subsystems.brakes")
require("utils.teleopcoroutine")
require("wpilib.dashboard")

local autoChooser = SendableChooser:new()

if isTesting() then
	autoChooser = MockSendableChooser
end

local doNothingAuto = FancyCoroutine:new(function()
end)

local function sleep(timeSeconds)
	local timer = Timer:new()
	timer:start()

	while timer:get() < timeSeconds do
		coroutine.yield()
	end
end

local function driveNInches(driveDistance, speed)
	return FancyCoroutine:new(function()
		local startingPosition = Drivetrain:combinedPosition()

		while math.abs(Drivetrain:combinedPosition() - startingPosition) < driveDistance do
			print("Driving...")
			print("Combined position:", Drivetrain:combinedPosition())
			Drivetrain:autoDrive(speed, 0)
			coroutine:yield()
		end

		print("Done")
		Drivetrain:stop()
	end)
end

local function driveSeconds(time, speed, turn)
	turn = turn or 0
	return FancyCoroutine:new(function()
		local timer = Timer:new()
		timer:start()

		while timer:get() < time do
			Drivetrain:autoDrive(speed, turn)
			coroutine.yield()
		end

		Drivetrain:stop()
	end)
end

local mobilityAuto = FancyCoroutine:new(function()
	driveNInches(12 * 12, -0.5):runUntilDone()
end)

local scoreHigh = FancyCoroutine:new(function()
	Lyon:closeGripper()
	Lyon:setTargetPositionPreset(Lyon.HIGH_PRESET)
	sleep(3)
	Lyon:openGripper()
	sleep(1)
	Lyon:setTargetPositionPreset(Lyon.NEUTRAL)
	sleep(2)
end)

local reverseScoreHigh = FancyCoroutine:new(function()
	Lyon:closeGripper()
	Lyon:setTargetPositionPreset(Lyon.HIGH_REAR)
	sleep(3)
	Lyon:openGripper()
	sleep(1)
	Lyon:setTargetPositionPreset(Lyon.NEUTRAL)
	sleep(2)
end)

local highMobility = FancyCoroutine:new(function()
	scoreHigh:reset()
	mobilityAuto:reset()
	scoreHigh:runUntilDone()
	mobilityAuto:runUntilDone()
end)

local armBalance = FancyCoroutine:new(function()
	Brakes:reverse()
	local xPID = PIDController:new(-0.5, 0, 0)
	local x = 0

	while true do
		Lyon:slowdownWhenExtended(true)
		local pitch = Drivetrain:pitchDegrees()
		if pitch > 5 or pitch < -5 then
			x = 0
			if pitch > 0 then
				Lyon:setTargetPosition(62, Lyon.AXLE_HEIGHT - 1)
			end
			if pitch < 0 then
				Lyon:setTargetPosition(-62, Lyon.AXLE_HEIGHT - 1)
			end
		else
			Lyon:slowdownWhenExtended(true)
			x = x + xPID:pid(pitch / 5, 1 / 5)
			x = clamp(x, -40, 40)
			Lyon:setTargetPosition(x, 15)
			SmartDashboard:putNumber("BalanceTargetX", x)
		end
		coroutine:yield()
	end
end)

local engage = FancyCoroutine:new(function()
	driveNInches((104.625) - 20, -0.5):runUntilDone()
end)

local driveBackwardSmartEngage = FancyCoroutine:new(function()
	print("Starting smartEngage")
	while Drivetrain:pitchDegrees() > -11 do
		print("Driving while waiting for pitch to drop...")
		Drivetrain:autoDrive(-0.5, 0)
		coroutine.yield()
	end
	print("Reached target, stopping...")
	Drivetrain:stop()
	print("Driving 32 inches...")
	driveNInches(28, -0.4):runUntilDone()
	Brakes:toggleBrakes()
	armBalance:reset()
	armBalance:runUntilDone()
end)

local driveForwardSmartEngage = FancyCoroutine:new(function()
	print("Starting reverseSmartEngage")
	while Drivetrain:pitchDegrees() < 11 do
		print("Driving while waiting for pitch to drop...")
		Drivetrain:autoDrive(0.5, 0)
		coroutine.yield()
	end
	print("reached target, stopping...")
	Drivetrain:stop()
	print("Driving 34 inches")
	driveNInches(34, 0.4):runUntilDone()
	Brakes:toggleBrakes()
	armBalance:reset()
	armBalance:runUntilDone()
end)

local highAutoEngage = FancyCoroutine:new(function()
	scoreHigh:reset()
	driveBackwardSmartEngage:reset()
	scoreHigh:runUntilDone()
	driveBackwardSmartEngage:runUntilDone()
end)
local reverseHighAutoEngage = FancyCoroutine:new(function()
	reverseScoreHigh:reset()
	driveForwardSmartEngage:reset()
	reverseScoreHigh:runUntilDone()
	driveForwardSmartEngage:runUntilDone()
end)

---@param path Path
---@param isReversed boolean?
---@param isMirrored boolean?
---@return FancyCoroutine
local function pathCoroutine(path, isReversed, isMirrored)
	isReversed = isReversed or false
	isMirrored = isMirrored or false

	if isMirrored then
		path:mirror()
	end
	
	return FancyCoroutine:new(function()
		local pointPoses = {}

		for i = 1, 85 do
			local pathIndex = math.ceil(#path.points * i / 85)
			local pathPoint = path.points[pathIndex]
			table.insert(pointPoses, { x = pathPoint.x, y = pathPoint.y, rot = 0 })
		end

		field:getObject("Path"):setPoses(pointPoses)

		if isReversed then
			Drivetrain:setPos(path.points[1].x, path.points[1].y, path.startAngle + math.pi)
		else
			Drivetrain:setPos(path.points[1].x, path.points[1].y, path.startAngle)
		end

		local pp = PurePursuit:new(path, 3, 0, 0.15, isReversed)

		local speed, turn, done = 0, 0, false

		while not done do
			local x, y, rot = Drivetrain:getPosition()
			speed, turn, done = pp:run(Vector:new(x, y), rot)
			Drivetrain:autoDrive(speed, turn)
			coroutine.yield()
		end

		print("Done with " .. path.name .. "!")
		print("Average error: " .. (pp.pathError / pp.iterations) .. "in")
		print("End error: " .. (path.points[#path.points] - Vector:new(Drivetrain:getPosition())):length() .. "in")

		Drivetrain:autoDrive(0, 0)
	end)
end

local testPathAuto = FancyCoroutine:new(function()
	local path = Path:new("Test", {
		testEvent = function()
			print("TEST PATH TEST PATH TEST PATH")
		end,
	})

	pathCoroutine(path, true):runUntilDone()
end)

local twoCone = FancyCoroutine:new(function()
	Lyon:closeGripper()
	sleep(0.1)
	Lyon:setTargetPositionPreset(Lyon.HIGH_PRESET)
	sleep(2.7)
	Lyon:openGripper()
	sleep(0.3)
	Lyon:setTargetPosition(-30, 0)

	local path = Path:new("TwoConePt1", {})
	local path2 = Path:new("TwoConePt2", {})

	pathCoroutine(path, true):runUntilDone()
	sleep(0.1)
	Lyon:closeGripper()
	sleep(0.2)
	Lyon:slowdownWhenExtended(false)
	Lyon:setTargetPosition(-30, 25)
	sleep(0.5)
	Lyon:slowdownWhenExtended(true)
	Lyon:neutralPosition()
	pathCoroutine(path2, false):runUntilDone()
	driveSeconds(0.5, 0.2, 0.1):runUntilDone()
	Lyon:setTargetPositionPreset(Lyon.HIGH_PRESET)
	sleep(2.7)
	Lyon:openGripper()
	sleep(0.1)
	Lyon:neutralPosition()
end)

local twoConeEngage = FancyCoroutine:new(function()
	Lyon:closeGripper()
	sleep(0.1)
	Lyon:setTargetPositionPreset(Lyon.HIGH_PRESET)
	sleep(2.7)
	Lyon:openGripper()
	sleep(0.3)
	Lyon:setTargetPosition(-30, 0)

	local path = Path:new("TwoConePt1", {})
	local path2 = Path:new("TwoConePt2", {})
	local path3 = Path:new("TwoConePt3", {})

	pathCoroutine(path, true):runUntilDone()
	sleep(0.1)
	Lyon:closeGripper()
	sleep(0.2)
	Lyon:slowdownWhenExtended(false)
	Lyon:setTargetPosition(-30, 25)
	sleep(0.5)
	Lyon:slowdownWhenExtended(true)
	Lyon:neutralPosition()
	pathCoroutine(path2, false):runUntilDone()
	driveSeconds(0.5, 0.2, 0.1):runUntilDone()
	Lyon:setTargetPositionPreset(Lyon.HIGH_PRESET)
	sleep(2.7)
	Lyon:openGripper()
	sleep(0.1)
	Lyon:neutralPosition()
	pathCoroutine(path3, true):runUntilDone()
	driveBackwardSmartEngage:reset()
	driveBackwardSmartEngage:runUntilDone()
end)

---@enum FieldSide
local FieldSide = { Blue = 0, Red = 1 }

---@param side FieldSide
---@return FancyCoroutine
---@diagnostic disable-next-line: cast-local-type
function twoCone(side)
	return FancyCoroutine:new(function()
		Lyon:closeGripper()
		sleep(0.1)
		Lyon:setTargetPositionPreset(Lyon.HIGH_PRESET)
		sleep(2.7)
		Lyon:openGripper()
		sleep(0.2)
		Lyon:setTargetPosition(-30, 0)

		local path = Path:new("TwoConePt1", {})
		local path2 = Path:new("TwoConePt2", {})

		pathCoroutine(path, true, side == FieldSide.Red):runUntilDone()
		sleep(0.1)

		Lyon:closeGripper()
		sleep(0.2)
		Lyon:slowdownWhenExtended(false)
		Lyon:setTargetPosition(-30, 25)
		sleep(0.5)
		Lyon:slowdownWhenExtended(true)
		Lyon:neutralPosition()
		pathCoroutine(path2, false, side == FieldSide.Red):runUntilDone()
		local endTurn = 0.1
		if side == FieldSide.Red then
			endTurn = -endTurn
		end
		driveSeconds(0.5, 0.2, endTurn):runUntilDone()
		Lyon:setTargetPositionPreset(Lyon.HIGH_PRESET)
		sleep(2.7)
		Lyon:openGripper()
		sleep(0.2)
		Lyon:neutralPosition()
	end)
end

---@return FancyCoroutine
function getSelectedAuto()
	if autoChooser:getSelected() then
		return autoChooser:getSelected()
	else
		return mobilityAuto
	end
end

autoChooser:putChooser("Selected Auto", {
	{ name = "doNothing",                value = doNothingAuto },
	{ name = "mobilityAuto",             value = mobilityAuto },
	{ name = "highOnly",                 value = scoreHigh },
	{ name = "highMobility",             value = highMobility },
	{ name = "highAutoEngage",           value = highAutoEngage },
	{ name = "driveBackwardSmartEngage", value = driveBackwardSmartEngage },
	{ name = "driveForwardSmartEngage",  value = driveForwardSmartEngage },
	{ name = "highOnlyRear",             value = reverseScoreHigh },
	{ name = "reverseHighAutoEngage",    value = reverseHighAutoEngage },
	{ name = "test path auto",           value = testPathAuto },
	{ name = "famcy Two Cone Blue",      value = twoCone(FieldSide.Blue) },
	{ name = "famcy Two Cone Red",       value = twoCone(FieldSide.Red) },
	{ name = "ultimate auto",            value = twoConeEngage },
	{ name = "armBalance",               value = armBalance }
})
