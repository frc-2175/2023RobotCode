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

local function sleep(time)
	local timer = Timer:new()
	timer:start()

	while timer:get() < time do
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

local function driveSeconds(time, speed)
	return FancyCoroutine:new(function()
		local timer = Timer:new()
		timer:start()

		while timer:get() < time do
			Drivetrain:autoDrive(speed, 0)
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

local engage = FancyCoroutine:new(function()
	driveNInches((104.625) - 20, -0.5):runUntilDone()
end)

local smartEngage = FancyCoroutine:new(function()
	print("Starting smartEngage")
	while Drivetrain:pitchDegrees() > -11 do
		print("Driving while waiting for pitch to drop...")
		Drivetrain:autoDrive( -0.5, 0)
		coroutine.yield()
	end
	print("Reached target, stopping...")
	Drivetrain:stop()
	print("Driving 42 inches...")
	driveNInches(42, -0.4):runUntilDone()
	Brakes:toggleBrakes()
end)

local reverseSmartEngage = FancyCoroutine:new(function()
	print("Starting reverseSmartEngage")
	while Drivetrain:pitchDegrees() < 11 do
		print("Driving while waiting for pitch to drop...")
		Drivetrain:autoDrive(0.5, 0)
		coroutine.yield()
	end
	print("reached target, stopping...")
	Drivetrain:stop()
	print("Driving 42 inches")
	driveNInches(42, 0.4):runUntilDone()
	Brakes:toggleBrakes()
end)

local highAutoEngage = FancyCoroutine:new(function()
	scoreHigh:reset()
	smartEngage:reset()
	scoreHigh:runUntilDone()
	smartEngage:runUntilDone()
end)
local reverseHighAutoEngage = FancyCoroutine:new(function()
	reverseScoreHigh:reset()
	reverseSmartEngage:reset()
	reverseScoreHigh:runUntilDone()
	reverseSmartEngage:runUntilDone()
end)

local testPathAuto = FancyCoroutine:new(function()
	local path = Path:new("Test", {
		testEvent = function()
			print("TEST PATH TEST PATH TEST PATH")
		end,
	})
	
	local pointPoses = {}

	for i = 1, 85 do
		local pathIndex = math.ceil(#path.points * i / 85)
		local pathPoint = path.points[pathIndex]
		table.insert(pointPoses, {pathPoint.x, pathPoint.y, 0})
	end

	field:getObject("Path"):setPoses(pointPoses)

	Drivetrain:setPos(path.firstPoint.x, path.firstPoint.y, path.startAngle)

	local pp = PurePursuit:new(path, 4 / math.pi, 0, 0)

	local speed, turn, done = 0, 0, false

	while not done do
		local x, y, rot = Drivetrain:getPosition()
		speed, turn, done = pp:run(Vector:new(x, y), rot)
		Drivetrain:autoDrive(speed, turn)
		coroutine.yield()
	end

	print("Done!")
	print("Average error: " .. (pp.pathError / pp.iterations) .. "in")
	print("End error: " ..  (path.points[#path.points] - Vector:new(Drivetrain:getPosition())):length() .. "in")

	Drivetrain:autoDrive(0, 0)
end)

---@return FancyCoroutine
function getSelectedAuto()
	if autoChooser:getSelected() then
		return autoChooser:getSelected()
	else
		return mobilityAuto
	end
end

autoChooser:putChooser("Selected Auto", {
	{ name = "doNothing",             value = doNothingAuto },
	{ name = "mobilityAuto",          value = mobilityAuto },
	{ name = "highOnly",              value = scoreHigh },
	{ name = "highMobility",          value = highMobility },
	{ name = "highAutoEngage",        value = highAutoEngage },
	{ name = "smartEngage",           value = smartEngage },
	{ name = "highOnlyRear",          value = reverseScoreHigh },
	{ name = "reverseHighAutoEngage", value = reverseHighAutoEngage },
	{ name = "test path auto",        value = testPathAuto },
})
