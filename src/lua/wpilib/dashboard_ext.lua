local ffi = require("ffi")

ffi.cdef[[
typedef struct { double x, y, rot; } ObjectPose;
void* Field2d_GetObject(void* _this, const char* name);
void FieldObject2d_SetPose(void* _this, double x, double y, double rotation);
void FieldObject2d_SetPoses(void* _this, ObjectPose* poses, size_t count);
]]

function SmartDashboard:getString(keyName)
	local cstr = ffi.C.SmartDashboard_GetString(keyName, nil)
	local luastr = ffi.string(cstr)
	ffi.C.liberate(ffi.cast("void*", cstr))
	return luastr
end

---@param keyName string
---@param value boolean[]
function SmartDashboard:putBooleanArray(keyName, value)
    ffi.C.PutBooleanArray(keyName, ffi.new("int[?]", #value, value), #value)
end

---@param keyName string
---@param defaultValue boolean[]?
---@return boolean[]
function SmartDashboard:getBooleanArray(keyName, defaultValue)
	defaultValue = defaultValue or {}
    return ffi.new("int[?]", ffi.C.SmartDashboard_GetBooleanArraySize(keyName), ffi.C.GetBooleanArray(keyName, ffi.new("int[?]", #defaultValue, defaultValue), #defaultValue))
end

---@param keyName string
---@param value number[]
function SmartDashboard:putNumberArray(keyName, value)
    ffi.C.PutNumberArray(keyName, ffi.new("double[?]", #value, value), #value)
end

---@param keyName string
---@param value string[]
function SmartDashboard:putStringArray(keyName, value)
    ffi.C.PutStringArray(keyName, ffi.new("const char *[?]", #value, value), #value)
end

---@param name string
---@param options table
function SendableChooser:putChooser(name, options)
	self.options = options

	for i, option in ipairs(options) do
		self:addOption(option.name, i)
	end

	ffi.C.PutIntChooser(name, self._this)
end

---@return any?
function SendableChooser:getSelected()
	local selected = ffi.C.SendableChooser_GetSelected(self._this)
	local selectedOption = self.options[selected]
	
	return selectedOption and selectedOption.value
end

---@param field Field2d
function SmartDashboard:putField(field)
	ffi.C.PutField(field._this)
end

---@class FieldObject2d
---@field _this FieldObject2d
FieldObject2d = {}

---@param name string
---@return FieldObject2d
function Field2d:getObject(name)
    local instance = {
        _this = ffi.C.Field2d_GetObject(self._this, name),
    }
    setmetatable(instance, FieldObject2d)
    FieldObject2d.__index = FieldObject2d

	return instance
end

function FieldObject2d:setPose(x, y, rot)
	ffi.C.FieldObject2d_SetPose(self._this, x, y, rot)
end

function FieldObject2d:setPoses(poses)
	ffi.C.FieldObject2d_SetPoses(self._this, ffi.new("ObjectPose[?]", #poses, poses), #poses)
end