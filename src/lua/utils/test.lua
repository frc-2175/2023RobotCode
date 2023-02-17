require("utils.math")
require("utils.path")
local pprint = require("utils.pprint")

-- math.lua tests

test(
	"lerp", function(t)
		t:assert(lerp(2, 10, 0) == 2)
		t:assert(lerp(2, 10, 0.5) == 6)
		t:assert(lerp(2, 10, 1) == 10)
	end
)

test(
	"squareInput", function(t)
		t:assertEqual(squareInput(-1), -1)
		t:assertEqual(squareInput(-0.5), -0.25)
		t:assertEqual(squareInput(0), 0)
		t:assertEqual(squareInput(0.5), 0.25)
		t:assertEqual(squareInput(1), 1)
	end
)

test(
	"getTrapezoidSpeed", function(t)
		t:assertEqual(getTrapezoidSpeed(0.2, 0.8, 0.4, 5, 1, 2, -1), 0.2)
		t:assertEqual(getTrapezoidSpeed(0.2, 0.8, 0.4, 5, 1, 2, 0), 0.2)
		t:assertEqual(getTrapezoidSpeed(0.2, 0.8, 0.4, 5, 1, 2, 0.5), 0.5)
		t:assertEqual(getTrapezoidSpeed(0.2, 0.8, 0.4, 5, 1, 2, 1), 0.8)
		t:assertEqual(getTrapezoidSpeed(0.2, 0.8, 0.4, 5, 1, 2, 1.5), 0.8)
		t:assertEqual(getTrapezoidSpeed(0.2, 0.8, 0.4, 5, 1, 2, 2), 0.8)
		t:assertEqual(getTrapezoidSpeed(0.2, 0.8, 0.4, 5, 1, 2, 3), 0.8)
		t:assertEqual(getTrapezoidSpeed(0.2, 0.8, 0.4, 5, 1, 2, 4), 0.6)
		t:assertEqual(getTrapezoidSpeed(0.2, 0.8, 0.4, 5, 1, 2, 5), 0.4)
		t:assertEqual(getTrapezoidSpeed(0.2, 0.8, 0.4, 5, 1, 2, 6), 0.4)

		t:assertEqual(getTrapezoidSpeed(0.2, 0.8, 0.4, 3, 1, 2, -1), 0.2)
		t:assertEqual(getTrapezoidSpeed(0.2, 0.8, 0.4, 3, 1, 2, 0), 0.2)
		t:assertEqual(getTrapezoidSpeed(0.2, 0.8, 0.4, 3, 1, 2, 0.5), 0.5)
		t:assertEqual(getTrapezoidSpeed(0.2, 0.8, 0.4, 3, 1, 2, 1), 0.8)
		t:assertEqual(getTrapezoidSpeed(0.2, 0.8, 0.4, 3, 1, 2, 2), 0.6)
		t:assertEqual(getTrapezoidSpeed(0.2, 0.8, 0.4, 3, 1, 2, 3), 0.4)
		t:assertEqual(getTrapezoidSpeed(0.2, 0.8, 0.4, 3, 1, 2, 4), 0.4)

		-- ramp up/down distances are greater than the total distance
		t:assertEqual(getTrapezoidSpeed(0.2, 0.8, 0.4, 3, 2, 2, -1), 0.2)
		t:assertEqual(getTrapezoidSpeed(0.2, 0.8, 0.4, 3, 2, 2, 0), 0.2)
		t:assertEqual(getTrapezoidSpeed(0.2, 0.8, 0.4, 3, 2, 2, 1.5), 0.3)
		t:assertEqual(getTrapezoidSpeed(0.2, 0.8, 0.4, 3, 2, 2, 3), 0.4)
		t:assertEqual(getTrapezoidSpeed(0.2, 0.8, 0.4, 3, 2, 2, 4), 0.4)
	end
)

test(
	"makePathLine", function(t)
		t:assertEqual(
			makePathLine(Vector:new(1, 1), Vector:new(3.5, 1)), {
				Vector:new(1, 1),
				Vector:new(2, 1),
				Vector:new(3, 1),
				Vector:new(3.5, 1),
			}
		)
		t:assertEqual(
			makePathLine(Vector:new(1, 1), Vector:new(1, 3.5)), {
				Vector:new(1, 1),
				Vector:new(1, 2),
				Vector:new(1, 3),
				Vector:new(1, 3.5),
			}
		)
	end
)

