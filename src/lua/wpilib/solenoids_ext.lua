local ffi = require("ffi")

function Solenoid:new(channel)
	channel = AssertInt(channel)
	local instance = {
		_this = ffi.C.Solenoid_new(0, channel),
	}
	setmetatable(instance, self)
	self.__index = self
	return instance
end

function DoubleSolenoid:new(forwardChannel, reverseChannel)
	forwardChannel = AssertInt(forwardChannel)
	reverseChannel = AssertInt(reverseChannel)
	local instance = {
		_this = ffi.C.DoubleSolenoid_new(0, forwardChannel, reverseChannel),
	}
	setmetatable(instance, self)
	self.__index = self
	return instance
end
