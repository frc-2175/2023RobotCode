require("utils.vector")
require("utils.math")
local json = require("utils.json")
local dir = getDeployDirectory() .. "/paths/"
print(getDeployDirectory())

local EXTRA_POINTS = 48 -- this should be >= LOOKAHEAD_DISTANCE

---@class PathSegment
---@field endAng number
---@field path Vector[]
PathSegment = {}

--- Creates a new path segment, given an ending angle
--- in degrees, `endAng`, and a list of vectors, `path`.
---
--- Examples:
---  - `mySegment = newPathSegment(90, {})` creates
--- a new path segment(with an empty path table).
---  - `mySegment.path = {Vector:new(0, 0), Vector:new(1, 1)}`
--- sets the path of the new segment you made.
---  - `mySegment.path[1]` returns `Vector:new(0, 0)`.
---@param endAng number
---@param path Vector[]
---@return PathSegment
function PathSegment:new(endAng, path)
	local p = {
		endAng = endAng,
		path = path,
	}
	setmetatable(p, self)
	self.__index = self

	return p
end

---@return Vector
function PathSegment:getEndPoint()
	return self.path[#self.path]
end

---@param startpoint Vector
---@param endpoint Vector
---@return Vector[] path
function makePathLine(startpoint, endpoint)
	local numPoints = math.floor((endpoint - startpoint):length() + 0.5)
	local pathVector = (endpoint - startpoint):normalized()
	local path = {}
	for i = 1, numPoints, 1 do
		path[i] = pathVector * (i - 1) + startpoint
	end
	path[numPoints + 1] = endpoint
	return path
end

---@param dist number
---@return PathSegment
function makeLinePathSegment(dist)
	return PathSegment:new(0, makePathLine(Vector:new(0, 0), Vector:new(0, dist)))
end

---@param radius number
---@param deg number
---@return PathSegment PathSegment
function makeRightArcPathSegment(radius, deg)
	local circumfrence = 2 * math.pi * radius
	local distanceOfPath = circumfrence * (deg / 360)
	local yEndpoint = radius * math.sin(math.rad(deg))
	local xEndpoint = radius - (radius * math.cos(math.rad(deg)))
	local degreesPerInch = 360 / circumfrence
	local numPoints = math.floor(distanceOfPath + 2)
	local path = {}
	for i = 1, numPoints - 1 do
		local angle = (i - 1) * degreesPerInch
		local yPosition = radius * math.sin(math.rad(angle))
		local xPosition = radius - (radius * math.cos(math.rad(angle)))
		path[i] = Vector:new(xPosition, yPosition)
	end
	path[numPoints] = Vector:new(xEndpoint, yEndpoint)

	return PathSegment:new(-deg, path)
end

---@param radius number
---@param deg number
---@return PathSegment
function makeLeftArcPathSegment(radius, deg)
	local rightPath = makeRightArcPathSegment(radius, deg).path
	local leftPath = {}
	for i = 1, #rightPath do
		leftPath[i] = Vector:new(-rightPath[i].x, rightPath[i].y)
	end
	return PathSegment:new(deg, leftPath)
end

---@class Path
---@field path Vector[]
---@field numberOfActualPoints integer
---@field triggerPoints table
Path = {}

---@param path Vector[]
---@param numberOfActualPoints integer
---@param triggerPoints table
---@return Path path
function Path:new(path, numberOfActualPoints, triggerPoints)
	triggerPoints = triggerPoints or {}
	local p = {
		path = path,
		numberOfActualPoints = numberOfActualPoints,
		triggerPoints = triggerPoints,
	}
	setmetatable(p, self)
	self.__index = self

	return p
end

function Path:print()
	for index, value in ipairs(self.path) do
		print(value)
	end
end

function Path:negated()
	local negatedPath = {}
	
	for i, value in ipairs(self.path) do
		negatedPath[i] = -value
	end

	return Path:new(negatedPath, self.numberOfActualPoints, self.triggerPoints)
end

---@param isBackwards boolean
---@param startingAng number
---@param startingPos Vector
---@param pathSegments PathSegment[]
---@return Path path
function makePath(isBackwards, startingAng, startingPos, pathSegments)
	local finalPath = {}
	local previousAng = 0
	local previousPos = Vector:new(0, 0)
	-- add 25 points to the end so the robot knows where to look ahead
	local endingPoints = makeLinePathSegment(24)

	-- create table with all the pathSegments elements and add a new element for endingPoints
	local pathSegmentsList = pathSegments
	pathSegmentsList[#pathSegmentsList + 1] = endingPoints

	-- create one big table of vectors
	for index, aPathSegment in ipairs(pathSegmentsList) do
		for subindex, subvalue in ipairs(aPathSegment.path) do
			table.insert(finalPath, subvalue:rotate(previousAng) + previousPos)
		end
		previousPos = previousPos + aPathSegment:getEndPoint():rotate(previousAng)
		previousAng = previousAng + aPathSegment.endAng
	end

	if isBackwards then
		for i = 1, #finalPath do
			finalPath[i] = finalPath[i] * -1
		end
	end
	for i = 1, #finalPath do
		finalPath[i] = finalPath[i]:rotate(math.rad(startingAng)) + startingPos
	end

	local pathResult = Path:new(finalPath, #finalPath - #endingPoints.path)

	return pathResult
end

---@param fileName string
---@return Path
function readPath(fileName)
	local rawFile, err = io.open(dir .. fileName .. ".path")
	if err ~= nil then -- this one's for you, gophers.
		return { Vector:new(0, 0) }
	end
    ---@type Vector[]
    local fileContents = json.decode(rawFile:read("a"))
    ---@type Vector[]
    local resultPath = {}

    for i, value in ipairs(fileContents.points) do
        resultPath[i] = Vector:new(value.x, value.y)
    end

	local triggerPoints = {}

	for i, value in ipairs(fileContents.triggerPoints) do
        triggerPoints[math.floor(value.distance)] = value.name
    end

    return Path:new(resultPath, 0, triggerPoints)
end

---@param filePath Path
---@return Path
function orientPath(filePath)
    local resultPath = {}
	local points = filePath.path

    local firstSegment = points[2] - points[1]
    local angleOffset = math.atan2(-firstSegment.x, firstSegment.y)

    for i, value in ipairs(points) do
        resultPath[i] = (value - points[1]):rotate(-angleOffset)
    end

    local finalSegment = resultPath[#resultPath] - resultPath[#resultPath - 1]
    local finalAng = math.atan2(finalSegment.y, finalSegment.x)

    for i = 1, EXTRA_POINTS do
        resultPath[#resultPath + 1] = resultPath[#resultPath] + Vector:new(1, 0):rotate(finalAng)
    end

    return Path:new(resultPath, #resultPath - EXTRA_POINTS, filePath.triggerPoints)
end
