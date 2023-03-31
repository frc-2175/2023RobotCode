require("utils.vector")
require("utils.math")
require("utils.pid")
require("wpilib.ahrs")
require("wpilib.motors")
require("wpilib.time")
local pprint = require("utils.pprint")

-- Search this many inches before and after the previous closest point. This
-- allows the path to cross over itself.
local SEARCH_DISTANCE = 36

-- Look this many inches ahead of the closest point to find the goal point.
local LOOKAHEAD_DISTANCE = 24

---@param path Path - a pure pursuit path
---@param fieldPosition Vector - the robot's current position on the field
---@param previousClosestPoint integer
---@return integer indexOfClosestPoint
--[[
    looks through all points on the list, finds & returns the point
    closest to current robot position 
--]]
local function findClosestPoint(path, fieldPosition, previousClosestPoint)
	local indexOfClosestPoint = previousClosestPoint
	local startDistance = path.distances[previousClosestPoint] - SEARCH_DISTANCE
	local endDistance = path.distances[previousClosestPoint] + SEARCH_DISTANCE

	startDistance = math.max(startDistance, 0)
	endDistance = math.min(endDistance, path.distances[#path.distances])

	local minDistance = (path.points[previousClosestPoint] - fieldPosition):length()
	for i = 1, #path.distances do
		if startDistance <= path.distances[i] and path.distances[i] <= endDistance then
			local distance = (path.points[i] - fieldPosition):length()

			if distance <= minDistance then
				indexOfClosestPoint = i
				minDistance = distance
			end
		end
	end

	return indexOfClosestPoint
end

---@param path Path
---@param closestPoint integer
---@return integer goalPoint
local function findGoalPoint(path, closestPoint)
	closestPoint = closestPoint == nil and 1 or closestPoint
	
	for i = closestPoint, #path.points do
		if path.distances[i] >= path.distances[closestPoint] + LOOKAHEAD_DISTANCE then
			return i
		end
	end

	return #path.points
end

---@class PurePursuit
---@field path Path
---@field events table[]
---@field purePursuitPID PIDController
---@field previousClosestPoint number
---@field pathError number
---@field iterations integer
---@field isReversed boolean
PurePursuit = {}

function table.copy(t)
	local u = { }
	for k, v in pairs(t) do u[k] = v end
	return setmetatable(u, getmetatable(t))
end

---@param path Path
---@param p number
---@param i number
---@param d number
---@param isReversed boolean
---@return PurePursuit
function PurePursuit:new(path, p, i, d, isReversed)
	local x = {
		path = path,
		events = table.copy(path.events),
		purePursuitPID = PIDController:new(p, i, d),
		previousClosestPoint = 1,
		pathError = 0,
		iterations = 0,
		isReversed = isReversed,
	}
	setmetatable(x, PurePursuit)
	self.__index = self

	table.sort(x.events, function (a, b)
		return a.distance < b.distance
	end)

	return x
end

---@param position Vector
---@param rotation number
---@return number speed, number turnValue, boolean isDone
function PurePursuit:run(position, rotation)
	self.iterations = self.iterations + 1

	if self.isReversed then
		rotation = rotation + math.pi
	end

	self.purePursuitPID:updateTime(Timer:getFPGATimestamp())
	local indexOfClosestPoint = findClosestPoint(self.path, position, self.previousClosestPoint)

	self.pathError = self.pathError + (self.path.points[indexOfClosestPoint] - position):length()

	for i, event in ipairs(self.path.events) do
		if self.path.distances[indexOfClosestPoint] >= event.distance then
			event.func()
			table.remove(self.path.events, i)
		end
	end

	local indexOfGoalPoint = findGoalPoint(self.path, indexOfClosestPoint)
	local goalPoint = self.path.points[indexOfGoalPoint]

	local maxDistance = self.path.distances[#self.path.distances]
	if self.path.distances[indexOfClosestPoint] + LOOKAHEAD_DISTANCE > maxDistance then
		local distancePastFinal = self.path.distances[indexOfClosestPoint] + LOOKAHEAD_DISTANCE - maxDistance
		goalPoint = self.path.points[#self.path.points] + Vector:new(distancePastFinal, 0):rotate(self.path.endAngle)
	end

	local angleToGoal = 0 -- relative to the robot's current heading
	local goalPointRobotRelative = (goalPoint - position):rotate(-rotation)
	if goalPointRobotRelative:length() ~= 0 then
		angleToGoal = math.atan2(goalPointRobotRelative.y, goalPointRobotRelative.x)
	end

	local turnValue = self.purePursuitPID:pid(angleToGoal, 0)
	
	local speed = getTrapezoidSpeed(
		0.25, 0.75, 0.25, self.path.distances[#self.path.distances], 10, 36, self.path.distances[indexOfClosestPoint]
	)

	self.previousClosestPoint = indexOfClosestPoint

	-- without this the bot will relentlessly target the last point and that's no good
	if indexOfClosestPoint >= #self.path.points then
		return 0, 0, true
	end

	SmartDashboard:putNumber("PurePursuitIndexClosest", indexOfClosestPoint)
	SmartDashboard:putNumber("PurePursuitIndexGoal", indexOfGoalPoint)
	SmartDashboard:putNumber("PurePursuitIndexMax", #self.path.points)
	SmartDashboard:putNumber("PurePursuitDistanceMax", #self.path.distances)
	SmartDashboard:putNumber("PurePursuitAngleToGoal", angleToGoal)

	field:getObject("PurePursuitGoalPoint"):setPose(goalPoint.x, goalPoint.y, 0)
	field:getObject("PurePursuitClosestPoint"):setPose(self.path.points[indexOfClosestPoint].x, self.path.points[indexOfClosestPoint].y, 0)
	local between = lerp(position, goalPoint, 0.5)
	field:getObject("PurePursuitAngleToGoal"):setPose(between.x, between.y, angleToGoal + rotation)

	if self.isReversed then
		speed = -speed
	end

	return speed, turnValue, false
end

test("Pure pursuit debug fun time", function(t)
	local path = Path:new("TestOnlyDoNotEdit", {
		testEvent = function() print("wow!") end,
	})
	local pp = PurePursuit:new(path, 1, 0, 0, false)
	pp:run(path.points[1], 0)
end)
