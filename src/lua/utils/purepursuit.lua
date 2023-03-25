require("utils.vector")
require("utils.math")
require("utils.pid")
require("wpilib.ahrs")
require("wpilib.motors")
require("wpilib.time")
local pprint = require("utils.pprint")

local SEARCH_DISTANCE = 36 -- 36 inches before and after the last closest point
local LOOKAHEAD_DISTANCE = 24 -- look 24 inches ahead of the closest point

---@param path Path - a pure pursuit path
---@param fieldPosition Vector - the robot's current position on the field
---@param previousClosestPoint integer
---@return integer indexOfClosestPoint
--[[
    looks through all points on the list, finds & returns the point
    closest to current robot position 
--]]
local function findClosestPoint(path, fieldPosition, previousClosestPoint)
	local indexOfClosestPoint = 1
	local startDistance = path.distances[previousClosestPoint] - SEARCH_DISTANCE
	local endDistance = path.distances[previousClosestPoint] + SEARCH_DISTANCE

	startDistance = math.max(startDistance, 0)
	endDistance = math.min(endDistance, path.distances[#path.distances])

	local minDistance = (path.points[1] - fieldPosition):length()
	for i = 1, #path.distances do
		if startDistance < path.distances[i] and path.distances[i] < endDistance then
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

---@param point Vector
---@return number angle
local function getAngleToPoint(point)
	if point:length() == 0 then
		return 0
	end
	local angle = math.atan2(point.y, point.x)
	return angle
end

---@class PurePursuit
---@field path Path
---@field events table[]
---@field previousClosestPoint number
---@field purePursuitPID PIDController
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
---@return PurePursuit
function PurePursuit:new(path, p, i, d)
	local x = {
		path = path,
		events = table.copy(path.events),
		purePursuitPID = PIDController:new(p, i, d),
		previousClosestPoint = 1,
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
	self.purePursuitPID:updateTime(Timer:getFPGATimestamp())
	local indexOfClosestPoint = findClosestPoint(self.path, position, self.previousClosestPoint)
	
	local indexOfGoalPoint = findGoalPoint(self.path, indexOfClosestPoint)
	local goalPoint = self.path[indexOfGoalPoint]

	local maxDistance = self.path.distances[#self.path.distances]
	if self.path.distances[indexOfClosestPoint] + LOOKAHEAD_DISTANCE > maxDistance then
		goalPoint = self.path.points[#self.path.points] + Vector:new(self.path.distances[indexOfClosestPoint] + LOOKAHEAD_DISTANCE - maxDistance, 0):rotate(self.path.endAngle)
	end
	
	goalPoint = (goalPoint - position):rotate(-rotation)
	
	local angleToGoal = getAngleToPoint(goalPoint)
	
	local turnValue = -self.purePursuitPID:pid(rotation, angleToGoal)
	local speed = getTrapezoidSpeed(
		0.25, 0.75, 0.5, #self.path.points, 20, 20, indexOfClosestPoint
	)

	self.previousClosestPoint = indexOfClosestPoint

	-- without this the bot will relentlessly target the last point and that's no good
	if indexOfClosestPoint >= #self.path.points then
		return 0, 0, true
	end

	SmartDashboard:putNumber("PurePursuitIndexClosest", indexOfClosestPoint)
	SmartDashboard:putNumber("PurePursuitIndexGoal", indexOfGoalPoint)
	SmartDashboard:putNumber("PurePursuitIndexMax", #self.path.points)
	SmartDashboard:putNumber("PurePursuitGoalX", goalPoint.x)
	SmartDashboard:putNumber("PurePursuitGoalY", goalPoint.y)
	SmartDashboard:putNumber("PurePursuitClosestX", self.path.points[indexOfClosestPoint].x)
	SmartDashboard:putNumber("PurePursuitClosestY", self.path.points[indexOfClosestPoint].y)
	SmartDashboard:putNumber("PurePursuitAngleToGoal", angleToGoal)

	return speed, turnValue, false
end
