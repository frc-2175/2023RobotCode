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
	Lyon:closeGripper()
	Lyon:setTargetPositionPreset(Lyon.HIGH_PRESET)
	sleep(3)
	Lyon:openGripper()
	sleep(1)
	Lyon:setTargetPositionPreset(Lyon.NEUTRAL)
	sleep(2)
end)

local highMobility = FancyCoroutine:new(function ()
	scoreHigh:reset()
	mobilityAuto:reset()
	scoreHigh:runUntilDone()
	mobilityAuto:runUntilDone()
end)

local engage = FancyCoroutine:new(function ()
	driveNInches((104.625) - 20, -0.5):runUntilDone()
end)

local smartEngage = FancyCoroutine:new(function ()
	print("Starting smartEngage")
	while Drivetrain:pitchDegrees() > -11 do
		print("Driving while waiting for pitch to drop...")
		Drivetrain:drive(-0.5, 0)
		coroutine.yield()
	end
	print("Reached target, stopping...")
	Drivetrain:stop()
	print("Driving 42 inches...")
	driveNInches(42, -0.4):runUntilDone()
end)

local highAutoEngage = FancyCoroutine:new(function ()
	scoreHigh:reset()
	smartEngage:reset()
	scoreHigh:runUntilDone()
	smartEngage:runUntilDone()
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
	{ name = "doNothing", value = doNothingAuto },
	{ name = "mobilityAuto", value = mobilityAuto},
	{ name = "highOnly", value = scoreHigh },
	{ name = "highMobility", value = highMobility},
	{ name = "highAutoEngage", value = highAutoEngage},
	{ name = "smartEngage", value = smartEngage}
})
