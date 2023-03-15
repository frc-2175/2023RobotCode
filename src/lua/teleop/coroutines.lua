-- autoEngage = FancyCoroutine:new(function ()
-- 	while navx:getRoll() < 0.1 do
-- 		Drivetrain:drive(0.2)
-- 		coroutine.yield()
-- 	end
	
-- 	local encoderStart = Drivetrain:getEncoder()

-- 	while Drivetrain:getEncoder() - encoderStart < 82 do
-- 		Drivetrain:drive(0.2)
-- 		coroutine.yield()
-- 	end

-- 	Drivetrain:stop()
-- end)
