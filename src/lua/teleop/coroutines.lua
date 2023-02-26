autoEngage = coroutine.create(autoEngage ()
	if navx:getRoll() < 0.1 then
		Drivetrain:drive(0.2)
		coroutine.yield()
	end
	if navx:getRoll() > 0.1 then
		Drivetrain:drive(0.2)
		if Drivetrain:getEncoder() >= 82 then
			coroutine.yield()
		end
	end
end