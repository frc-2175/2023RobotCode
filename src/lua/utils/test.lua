require("utils.math")
require("utils.path")
local pprint = require("utils.pprint")

-- math.lua tests

test(
	"squareInput", function(t)
		t:assertEqual(signedPow(-1), -1)
		t:assertEqual(signedPow(-0.5), -0.25)
		t:assertEqual(signedPow(0), 0)
		t:assertEqual(signedPow(0.5), 0.25)
		t:assertEqual(signedPow(1), 1)
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
