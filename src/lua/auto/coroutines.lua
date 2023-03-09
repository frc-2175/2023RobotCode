require("wpilib.dashboard")
require("subsystems.drivetrain")

local autoChooser = SendableChooser:new()

local doNothingAuto = FancyCoroutine:new(function () 
end)

local function sleep(time) 
	local timer = Timer:new()
	timer:start()

	while timer:get() < time do
		coroutine.yield()
	end
end

local function driveNInches(driveDistance, speed)
	return FancyCoroutine:new(function () 
		local startingPosition = Drivetrain:combinedPosition()

		while math.abs(Drivetrain:combinedPosition() - startingPosition) < driveDistance do
			print("Driving...")
			print("Combined position:", Drivetrain:combinedPosition())
			Drivetrain:drive(speed, 0)
			coroutine:yield()
		end
		
		print("Done")
		Drivetrain:stop()
	end)
end

local function driveSeconds(time, speed)
	return FancyCoroutine:new(function ()
		local timer = Timer:new()
		timer:start()

		while timer:get() < time do
			Drivetrain:drive(speed, 0)
			coroutine.yield()
		end

		Drivetrain:stop()
	end)
end

local mobilityAuto = FancyCoroutine:new(function ()
	driveNInches(12 * 12, -0.5):runUntilDone()
end)

local scoreHigh = FancyCoroutine:new(function ()
	Lyon:setTargetPositionPreset(Lyon.HIGH_PRESET)
	sleep(3)
	Lyon:openGripper()
	sleep(1)
	Lyon:setTargetPositionPreset(Lyon.NEUTRAL)
	sleep(2)
end)

local highMobility = FancyCoroutine:new(function ()
	scoreHigh:runUntilDone()
	mobilityAuto:runUntilDone()
end)

---@return FancyCoroutine
function getSelectedAuto()
	return autoChooser:getSelected()
end

autoChooser:putChooser({
	{ name = "doNothing", value = doNothingAuto },
	{ name = "mobilityAuto", value = mobilityAuto},
	{ name = "highMobility", value = highMobility},
	{ name = "highAutoEngage", value = highAutoEngage}
})
