-- Automatically generated by gen_bindings.lua. DO NOT EDIT.

local ffi = require("ffi")
require("wpilib.bindings.asserts")
require("wpilib.bindings.enum")

---@class SmartDashboard
---@field _this SmartDashboard
SmartDashboard = {}

---@class SendableChooser
---@field _this SendableChooser
SendableChooser = {}

---@class Field2d
---@field _this Field2d
Field2d = {}

---@param key string
---@return boolean
function SmartDashboard:containsKey(key)
    return ffi.C.ContainsKey(key)
end

---@param key string
function SmartDashboard:setPersistent(key)
    ffi.C.SetPersistent(key)
end

---@param key string
function SmartDashboard:clearPersistent(key)
    ffi.C.ClearPersistent(key)
end

---@param key string
---@return boolean
function SmartDashboard:isPersistent(key)
    return ffi.C.IsPersistent(key)
end

---@param keyName string
---@param value boolean
function SmartDashboard:putBoolean(keyName, value)
    ffi.C.PutBoolean(keyName, value)
end

---@param keyName string
---@param defaultValue? boolean
---@return boolean
function SmartDashboard:getBoolean(keyName, defaultValue)
    defaultValue = defaultValue == nil and nil or defaultValue
    return ffi.C.GetBoolean(keyName, defaultValue)
end

---@param keyName string
---@param value number
function SmartDashboard:putNumber(keyName, value)
    value = AssertNumber(value)
    ffi.C.PutNumber(keyName, value)
end

---@param keyName string
---@param defaultValue? number
---@return number
function SmartDashboard:getNumber(keyName, defaultValue)
    defaultValue = defaultValue == nil and nil or defaultValue
    defaultValue = AssertNumber(defaultValue)
    return ffi.C.GetNumber(keyName, defaultValue)
end

---@param keyName string
---@param value string
function SmartDashboard:putString(keyName, value)
    ffi.C.PutString(keyName, value)
end

---@return SendableChooser
function SendableChooser:new()
    local instance = {
        _this = ffi.C.SendableChooser_new(),
    }
    setmetatable(instance, self)
    self.__index = self
    return instance
end

---@param name string
---@param object integer
function SendableChooser:addOption(name, object)
    object = AssertInt(object)
    ffi.C.SendableChooser_AddOption(self._this, name, object)
end

---@return Field2d
function Field2d:new()
    local instance = {
        _this = ffi.C.Field2d_new(),
    }
    setmetatable(instance, self)
    self.__index = self
    return instance
end

---@param x number
---@param y number
---@param rotation number
function Field2d:setRobotPose(x, y, rotation)
    x = AssertNumber(x)
    y = AssertNumber(y)
    rotation = AssertNumber(rotation)
    ffi.C.Field2d_SetRobotPose(self._this, x, y, rotation)
end
