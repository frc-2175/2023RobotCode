require("utils.path")
local taxiPath = orientPath(readPath("taxi"))
local autoPath1 = orientPath(readPath("auto1"))
local autoPath2 = orientPath(readPath("auto2"))
local pprint = require("utils.pprint")

doNothingAuto = FancyCoroutine:new(function()
	print("We are doing nothing in auto!!!")
end)

taxiAuto = FancyCoroutine:new(function ()
	local pathPursuit = PurePursuit:new(
		taxiPath,
		true,
		0.015, 0, 0.002
	)

	while true do
		local rotation, speed = pathPursuit:run()
		putNumber("Rotation", rotation)
		Drivetrain:drive(0.6 * speed, rotation)
		coroutine.yield(speed ~= 0)
	end
end)

shootBall = FancyCoroutine:new(function ()
	local cargoTimer = Timer:new()
	cargoTimer:start()
	while not cargoTimer:hasElapsed(1) do
		Intake:rollOut()
		coroutine.yield(true)
	end
	Intake:stop()
	coroutine.yield(false)
end)

oneBallAuto = FancyCoroutine:new(function()
	shootBall:reset()
	while shootBall:run() do coroutine.yield(true) end

	taxiAuto:reset()
	while taxiAuto:run() do coroutine.yield(true) end

	coroutine.yield(false)
end)

auto1 = FancyCoroutine:new(function ()
	local pathPursuit = PurePursuit:new(
		autoPath1,
		false,
		0.015, 0, 0.002
	)

	local i = 0
	while true do
		i = i + 1
		local rotation, speed = pathPursuit:run()
		print("speen!!!", speed)
		Drivetrain:drive(0.6 * speed, rotation)
		coroutine.yield(speed ~= 0)
	end
end)

auto2 = FancyCoroutine:new(function ()
	local pathPursuit = PurePursuit:new(
		autoPath2,
		false,
		0.015, 0, 0.002,
		{
			intakeStart = function ()
				Intake:down()
				Intake:rollIn()
			end,
			intakeStop = function ()
				Intake:up()
			end,
			shoot = function ()
				Intake:rollOut()
			end
		}
	)

	while true do
		local rotation, speed = pathPursuit:run()
		putNumber("Rotation", rotation)
		Drivetrain:drive(0.6 * speed, rotation)
		coroutine.yield(speed ~= 0)
	end
end)

testAuto = FancyCoroutine:new(function ()
	local pathPursuit = PurePursuit:new(
		orientPath(readPath("test")),
		false,
		0.015, 0, 0.002,
		{
			start1 = function()
				Intake:down()
				Intake:rollIn()
			end,
			start3 = function()
				Intake:up()
				Intake:stop()
			end,
			end3 = function()
				Intake:rollOut()
			end
		}
	)
	
	while true do
		local rotation, speed = pathPursuit:run()
		putNumber("Rotation", rotation)
		Drivetrain:drive(0.6 * speed, rotation)
		coroutine.yield()
	end
end)

test("FancyCoroutine", function (t)
	local testTable = {}
	local appendOne = FancyCoroutine:new(function ()
		for i = 1, 3 do
			table.insert(testTable, 1)
			coroutine.yield(true)
		end
		coroutine.yield(false)
	end)
	local appendTwo = FancyCoroutine:new(function ()
		for i = 1, 3 do
			table.insert(testTable, 2)
			coroutine.yield(true)
		end
		coroutine.yield(false)
	end)
	local appendBoth = FancyCoroutine:new(function ()
		appendOne:reset()
		while appendOne:run() do
			coroutine.yield()
		end

		appendTwo:reset()
		while appendTwo:run() do
			coroutine.yield()
		end
	end)
	appendBoth:run()
	appendBoth:run()
	appendBoth:run()
	appendBoth:run()
	appendBoth:run()
	appendBoth:run()
	pprint(testTable)
end)