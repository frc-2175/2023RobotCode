local json = require("utils.json")
require("wpilib.time")
require("wpilib.filesystem")

local path
local file

function initLogging()
	os.execute("mkdir -p /home/lvuser/logs")
	path = "/home/lvuser/logs/" .. os.date():gsub(":", "."):gsub(" ", "-") .. ".log"
	print(path)
	file, errorMessage = io.open(path, "w")
	io.output(file)
end

local currentID = -1

function uniqueID()
	currentID = currentID + 1
	return currentID
end

function writeLine(table)
	file:write(json.encode(table), "\n")
	file:flush()
end

local logMetatable = {
	stop = function(self)
		self.time = getFPGATimestamp()
		writeLine(self)
	end,
}
logMetatable.__index = logMetatable

function log(message, parent)
	parent = parent or -1

	local log = {
		type = "event",
		message = message,
		id = uniqueID(),
		time = getFPGATimestamp(),
		parent = parent,
	}
	setmetatable(log, logMetatable)

	writeLine(log)

	return log
end

local dataMetatable = {
	update = function(self, value)
		self.time = getFPGATimestamp()
		self.value = value
		writeLine(self)
	end,
}
dataMetatable.__index = dataMetatable

function logData(name, value)
	local data = {
		type = "data",
		name = name,
		time = getFPGATimestamp(),
		value = value,
	}
	setmetatable(data, dataMetatable)

	writeLine(data)

	return data
end