test(
	"makeRightPathArc", function(t)
		local r = 6 / math.pi
		local path = makeRightArcPathSegment(r, 95).path
		t:assertEqual(#path, 5, "path should be 5 points long")
		t:assertEqual(path[1], Vector:new(0, 0))
		t:assertEqual(path[2], Vector:new(r - r * (math.sqrt(3) / 2), r / 2))
		t:assertEqual(path[3], Vector:new(r - r / 2, r * math.sqrt(3) / 2))
		t:assertEqual(path[4], Vector:new(r, r))
		t:assert(path[5].x > r)
		t:assert(path[5].y > r - 0.7)
	end
)

test(
	"makeLeftPathArc", function(t)
		local r = 6 / math.pi
		local path = makeLeftArcPathSegment(r, 95).path
		t:assert(path[2].x < 0)
		t:assert(path[3].x < 0)
		t:assert(path[4].x < 0)
		t:assert(path[5].x < 0)

		t:assert(path[2].y > 0)
		t:assert(path[3].y > 0)
		t:assert(path[4].y > 0)
		t:assert(path[5].y > 0)
	end
)

test(
	"makePath", function(t)
		local path = makePath(
			false, 0, Vector:new(0, 0), {
				PathSegment:new(
					-90, {
						Vector:new(0, 0),
						Vector:new(0, 1),
						Vector:new(0, 2),
					}
				),
				PathSegment:new(
					90, {
						Vector:new(0, 0),
						Vector:new(0, 1),
						Vector:new(0, 2),
					}
				),
				PathSegment:new(
					-90, {
						Vector:new(0, 0),
						Vector:new(0, 1),
						Vector:new(0, 2),
					}
				),
			}
		)
		local actualPath = table.pack(table.unpack(path.path, 1, path.numberOfActualPoints))

		t:assertEqual(
			actualPath, {
				Vector:new(0, 0),
				Vector:new(0, 1),
				Vector:new(0, 2),
				Vector:new(0, 2),
				Vector:new(1, 2),
				Vector:new(2, 2),
				Vector:new(2, 2),
				Vector:new(2, 3),
				Vector:new(2, 4),
			}
		)
	end
)

test("orientPath", function(t)
	local points = {
		Vector:new(-1, 1), -- up at a 45 degree for a few
		Vector:new(0, 2),
		Vector:new(1, 3),
		Vector:new(2, 2), -- and down to the right for a bit
		Vector:new(3, 1),
		Vector:new(4, 0),
	}

	local before = Path:new(points, #points)
	local after = orientPath(before)

	t:assertEqual(after.path[1], Vector:new(0, 0))
	t:assertEqual(after.path[2].x, 0)
	t:assertEqual(after.path[3].x, 0)

	t:assert(after.path[4].x > 0)
	t:assertEqual(after.path[4].y, after.path[3].y)
	t:assert(after.path[5].x > 0)
	t:assertEqual(after.path[5].y, after.path[3].y)
	t:assert(after.path[6].x > 0)
	t:assertEqual(after.path[6].y, after.path[3].y)

	-- extended points
	t:assertEqual(after.path[7].y, after.path[3].y)
	t:assertEqual(after.path[8].y, after.path[3].y)
	t:assertEqual(after.path[9].y, after.path[3].y)
	t:assertEqual(after.path[10].y, after.path[3].y)
end)

-- ramp tests

test(
	"doGrossRampStuff", function(t)
		-- positive speed
		t:assertEqual(doGrossRampStuff(0.5, 1, 0.2, 0.1), 0.7, "should accelerate by 0.2")
		t:assertEqual(doGrossRampStuff(0.5, 0.1, 0.2, 0.1), 0.4, "should decelerate by 0.1")
		t:assertEqual(doGrossRampStuff(0.5, 0, 0.2, 0.1), 0.4, "should decelerate by 0.1")
		t:assertEqual(doGrossRampStuff(0.5, -1, 0.2, 0.1), 0.4, "should decelerate by 0.1")
		t:assertEqual(
			doGrossRampStuff(0.5, 0.5, 0.2, 0.1), 0.5,
			"speed should not change when current and target are equal"
		)

		-- negative speed
		t:assertEqual(doGrossRampStuff(-0.5, 1, 0.2, 0.1), -0.4, "should decelerate by 0.1")
		t:assertEqual(doGrossRampStuff(-0.5, 0, 0.2, 0.1), -0.4, "should decelerate by 0.1")
		t:assertEqual(doGrossRampStuff(-0.5, -0.1, 0.2, 0.1), -0.4, "should decelerate by 0.1")
		t:assertEqual(doGrossRampStuff(-0.5, -1, 0.2, 0.1), -0.7, "should accelerate by 0.2")
		t:assertEqual(
			doGrossRampStuff(-0.5, -0.5, 0.2, 0.1), -0.5,
			"speed should not change when current and target are equal"
		)

		-- zero
		t:assertEqual(doGrossRampStuff(0, 0, 0.2, 0.1), 0, "should go nowhere at zero")
		t:assertEqual(doGrossRampStuff(0, 1, 0.2, 0.1), 0.2, "should accelerate by 0.2 positively")
		t:assertEqual(doGrossRampStuff(0, -1, 0.2, 0.1), -0.2, "should accelerate by 0.2 negatively")

		-- overshoot
		t:assertEqual(doGrossRampStuff(0.5, 0.6, 1, 0.1), 0.6, "acceleration overshot when positive")
		t:assertEqual(doGrossRampStuff(-0.5, -0.6, 1, 0.1), -0.6, "acceleration overshot when negative")
		t:assertEqual(doGrossRampStuff(0.5, -0.1, 0.1, 1), -0.1, "deceleration overshot when positive")
		t:assertEqual(doGrossRampStuff(-0.5, 0.1, 0.1, 1), 0.1, "deceleration overshot when negative")
	end
)

test(
	"ramp", function(t)
		-- five ticks to max, ten ticks to stop
		local ramp = Ramp:new(0.1, 0.2)

		t:assertEqual(ramp.maxAccel, 0.2)
		t:assertEqual(ramp.maxDecel, 0.1)

		-- accelerate (positively)
		t:assertEqual(ramp:ramp(0.9), 0.2)
		t:assertEqual(ramp:ramp(0.9), 0.4)
		t:assertEqual(ramp:ramp(1.1), 0.6)
		t:assertEqual(ramp:ramp(1.1), 0.8)
		t:assertEqual(ramp:ramp(1), 1.0)
		t:assertEqual(ramp:ramp(1), 1.0)

		-- decelerate (while positive)
		t:assertEqual(ramp:ramp(0.1), 0.9)
		t:assertEqual(ramp:ramp(0.1), 0.8)
		t:assertEqual(ramp:ramp(0), 0.7)
		t:assertEqual(ramp:ramp(0), 0.6)
		t:assertEqual(ramp:ramp(-0.1), 0.5)
		t:assertEqual(ramp:ramp(-0.1), 0.4)
		t:assertEqual(ramp:ramp(-1), 0.3)
		t:assertEqual(ramp:ramp(-1), 0.2)
		t:assertEqual(ramp:ramp(-1), 0.1)
		t:assertEqual(ramp:ramp(0), 0.0)
		t:assertEqual(ramp:ramp(0), 0.0)

		-- accelerate (negatively)
		t:assertEqual(ramp:ramp(-0.9), -0.2)
		t:assertEqual(ramp:ramp(-0.9), -0.4)
		t:assertEqual(ramp:ramp(-1.1), -0.6)
		t:assertEqual(ramp:ramp(-1.1), -0.8)
		t:assertEqual(ramp:ramp(-1), -1.0)
		t:assertEqual(ramp:ramp(-1), -1.0)

		-- decelerate (while negative)
		t:assertEqual(ramp:ramp(-0.1), -0.9)
		t:assertEqual(ramp:ramp(-0.1), -0.8)
		t:assertEqual(ramp:ramp(0), -0.7)
		t:assertEqual(ramp:ramp(0), -0.6)
		t:assertEqual(ramp:ramp(0.1), -0.5)
		t:assertEqual(ramp:ramp(0.1), -0.4)
		t:assertEqual(ramp:ramp(1), -0.3)
		t:assertEqual(ramp:ramp(1), -0.2)
		t:assertEqual(ramp:ramp(1), -0.1)
		t:assertEqual(ramp:ramp(0), 0.0)
		t:assertEqual(ramp:ramp(0), 0.0)
	end
)

test(
	"Vector Tests :D", function(t)
		t:assertEqual(Vector:new(1, 2) + Vector:new(3, 4), Vector:new(4, 6))
		t:assertEqual(Vector:new(1, 2) + Vector:new(3, 4), Vector:new(-2, -2))
		t:assertEqual(Vector:new(1, 2) * 3, Vector:new(3, 6))
		t:assertEqual(3 * Vector:new(1, 2), Vector:new(3, 6))
		t:assertEqual(Vector:new(4, 6) / 2, Vector:new(2, 3))
		t:assertEqual(-Vector:new(1, 2), Vector:new(-1, -2))
		t:assertEqual(Vector:new(3, 4) == Vector:new(3, 4), true)
		t:assertEqual(Vector:new(3, 4):length(), 5)
		t:assertEqual(Vector:new(3, 4):normalized(), Vector:new(0.6, 0.8))
		t:assertEqual(Vector:new(1, 2):rotate(math.pi / 2), Vector:new(-2, 1))
	end
)
