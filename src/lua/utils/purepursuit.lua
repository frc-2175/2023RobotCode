require("utils.vector")
require("utils.math")
require("utils.pid")
require("wpilib.ahrs")
require("wpilib.motors")
require("wpilib.time")
local pprint = require("utils.pprint")

local TICKS_TO_INCHES = (6 * math.pi) / (2048 * 10)
local SEARCH_DISTANCE = 36 -- 36 inches before and after the last closest point
local LOOKAHEAD_DISTANCE = 42 -- look 24 inches ahead of the closest point

navx = AHRS:new(4)
position = Vector:new(0, 0)
local angleOffset = navx:getAngle()

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
	local startIndex = previousClosestPoint - SEARCH_DISTANCE
	local endIndex = previousClosestPoint + SEARCH_DISTANCE
	
	-- making sure indexes make sense
	startIndex = math.max(startIndex, 1)
	endIndex = math.min(endIndex, path.numberOfActualPoints) -- closest point cannot be in the extra points

	local minDistance = (path.points[1] - fieldPosition):length() -- distance to closest point so far
	for i = startIndex, endIndex do -- check through each point in list, and ...
		local distanceToPoint = (path.points[i] - fieldPosition):length()
		if distanceToPoint <= minDistance then
			indexOfClosestPoint = i
			minDistance = distanceToPoint -- if we find a closer one, that becomes the new minDist
		end
	end
	return indexOfClosestPoint
end

---@param path Path
---@param closestPoint integer
---@return integer goalPoint
function findGoalPoint(path, closestPoint)
	closestPoint = closestPoint or 1 -- default 1
	return math.min(closestPoint + LOOKAHEAD_DISTANCE, #path.points) -- # is length operator
	-- in case we are aiming PAST the end of the path, just aim at the end instead
end

---@param point Vector
---@return number degAngle
function getAngleToPoint(point)
	if point:length() == 0 then
		return 0
	end
	local angle = math.acos(point.y / point:length())
	return sign(point.x) * math.deg(angle)
end

-- function getAverageEncoderDistance() 
-- 	return ((rightMotor:getSelectedSensorPosition() + leftMotor:getSelectedSensorPosition())/2)*TICKS_TO_INCHES
-- end

function trackLocation(leftMotor, rightMotor)
	-- first, get the distance we've traveled since last time trackLocation was called
	lastEncoderDistanceLeft = lastEncoderDistanceLeft or 0
	lastEncoderDistanceRight = lastEncoderDistanceRight or 0
	distanceLeft = leftMotor:getSelectedSensorPosition() * TICKS_TO_INCHES - lastEncoderDistanceLeft
	distanceRight = rightMotor:getSelectedSensorPosition() * TICKS_TO_INCHES - lastEncoderDistanceRight
	-- calculates avg distance traveled
	distance = (distanceLeft + distanceRight) / 2
	-- get our heading in radians
	local angle = math.rad(navx:getAngle() - angleOffset)

	-- make a vector representing our change in position since last time
	x = math.sin(angle) * distance
	y = math.cos(angle) * distance

	changeInPosition = Vector:new(x, y)
	position = position + changeInPosition

	-- setting the "lastEncoderDistance" for next time
	lastEncoderDistanceLeft = leftMotor:getSelectedSensorPosition() * TICKS_TO_INCHES
	lastEncoderDistanceRight = rightMotor:getSelectedSensorPosition() * TICKS_TO_INCHES
end

function resetTracking()
	lastEncoderDistanceLeft = 0
	lastEncoderDistanceRight = 0
	zeroEncoderLeft = leftMotor:setSelectedSensorPosition(0)
	zeroEncoderRight = rightMotor:setSelectedSensorPosition(0)
	position = Vector:new(0, 0)
	angleOffset = navx:getAngle()
end

---@class PurePursuit
---@field path Path
---@field triggerFuncs table<string, function>
---@field isBackwards boolean
---@field previousClosestPoint number
---@field purePursuitPID number
PurePursuit = {}

---@param path Path
---@param isBackwards boolean
---@param p number
---@param i number
---@param d number
---@return PurePursuit
function PurePursuit:new(path, isBackwards, p, i, d, triggerFuncs)
	triggerFuncs = triggerFuncs or {}
	if isBackwards then
		path = path:negated()
	end
	local x = {
		path = path,
		triggerFuncs = triggerFuncs,
		isBackwards = isBackwards,
		purePursuitPID = PIDController:new(p, i, d),
		previousClosestPoint = 0,
	}
	setmetatable(x, PurePursuit)
	self.__index = self

	return x
end

---@return number turnValue, number speed
function PurePursuit:run()
	-- pprint(self.path.triggerPoints)
	self.purePursuitPID:updateTime(Timer:getFPGATimestamp())

	local indexOfClosestPoint = findClosestPoint(self.path, position, self.previousClosestPoint)
	local indexOfGoalPoint = findGoalPoint(self.path, indexOfClosestPoint)
	local goalPoint = (self.path.points[indexOfGoalPoint] - position):rotate(math.rad(navx:getAngle()))
	local angle = getAngleToPoint(goalPoint)
	
	if self.isBackwards then
		angle = -getAngleToPoint(-goalPoint)
	end
	
	local turnValue = self.purePursuitPID:pid(-angle, 0)
	local speed = getTrapezoidSpeed(
		0.25, 0.75, 0.5, self.path.numberOfActualPoints, 20, 20, indexOfClosestPoint
	)

	if self.isBackwards then -- dont join these two
		turnValue = -turnValue
		speed = -speed
	end

	for i = self.previousClosestPoint - 1, indexOfClosestPoint do
		print(i)
		if self.path.eventFuncs[i] ~= nil then
			self.triggerFuncs[self.path.eventFuncs[i]]()
		end
	end

	self.previousClosestPoint = indexOfClosestPoint

	-- without this the bot will relentlessly target the last point and that's no good
	if indexOfClosestPoint >= self.path.numberOfActualPoints then
		speed = 0
		turnValue = 0
	end

	if speed ~= 0 then
		SmartDashboard:putNumber("closest", indexOfClosestPoint)
		SmartDashboard:putNumber("goal", indexOfGoalPoint)
		SmartDashboard:putNumber("max", self.path.numberOfActualPoints)
		SmartDashboard:putNumber("x", position.x)
		SmartDashboard:putNumber("y", position.y)
	end
	return turnValue, speed
end
