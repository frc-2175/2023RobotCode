-- Automatically generated by gen_bindings.lua. DO NOT EDIT.

local ffi = require("ffi")
require("wpilib.bindings.asserts")
require("wpilib.bindings.enum")

---@class Timer
---@field _this Timer
Timer = {}

---@return Timer
function Timer:new()
    local instance = {
        _this = ffi.C.Timer_new(),
    }
    setmetatable(instance, self)
    self.__index = self
    return instance
end

---@return number
function Timer:get()
    return ffi.C.Timer_Get(self._this)
end

function Timer:reset()
    ffi.C.Timer_Reset(self._this)
end

function Timer:start()
    ffi.C.Timer_Start(self._this)
end

function Timer:stop()
    ffi.C.Timer_Stop(self._this)
end

---@param period number
---@return boolean
function Timer:hasElapsed(period)
    period = AssertNumber(period)
    return ffi.C.Timer_HasElapsed(self._this, period)
end

---@param period number
---@return boolean
function Timer:advanceIfElapsed(period)
    period = AssertNumber(period)
    return ffi.C.Timer_AdvanceIfElapsed(self._this, period)
end

---@return number
function Timer:getFPGATimestamp()
    return ffi.C.GetFPGATimestamp()
end

---@return number
function Timer:getMatchTime()
    return ffi.C.GetMatchTime()
end
