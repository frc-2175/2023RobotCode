-- this is a file

require("utils.vector")
require("utils.math")
local json = require("utils.json")
local dir = getDeployDirectory() .. "/pathplanner/"

---@class Path
---@field points Vector[] The path points in field coordinates. (Origin bottom left, inches.)
---@field distances number[] A table with the distance for each path point. (Cumulative)
---@field events table[] The events to run along the path. Each table is {distance from start, function to run}.
---@field name string
---@field startAngle number
---@field endAngle number
Path = {}

--[[
what we store internally:
{
	{distance = 12, func = openGripper},
	{distance = 50, func = closeGripper},
	{distance = 60, func = openGripper},
}

what it looks like to call Path:new
local myPath = Path:new("MyPath", {
	openGripper = function()
		Arm:openGripper()
	end,
	closeGripper = function()
		Arm:closeGripper()
	end,
})
--]]



---@param pathName string The name of the path in PathPlanner, e.g. "MyPath" for a file named MyPath.path
---@param eventFuncs table<string, function>? A table of functions for path events.
---@return Path
function Path:new(pathName, eventFuncs)
	eventFuncs = eventFuncs or {}

	local points = {}
	local distances = {}
	local events = {}
	-- TODO: Read file, calculate stuff, and save it all on the Path object below

	local rawFile, err = io.open(dir..pathName..".path")
	if rawFile == nil then
		error(err)
	end
	local parsedJSON = json.decode(rawFile:read("*a"))
	
	local waypoints = parsedJSON.waypoints
	local markers = parsedJSON.markers

	local firstPoint = Vector:new(waypoints[1].anchorPoint.x, waypoints[1].anchorPoint.y) * METERS2INCHES
	local firstControl = Vector:new(waypoints[1].nextControl.x, waypoints[1].nextControl.y) * METERS2INCHES
	local startAngle = math.atan2((firstControl - firstPoint).y, (firstControl - firstPoint).x)

	local lastControl = Vector:new(waypoints[#waypoints].prevControl.x, waypoints[#waypoints].prevControl.y) * METERS2INCHES
	local lastPoint = Vector:new(waypoints[#waypoints].anchorPoint.x, waypoints[#waypoints].anchorPoint.y) * METERS2INCHES
	local endAngle = math.atan2((lastPoint - lastControl).y, (lastPoint - lastControl).x)

	for i = 1, #waypoints - 1 do
		local p1 = Vector:new(waypoints[i].anchorPoint.x, waypoints[i].anchorPoint.y)
		local p2 = Vector:new(waypoints[i].nextControl.x, waypoints[i].nextControl.y)
		local p3 = Vector:new(waypoints[i + 1].prevControl.x, waypoints[i + 1].prevControl.y)
		local p4 = Vector:new(waypoints[i + 1].anchorPoint.x, waypoints[i + 1].anchorPoint.y)

		local increment = 0.01
		for t = 0, 1, increment do
			for _, marker in ipairs(markers) do
				if math.floor(marker.position) == i - 1 then -- the marker is on the current segment
					if t - increment < marker.position and marker.position <= t then -- we just crossed the marker
						for _, name in ipairs(marker.names) do
							if eventFuncs[name] == nil then
								error('Function "'.. name ..'" not defined')
							else
								table.insert(events, {
									distance = distances[#distances],
									func = eventFuncs[name],
								})
							end
						end
					end
				end
			end

			local bezierPoint = bezier(t, p1, p2, p3, p4) * METERS2INCHES
			table.insert(points, bezierPoint)
			if 1 < #points then
				table.insert(distances, distances[#distances] + (points[#points - 1] - bezierPoint):length())
			else
				table.insert(distances, 0)
			end
		end
	end

	local p = {
		points = points,
		distances = distances,
		events = events,
		name = pathName,
		startAngle = startAngle,
		endAngle = endAngle,
	}
	setmetatable(p, self)
	self.__index = self

	return p
end

---mirrors a path, does not make a copy
function Path:mirror()
	for _, point in ipairs(self.points) do
		point.x = 651.25 - point.x
	end

	self.startAngle = math.pi - self.startAngle
	self.endAngle = math.pi - self.endAngle
end

function Path:print()
	for _, point in ipairs(self.points) do
		print(point)
	end
end

test("Path:new", function(t)
	local p = Path:new("TestOnlyDoNotEdit", {
		testEvent = function()
			print("wow, an event!")
		end
	})
	t:assertEqual(#p.distances, #p.points, "we should have one distance for each point")
	t:assert(p.events[1].func ~= nil)
end)
