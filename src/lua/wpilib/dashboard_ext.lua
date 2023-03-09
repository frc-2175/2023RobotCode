local ffi = require("ffi")

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

function SendableChooser:getSelected()
	local selected = ffi.C.SendableChooser_GetSelected(self._this)

	return self.options[selected].value
end

---@param field Field2d
function SmartDashboard:putField(field)
	ffi.C.PutField(field._this)
end