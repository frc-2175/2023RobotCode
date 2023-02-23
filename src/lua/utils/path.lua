require("utils.vector")
require("utils.math")
local json = require("utils.json")
local dir = getDeployDirectory() .. "/paths/"

---@class Path
---@field points Vector[] The path points in field coordinates. (Origin bottom left, inches.)
---@field distances number[] A table with the distance for each path point.
---@field events table[] The events to run along the path. Each table is {distance from start, function to run}.
Path = {}

--[[
what we store internally:
{
	{12, openGripper},
	{50, closeGripper},
	{60, openGripper},
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

	local p = {
		points = points,
		distances = distances,
		events = events,
	}
	setmetatable(p, self)
	self.__index = self

	return p
end

function Path:print()
	for index, value in ipairs(self.points) do
		print(value)
	end
end
