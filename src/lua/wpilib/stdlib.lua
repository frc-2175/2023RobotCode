-- Automatically generated by gen_bindings.lua. DO NOT EDIT.

local ffi = require("ffi")
require("wpilib.bindings.asserts")
require("wpilib.bindings.enum")

---@param ptr any
function liberate(ptr)
    ffi.C.liberate(ptr)
end
