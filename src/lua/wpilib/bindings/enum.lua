require("utils.colors")

BindingEnum = {}
local BindingEnumValue = {}

function BindingEnum:new(name, values)
	local enum = {
		_name = name,
		_names = {},
	}
	setmetatable(enum, self)
	-- we do not do the __index stuff here, because it needs to be fancier

	for name, value in pairs(values) do
		enum:addValue(name, value)
	end

	return enum
end

function BindingEnum:addValue(name, value)
	self[name] = BindingEnumValue:new(self, name, value)
	table.insert(self._names, name)
end

function BindingEnum:__index(name)
	if rawget(self, name) then
		return rawget(self, name)
	elseif rawget(BindingEnum, name) then
		return rawget(BindingEnum, name)
	else
		local msg = self._name .. "." .. name .. " is not a valid value."
		io.stderr:write(Red .. "ERROR" .. ResetColor .. ":\n")
		io.stderr:write("    " .. msg .. "\n")
		io.stderr:write("    Use one of the following values instead:\n")
		for _, name in ipairs(self._names) do
			io.stderr:write("      " .. tostring(self) .. "." .. name .. "\n")
		end
		error(msg, 2)
	end
end

function BindingEnum:__tostring()
	return self._name
end

function BindingEnumValue:new(type, name, value)
	local v = {
		_type = type,
		_name = name,
		_value = value,
	}
	setmetatable(v, self)
	self.__index = self
	return v
end

function BindingEnumValue:__tostring()
	return self._type._name .. "." .. self._name
end

function AssertEnumValue(type, value)
	if getmetatable(value) ~= BindingEnumValue or value._type ~= type then
		local msg = "Expected a value of type " .. tostring(type) .. ", but got " .. tostring(value) .. " instead."
		io.stderr:write(Red .. "ERROR" .. ResetColor .. ":\n")
		io.stderr:write("    " .. msg .. "\n")
		io.stderr:write("    Use one of the following values instead:\n")
		for _, name in ipairs(type._names) do
			io.stderr:write("      " .. tostring(type) .. "." .. name .. "\n")
		end
		error(msg, 2)
	end
	return value._value
end

test("BindingEnum", function(t)
	local MyEnum = BindingEnum:new("MyEnum", {
		Foo = 1,
		Bar = 3,
	})
	local OtherEnum = BindingEnum:new("OtherEnum", {
		Zing = 10,
		Zang = 100,
	})

	t:assertEqual(AssertEnumValue(MyEnum, MyEnum.Foo), 1)
	t:assertEqual(AssertEnumValue(MyEnum, MyEnum.Bar), 3)

	t:assertDoesError(function()
		print(MyEnum.ThisDoesNotExist)
	end)
	t:assertDoesError(function()
		print(AssertEnumValue(OtherEnum, MyEnum.Foo))
	end)
	t:assertDoesError(function()
		print(AssertEnumValue(MyEnum, 3))
	end)
end)
