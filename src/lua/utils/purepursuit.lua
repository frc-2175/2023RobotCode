require("utils.vector")
require("utils.math")
require("utils.pid")
require("wpilib.ahrs")
require("wpilib.motors")
require("wpilib.time")

local SEARCH_DISTANCE = 36 -- 36 inches before and after the last closest point
local LOOKAHEAD_DISTANCE = 42 -- look 24 inches ahead of the closest point

---@param path Path - a pure pursuit path
---@param fieldPosition Vector - the robot's current position on the field
---@param previousClosestPoint integer
---@return integer indexOfClosestPoint
--[[
    looks through all points on the list, finds & returns the point
    closest to current robot position 
--]]
function findClosestPoint(path, fieldPosition, previousClosestPoint)
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
function findGoalPoint(path, closestPoint)
	closestPoint = closestPoint == nil and 1 or closestPoint

	local goalPoint = closestPoint

	for i = goalPoint, #path.points do
		if path.distances[i] >= path.distances[closestPoint] + LOOKAHEAD_DISTANCE then
			return i
		end
	end

	return goalPoint
end

---@param point Vector
---@return number degAngle
function getAngleToPoint(point)
	if point:length() == 0 then
		return 0
	end
	local angle = math.atan(point:normalized().y)
	return sign(point.x) * angle
end

---@class PurePursuit
---@field path Path
---@field triggerFuncs table<string, function>
---@field previousClosestPoint number
---@field purePursuitPID PIDController
PurePursuit = {}

---@param path Path
---@param p number
---@param i number
---@param d number
---@return PurePursuit
function PurePursuit:new(path, p, i, d, triggerFuncs)
	triggerFuncs = triggerFuncs or {}

	local x = {
		path = path,
		triggerFuncs = triggerFuncs,
		purePursuitPID = PIDController:new(p, i, d),
		previousClosestPoint = 1,
	}
	setmetatable(x, PurePursuit)
	self.__index = self

	return x
end

---@param position Vector
---@param rotation number
---@return number turnValue, number speed
function PurePursuit:run(position, rotation)
	-- pprint(self.path.triggerPoints)
	self.purePursuitPID:updateTime(Timer:getFPGATimestamp())

	local indexOfClosestPoint = findClosestPoint(self.path, position, self.previousClosestPoint)
	local indexOfGoalPoint = findGoalPoint(self.path, indexOfClosestPoint)
	local goalPoint = self.path.points[indexOfGoalPoint] - position
	local angleToGoal = getAngleToPoint(goalPoint)
	
	local turnValue = self.purePursuitPID:pid(rotation, angleToGoal)
	local speed = getTrapezoidSpeed(
		0.25, 0.75, 0.5, #self.path.points, 20, 20, indexOfClosestPoint
	)

	self.previousClosestPoint = indexOfClosestPoint

	-- without this the bot will relentlessly target the last point and that's no good
	if indexOfClosestPoint >= #self.path.points then
		speed = 0
		turnValue = 0
	end

	SmartDashboard:putNumber("closest", indexOfClosestPoint)
	SmartDashboard:putNumber("goal", indexOfGoalPoint)
	SmartDashboard:putNumber("max", #self.path.points)
	SmartDashboard:putNumber("goalx", goalPoint.x)
	SmartDashboard:putNumber("goaly", goalPoint.y)
	SmartDashboard:putNumber("closestx", self.path.points[indexOfClosestPoint].x)
	SmartDashboard:putNumber("closesty", self.path.points[indexOfClosestPoint].y)
	SmartDashboard:putNumber("angletopoint", angleToGoal)

	return speed, turnValue
end
