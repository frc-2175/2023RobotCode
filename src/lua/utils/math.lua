--- Linearly interpolate (blend) from one value to another. `a` and `b` are
--- the two end values, and `t` is the blend factor between them. As `t` goes
--- from 0 to 1, the result goes from `a` to `b`.
---
--- Examples:
---  - `lerp(2, 10, 0)` is `2`.
---  - `lerp(2, 10, 1)` is `10`.
---  - `lerp(2, 10, 0.5)` is `6`, because `6` is halfway from `2` to `10`.
---@param a any
---@param b any
---@param t number
---@return number blendedValue
function lerp(a, b, t)
	return (1 - t) * a + t * b
end

--- Returns the sign of the input number `n`
---
--- Examples:
---  - `sign(2)` is `1`.
---  - `sign(0)` is `0`.
---  - `sign(-2)` is `-1`.
---@param n number
---@return number sign
function sign(n)
	local val = 0
	if n > 0 then
		val = 1
	elseif n < 0 then
		val = -1
	end
	return val
end

---@param value number
---@param band number
---@return number
function deadband(value, band)
	local result = 0
	if (value > band) then
		result = (value - band) / (1 - band)
	elseif (value < -band) then
		result = (value + band) / (1 - band)
	end
	return result
end

-- sets an upper/lower limit, if value is beyond that, it snaps it to that limit
---@param value number
---@param min number
---@param max number
---@return number
function clamp(value, min, max)
	return math.min(math.max(value, min), max)
end

function squareInput(num)
	return num * math.abs(num)
end

-- Oh boyo, here we go!

--- A way of moving a robot from a starting speed to a middle speed and then to an ending speed, ramping inbetween.
--- A graph of velocity over time would look like \_|/‾\\\_ with the `|` symbol representing time = 0.
---
--- This function takes 7 arguments:
--- - `startSpeed`, `middleSpeed`, and `endSpeed` are pretty self-explanatory.
--- - `totalDistance` is the total distance you want the 'trapezoid' shape to occur over.
--- - `rampUpDistance` and `rampDownDistance` are the distances along the 'trapezoid'
--- that the robot will start accelerating or decelerating.
--- - `currentDistance` is how far along the 'trapezoid' the robot already is.
---
--- Examples:
--- - `getTrapezoidSpeed(0, 1, 0.5, 3, 1, 1, -1)` returns the startSpeed `0`
--- - `getTrapezoidSpeed(0, 1, 0.5, 3, 1, 1, 0)` returns the startSpeed `0`
--- - `getTrapezoidSpeed(0, 1, 0.5, 3, 1, 1, 0.5)` returns `0.5` which is halfway between the startSpeed `0` and the
--- middleSpeed `1` because currentDistance `0.5` is half of the rampUpDistance `1`
--- - `getTrapezoidSpeed(0, 1, 0.5, 3, 1, 1, 1.5)` returns the middleSpeed `1` because the currentDistance `1.5` is
--- after the rampUpDistance but before the totalDistance - rampDownDistance
--- - `getTrapezoidSpeed(0, 1, 0.5, 3, 1, 1, 2.5)` returns `0.75` which is halfway between the middleSpeed `1` and
--- endSpeed `0.5` because currentDistance `2.5` is halfway between totalDistance - rampDownDistance and totalDistance
--- - `getTrapezoidSpeed(0, 1, 0.5, 3, 1, 1, 3)` returns the endSpeed `0.5`
---@param startSpeed number
---@param middleSpeed number
---@param endSpeed number
---@param totalDistance number
---@param rampUpDistance number
---@param rampDownDistance number
---@param currentDistance number
---@return number speed
function getTrapezoidSpeed(
    startSpeed,
    middleSpeed,
    endSpeed,
    totalDistance,
    rampUpDistance,
    rampDownDistance,
    currentDistance
)
	-- if the ramp up/down distances are too great, simply lerp from start to finish instead of ramping
	if rampDownDistance + rampUpDistance > totalDistance then
		if currentDistance < 0 then
			return startSpeed
		elseif totalDistance < currentDistance then
			return endSpeed
		end

		return lerp(startSpeed, endSpeed, currentDistance / totalDistance)
	end

	if currentDistance < 0 then
		return startSpeed
	elseif currentDistance < rampUpDistance then
		return lerp(startSpeed, middleSpeed, currentDistance / rampUpDistance)
	elseif currentDistance < totalDistance - rampDownDistance then
		return middleSpeed
	elseif currentDistance < totalDistance then
		local rampDownStartDistance = (totalDistance - rampDownDistance)
		return lerp(middleSpeed, endSpeed, (currentDistance - rampDownStartDistance) / rampDownDistance)
	else
		return endSpeed
	end
end