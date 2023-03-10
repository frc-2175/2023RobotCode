-- Automatically generated by bindings.c. DO NOT EDIT.

local ffi = require("ffi")
require("wpilib.bindings.asserts")
require("wpilib.bindings.enum")

---@class Solenoid
---@field _this Solenoid
Solenoid = {}

---@class DoubleSolenoid
---@field _this DoubleSolenoid
DoubleSolenoid = {}

---@class DoubleSolenoidValue
---@field Off integer
---@field Forward integer
---@field Reverse integer
DoubleSolenoidValue = BindingEnum:new('DoubleSolenoidValue', {
    Off = 0,
    Forward = 1,
    Reverse = 2,
})

---@param channel integer
---@return Solenoid
function Solenoid:new(channel)
    channel = AssertInt(channel)
    local instance = {
        _this = ffi.C.Solenoid_new(0, channel),
    }
    setmetatable(instance, self)
    self.__index = self
    return instance
end

---@param on boolean
function Solenoid:set(on)
    ffi.C.Solenoid_Set(self._this, on)
end

---@return boolean
function Solenoid:get()
    return ffi.C.Solenoid_Get(self._this)
end

function Solenoid:toggle()
    ffi.C.Solenoid_Toggle(self._this)
end

---@return integer
function Solenoid:getChannel()
    return ffi.C.Solenoid_GetChannel(self._this)
end

---@return boolean
function Solenoid:isDisabled()
    return ffi.C.Solenoid_IsDisabled(self._this)
end

---@param forwardChannel integer
---@param reverseChannel integer
---@return DoubleSolenoid
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

---@param value integer
function DoubleSolenoid:set(value)
    value = AssertEnumValue(DoubleSolenoidValue, value)
    value = AssertInt(value)
    ffi.C.DoubleSolenoid_Set(self._this, value)
end

---@return integer
function DoubleSolenoid:get()
    return ffi.C.DoubleSolenoid_Get(self._this)
end

function DoubleSolenoid:toggle()
    ffi.C.DoubleSolenoid_Toggle(self._this)
end

---@return integer
function DoubleSolenoid:getFwdChannel()
    return ffi.C.DoubleSolenoid_GetFwdChannel(self._this)
end

---@return integer
function DoubleSolenoid:getRevChannel()
    return ffi.C.DoubleSolenoid_GetRevChannel(self._this)
end

---@return boolean
function DoubleSolenoid:isFwdSolenoidDisabled()
    return ffi.C.DoubleSolenoid_IsFwdSolenoidDisabled(self._this)
end

---@return boolean
function DoubleSolenoid:isRevSolenoidDisabled()
    return ffi.C.DoubleSolenoid_IsRevSolenoidDisabled(self._this)
end
