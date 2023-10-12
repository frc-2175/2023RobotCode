---------------
-- UTILITIES --
---------------

function string.trimLeft(s)
	return s:gsub("^%s*(.-)$", "%1")
end

function string.trimRight(s)
	return s:gsub("^(.-)%s*$", "%1")
end

function string.trim(s)
	return s:gsub("^%s*(.-)%s*$", "%1")
end

function printf(format, ...)
	print(string.format(format, ...))
end

function errorf(format, ...)
	return error(string.format(format, ...), 2)
end

function errorf2(depth, format, ...)
	return error(string.format(format, ...), depth + 1)
end

function writef(file, format, ...)
	return file:write(string.format(format, ...))
end

-------------------
-- ACTUAL PARSER --
-------------------

f = io.open("src/bindings/bindings.metadesk"):read("a")

function nextToken(advance)
::again::
	f = f:trimLeft()

	local goAgain = false
	local patterns = {
		{ "^@%w+", function (m)
			return { type = "tag", name = m:sub(2) }
		end },
		{ "^%(", function (m)
			return { type = "(" }
		end },
		{ "^%)", function (m)
			return { type = ")" }
		end },
		{ "^{", function (m)
			return { type = "{" }
		end },
		{ "^}", function (m)
			return { type = "}" }
		end },
		{ "^:", function (m)
			return { type = ":" }
		end },
		{ "^,", function (m)
			return { type = "," }
		end },
		{ "^;", function (m)
			return { type = ";" }
		end },
		{ "^\"\"\".-\"\"\"", function (m)
			return { type = "string", contents = m:sub(4, m:len() - 3) }
		end },
		{ "^\".-\"", function (m)
			return { type = "string", contents = m:sub(2, m:len() - 1) }
		end },
		{ "^'.-'", function (m)
			return { type = "string", contents = m:sub(2, m:len() - 1) }
		end },
		{ "^%d+", function (m)
			return { type = "number", value = tonumber(m) }
		end },
		{ "^[%w_*]+", function (m)
			return { type = "identifier", name = m }
		end },
		{ "^//.-\n", function ()
			goAgain = true
		end }
	}

	for i, p in ipairs(patterns) do
		local m = f:match(p[1])
		if m ~= nil then
			local result = p[2](m)
			if goAgain or advance then
				f = f:sub(m:len() + 1)
			end
			if goAgain then
				goto again
			end

			return result
		end
	end

	errorf("unknown token: %s", f:match("%g+"))
	os.exit(1)
end

function eof()
	return f:trim() == ""
end

function readAll(open, close)
	f = f:trimLeft()
	local m = f:match("%b"..open..close)
	if m == nil then
		error("couldn't read a section", 2)
	end
	f = f:sub(m:len() + 1)
	return m
end

function expect(...)
	local t = nextToken(true)
	if t == nil then
		error("nothing left in file")
	end

	local args = table.pack(...)
	for i, type in ipairs(args) do
		if t.type == type then
			return t
		end
	end
	errorf2(2, "bad type of token: got %s, expected one of {%s}", t.type, table.concat(args, ", "))
end

function nextIs(...)
	local t = nextToken(false)
	if t == nil then
		return false
	end

	local args = table.pack(...)
	for i, type in ipairs(args) do
		if t.type == type then
			return true
		end
	end
	return false
end

function parseTag(t, allowedNames)
	local allowed = false
	for i, name in ipairs(allowedNames) do
		if t.name == name then
			allowed = true
			break
		end
	end
	if not allowed then
		errorf("tag @%s not allowed here, expected one of {%s}", t.name, table.concat(allowedNames, ", "))
	end

	bareTags = {"constructor", "nolua", "static", "baseclass", "deref"}
	stringTags = {"include", "cpp", "doc", "deref", "converter", "extends", "construct"}
	identTags = {"renameTo", "enum"}

	local result = nil
	for i, name in ipairs(bareTags) do
		if t.name == name then
			return { type = t.name }
		end
	end
	for i, name in ipairs(stringTags) do
		if t.name == name then
			expect("(")
			result = { type = name, value = expect("string").contents }
			expect(")")
			return result
		end
	end
	for i, name in ipairs(identTags) do
		if t.name == name then
			expect("(")
			result = { type = name, name = expect("identifier").name }
			expect(")")
			return result
		end
	end

	if t.name == "default" then
		expect("(")
		local vt = expect("number", "identifier", "string")
		local value = nil
		if vt.type == "number" then
			value = tostring(vt.value)
		elseif vt.type == "identifier" then
			value = vt.name
		elseif vt.type == "string" then
			value = vt.contents
		end
		result = { type = "default", value = value }
		expect(")")
	elseif t.name == "value" then
		expect("(")
		result = { type = "value", value = expect("number").value }
		expect(")")
	elseif t.name == "cast" then
		if nextIs("(") then
			expect("(")
			result = { type = "cast", value = expect("string").contents }
			expect(")")
		else
			result = { type = "cast", name = nil }
		end
	else
		errorf("unknown tag @%s", t.name)
	end

	return result
end

function parseTags(...)
	local allowedNames = table.pack(...)
	local result = {}
	for i, name in ipairs(allowedNames) do
		result[name] = {}
	end

	while nextIs("tag") do
		local t = expect("tag")
		local parsed = parseTag(t, allowedNames)
		table.insert(result[t.name], parsed)
	end

	return result
end

function expectTags(tags, allowedNames)
	for tagName, parsedTags in pairs(tags) do
		local allowed = false
		for i, allowedName in ipairs(allowedNames) do
			if tagName == allowedName then
				allowed = true
				break
			end
		end
		if not allowed and #parsedTags > 0 then
			errorf2(2, "tag @%s is not allowed here, expected one of {%s}", tagName, table.concat(allowedNames, ", "))
		end
	end
end

function expectOneTag(tags, name)
	if tags[name] == nil then
		errorf2(2, "tried to check for tag @%s but that tag was never parsed", name)
	end
	if #tags[name] ~= 1 then
		errorf2(2, "expected one occurrence of @%s but got %d", name, #tags[name])
	end
	return tags[name][1]
end

function expectAtMostOneTag(tags, name)
	if tags[name] == nil then
		errorf2(2, "tried to check for tag @%s but that tag was never parsed", name)
	end
	if #tags[name] > 1 then
		errorf2(2, "expected at most one occurrence of @%s but got %d", name, #tags[name])
	end
	return tags[name][1]
end

function hasOneOfTag(tags, name)
	return expectAtMostOneTag(tags, name) ~= nil
end

function parseTypeAndName()
	local nameChunks = {}
	while nextIs("identifier") do
		table.insert(nameChunks, expect("identifier").name)
	end

	if #nameChunks == 1 then
		return nil, nameChunks[1]
	else
		local type = table.concat({table.unpack(nameChunks, 1, #nameChunks - 1)}, " ")
		local name = nameChunks[#nameChunks]
		return type, name
	end
end

funcTags = {"doc", "constructor", "nolua", "renameTo", "static", "converter", "cast"}

function parseFunc(tags)
	local func = {
		type = "function",
		name = nil,
		returnType = nil,
		args = {},
		doc = nil,
		body = nil,

		isConstructor = false,
		isStatic = false,
		isNoLua = false,
		renameTo = nil,
		convertsTo = nil,
		castReturn = false,
	}

	expectTags(tags, funcTags)

	func.returnType, func.name = parseTypeAndName()

	printf("  Parsing func %s...", func.name)

	local docTag = expectAtMostOneTag(tags, "doc")
	if docTag then
		func.doc = docTag.value
	end

	func.isConstructor = hasOneOfTag(tags, "constructor")
	func.isStatic = hasOneOfTag(tags, "static")
	func.isNoLua = hasOneOfTag(tags, "nolua")
	if hasOneOfTag(tags, "renameTo") then
		func.renameTo = expectOneTag(tags, "renameTo").name
	end
	if hasOneOfTag(tags, "converter") then
		func.convertsTo = expectOneTag(tags, "converter").value
	end
	func.castReturn = hasOneOfTag(tags, "cast")

	if func.isConstructor and func.isStatic then
		errorf("function %s cannot be both a constructor and static", func.name)
	end

	-- parse arguments
	expect("(")
	while not nextIs(")") do
		local arg = {
			name = nil,
			type = nil,

			enum = nil,
			default = nil,
			castTo = nil,
			deref = false,
			value = nil, -- value hardcoded in the generated Lua
			cppConstructor = nil, -- cpp constructor to call with the argument
		}
		table.insert(func.args, arg)

		local tags = parseTags("cast", "enum", "default", "deref", "value", "construct")

		arg.type, arg.name = parseTypeAndName()

		local enum = expectAtMostOneTag(tags, "enum")
		if enum then
			arg.enum = enum.name
		end

		local default = expectAtMostOneTag(tags, "default")
		if default then
			arg.default = default.value
		end

		local cast = expectAtMostOneTag(tags, "cast")
		if cast then
			arg.castTo = cast.value
		end

		arg.deref = hasOneOfTag(tags, "deref")

		local value = expectAtMostOneTag(tags, "value")
		if value then
			arg.value = value.value
		end

		local cppConstructor = expectAtMostOneTag(tags, "construct")
		if cppConstructor then
			arg.cppConstructor = cppConstructor.value
		end

		if nextIs(")") then
			break
		end
		expect(",")
	end
	expect(")")

	if nextIs("{") then
		func.body = readAll("{", "}"):sub(2, -2):trim()
	else
		expect(";")
	end

	return func
end

-----------------------
-- OUTPUT GENERATION --
-----------------------

function luaTypeFromCType(cType)
	if cType == "bool" then
		return "boolean"
	elseif cType == "int" then
		return "integer"
	elseif cType == "float" or cType == "double" then
		return "number"
	elseif cType == "void" then
		return "nil"
	elseif cType:match("const +char **") or cType:match("char +const **") then
		return "string"
	else
		return "any"
	end
end

function genMethodName(luaClassName, funcName)
	return string.format("%s_%s", luaClassName, funcName)
end

function genLuaDocComment(func, class)
	local types = {}
	for _, arg in ipairs(func.args) do
		if not arg.value then
			table.insert(types, string.format(
				"---@param %s%s %s",
				arg.name, arg.default and "?" or "", luaTypeFromCType(arg.type)
			))
		end
	end
	if func.isConstructor then
		table.insert(types, string.format(
			"---@return %s",
			class.name
		))
	elseif func.returnType then
		local luaType = luaTypeFromCType(func.returnType)
		if luaType ~= "nil" then
			table.insert(types, string.format(
				"---@return %s",
				luaType
			))
		end
	end

	local doc = func.doc and string.format("-- %s\n", func.doc) or ""
	local allTypes = table.concat(types, "\n")
	if allTypes ~= "" then
		allTypes = allTypes .. "\n"
	end

	return string.format(
		"%s"..
		"%s",
		doc,
		allTypes
	)
end

function genFunc(func, class)
	local isMethod = class ~= nil and not func.isStatic

	---------------------
	-- C++ ingredients --
	---------------------

	local wpilibName = func.name
	local renamed = func.renameTo or func.name
	local cppWrapperName = isMethod and genMethodName(class.name, renamed) or renamed
	local cppDocs = func.doc and string.format("// %s\n", func.doc) or ""
	local cppReturnType = func.returnType or "void"

	-- Arguments used in the signature of the C wrapper function
	local cppSigArgs = {}
	if isMethod and not func.isConstructor then
		table.insert(cppSigArgs, "void* _this")
	end
	for _, arg in ipairs(func.args) do
		table.insert(cppSigArgs, string.format("%s %s", arg.type, arg.name))
	end

	-- Arguments used when calling the WPILib C++ function from the C wrapper function.
	-- Handles: @cast, @deref, @construct
	local cppCallArgs = {}
	for _, arg in ipairs(func.args) do
		local deref = arg.deref and "*" or ""
		local cast = arg.castTo and string.format("(%s)", arg.castTo) or ""
		if arg.cppConstructor then
			table.insert(cppCallArgs, string.format(
				"%s(%s%s%s)",
				arg.cppConstructor, deref, cast, arg.name
			))
		else
			table.insert(cppCallArgs, string.format(
				"%s%s%s",
				deref, cast, arg.name
			))
		end
	end

	---------------------
	-- Lua ingredients --
	---------------------

	-- Doc comment
	local luaDocComment = genLuaDocComment(func, class)

	-- Extra lines at the top of the nice Lua function that modify the provided arguments.
	local luaMods = {}
	for _, arg in ipairs(func.args) do
		-- @default tags
		if arg.default then
			table.insert(luaMods, string.format(
				"    %s = %s == nil and %s or %s",
				arg.name, arg.name, arg.default, arg.name
			))
		end

		-- @enum tags
		if arg.enum then
			table.insert(luaMods, string.format(
				"    %s = AssertEnumValue(%s, %s)",
				arg.name, arg.enum, arg.name
			))
		end

		-- Extra type assertions
		if not arg.value then
			if arg.type == "int" then
				table.insert(luaMods, string.format(
					"    %s = AssertInt(%s)",
					arg.name, arg.name
				))
			elseif arg.type == "float" or arg.type == "double" then
				table.insert(luaMods, string.format(
					"    %s = AssertNumber(%s)",
					arg.name, arg.name
				))
			end
		end
	end
	local luaModsStr = table.concat(luaMods, "\n")..(#luaMods > 0 and "\n" or "")

	-- Arguments used when calling the Lua FFI function from the nice Lua function.
	-- Handles: @value
	local luaCallArgs = {}
	if isMethod and not func.isConstructor then
		table.insert(luaCallArgs, "self._this")
	end
	for _, arg in ipairs(func.args) do
		table.insert(luaCallArgs, arg.value or arg.name)
	end

	-- Arguments that will appear in the nice Lua function's signature.
	local luaSigArgs = {}
	for _, arg in ipairs(func.args) do
		if not arg.value then
			table.insert(luaSigArgs, arg.name)
		end
	end

	-----------------------------------
	-- C++ and Lua wrapper functions --
	-----------------------------------

	local cppBody, luaBody

	if func.body then
		cppBody = func.body
	end

	local isVoid = cppReturnType == "void" and not func.convertsTo
	if isMethod and isVoid then
		cppBody = cppBody or string.format(
			"    ((%s*)_this)\n"..
			"        ->%s(%s);",
			class.cppClass,
			wpilibName, table.concat(cppCallArgs, ", ")
		)
		luaBody = luaBody or string.format(
			"%s"..
			"    ffi.C.%s(%s)",
			luaModsStr,
			cppWrapperName, table.concat(luaCallArgs, ", ")
		)
	elseif isMethod and not isVoid then
		cppBody = cppBody or string.format(
			"    auto _result = ((%s*)_this)\n"..
			"        ->%s(%s);\n"..
			"    return (%s)_result;",
			class.cppClass,
			wpilibName, table.concat(cppCallArgs, ", "),
			cppReturnType
		)
		luaBody = luaBody or string.format(
			"%s"..
			"    return ffi.C.%s(%s)",
			luaModsStr,
			cppWrapperName, table.concat(luaCallArgs, ", ")
		)
	elseif not isMethod and isVoid then
		cppBody = cppBody or string.format(
			"    %s::%s(%s);",
			class.cppClass, wpilibName, table.concat(cppCallArgs, ", ")
		)
		luaBody = luaBody or string.format(
			"%s"..
			"    ffi.C.%s(%s)",
			luaModsStr,
			cppWrapperName, table.concat(luaCallArgs, ", ")
		)
	elseif not isMethod and not isVoid then
		cppBody = cppBody or string.format(
			"    auto _result = %s::%s(%s);\n"..
			"    return (%s)_result;",
			class.cppClass, wpilibName, table.concat(cppCallArgs, ", "),
			cppReturnType
		)
		luaBody = luaBody or string.format(
			"%s"..
			"    return ffi.C.%s(%s)",
			luaModsStr,
			cppWrapperName, table.concat(luaCallArgs, ", ")
		)
	else
		error("messed up some cases")
	end

	-----------------------------------------
	-- Overrides for constructors and such --
	-----------------------------------------

	if func.isConstructor then -- handle @constructor
		cppReturnType = "void*"
		cppBody = string.format(
			"    return new %s(%s);",
			class.cppClass, table.concat(cppCallArgs, ", ")
		)
		luaBody = string.format(
			"%s"..
			"    local instance = {\n"..
			"        _this = ffi.C.%s(%s),\n"..
			"    }\n"..
			"    setmetatable(instance, self)\n"..
			"    self.__index = self\n"..
			"    return instance",
			luaModsStr,
			genMethodName(class.name, func.name), table.concat(luaCallArgs, ", ")
		)
	elseif func.convertsTo then -- handle @converter
		cppReturnType = "void*"
		cppBody = string.format(
			"    %s* _converted = (%s*)_this;\n"..
			"    return _converted;",
			func.convertsTo, class.cppClass
		)
	end

	------------------
	-- Final output --
	------------------

	-- Generate full C++ wrapper function
	local cppSignature = string.format(
		"%s %s(%s)",
		cppReturnType, cppWrapperName, table.concat(cppSigArgs, ", ")
	)
	local cppFunction = string.format(
		"%s"..
		"LUAFUNC %s {\n"..
		"%s\n"..
		"}\n",
		cppDocs,
		cppSignature,
		cppBody
	)

	-- Generate full nice Lua function
	local methodReceiver = (isMethod or func.isStatic) and string.format("%s:", class.name) or ""
	local lowercasedName = renamed:sub(1, 1):lower() .. renamed:sub(2, -1)
	local luaFunction = string.format(
		"%s"..
		"function %s%s(%s)\n"..
		"%s\n"..
		"end\n",
		luaDocComment,
		methodReceiver, lowercasedName, table.concat(luaSigArgs, ", "),
		luaBody
	)

	local result = {
		cppFunction = cppFunction,
		luaBindingSignature = string.format("%s;", cppSignature),
		luaFunction = luaFunction,
	}
	if func.isNoLua then
		result.luaFunction = nil
	end

	return result
end

------------------
-- MAIN PROGRAM --
------------------

-- Parse files
files = {}
while not eof() do
	local file = {
		name = nil,
		includes = {},
		defs = {},
	}
	table.insert(files, file)

	local tags = parseTags("include")
	local defType = expect("identifier").name
	if defType ~= "file" then
		errorf("expected a file definition, got '%s'", defType)
	end
	file.name = expect("identifier").name
	for i, include in ipairs(tags.include) do
		table.insert(file.includes, include.value)
	end
	printf("Parsing file \"%s\"...", file.name)

	expect("{")
	while not nextIs("}") do
		local tags = parseTags("cpp", "baseclass", "extends", table.unpack(funcTags))

		local defType = expect("identifier").name
		if defType == "enum" then
			local enum = {
				type = "enum",
				name = nil,
				fields = {},
			}
			table.insert(file.defs, enum)

			expectTags(tags, {})
			enum.name = expect("identifier").name
			printf("Parsing enum %s...", enum.name)

			expect("{")
			while not nextIs("}") do
				local name = expect("identifier").name
				expect(":")
				local num = expect("number").value
				expect(",")
				table.insert(enum.fields, { name = name, value = num })
			end
			expect("}")
			printf("  Parsed %d fields", #enum.fields)
		elseif defType == "class" then
			local class = {
				type = "class",
				name = nil,
				cppClass = nil,
				funcs = {},

				isBaseClass = false,
				extends = {},
			}
			table.insert(file.defs, class)

			expectTags(tags, {"cpp", "baseclass", "extends"})
			local nameToken = expect("identifier", "string")
			if nameToken.type == "identifier" then
				class.name = nameToken.name
			else
				class.name = nameToken.contents
			end
			printf("Parsing class %s...", class.name)

			if hasOneOfTag(tags, "baseclass") then
				class.isBaseClass = true
			end
			if not class.isBaseClass then
				class.cppClass = expectOneTag(tags, "cpp").value
			end

			for i, extends in ipairs(tags["extends"]) do
				table.insert(class.extends, extends.value)
			end

			-- parse function declarations
			expect("{")
			while not nextIs("}") do
				local tags = parseTags(table.unpack(funcTags))
				local func = parseFunc(tags)
				table.insert(class.funcs, func)
			end
			expect("}")
		elseif defType == "function" then
			local func = parseFunc(tags)
			if func.isConstructor then
				error("a function outside a class cannot be a constructor")
			end
			if func.isStatic then
				error("a function outside a class cannot be static (unless...?)")
			end
			table.insert(file.defs, func)
		elseif defType == "struct" then
			local struct = {
				type = "struct",
				name = nil,
				fields = {},
			}
			table.insert(file.defs, struct)

			expectTags(tags, {})
			struct.name = expect("identifier").name
			printf("  Parsing struct %s...", struct.name)

			expect("{")
			while not nextIs("}") do
				local type, name1 = parseTypeAndName()
				local names = {name1}
				while nextIs(",") do
					expect(",")
					table.insert(names, expect("identifier").name)
				end
				expect(";")

				for i, name in ipairs(names) do
					table.insert(struct.fields, {
						type = type,
						name = name,
					})
				end
			end
			expect("}")
		else
			errorf("unknown thing '%s' in file", defType)
		end
	end
	expect("}")

	print("Finished file.")
	print()
end

-- Emit Lua and C++ files
local luaSignatures = {}
for _, file in ipairs(files) do
	local cppfile = assert(io.open(string.format("src/main/cpp/wpiliblua/%s.cpp", file.name), "w"))
	local luafile = assert(io.open(string.format("src/lua/wpilib/%s.lua", file.name), "w"))

	-- C++ preamble
	writef(cppfile, "// Automatically generated by gen_bindings.lua. DO NOT EDIT.\n\n")
	for _, include in ipairs(file.includes) do
		writef(cppfile, "#include %s\n", include)
	end
	writef(cppfile, "\n")
	writef(cppfile, "#include \"luadef.h\"\n\n")

	-- Lua preamble
	writef(luafile, "-- Automatically generated by gen_bindings.lua. DO NOT EDIT.\n")
	writef(luafile, "\n")
	writef(luafile, "local ffi = require(\"ffi\")\n")
	writef(luafile, "require(\"wpilib.bindings.asserts\")\n")
	writef(luafile, "require(\"wpilib.bindings.enum\")\n")
	writef(luafile, "\n")

	local baseClasses = {}
	local cppDefs, luaDefs = {}, {}
	for _, def in ipairs(file.defs) do
		if def.type == "class" then
			if def.isBaseClass then
				baseClasses[def.name] = def
			else
				writef(luafile, "---@class %s\n", def.name)
				writef(luafile, "---@field _this %s\n", def.name)
				writef(luafile, "%s = {}\n", def.name)
				writef(luafile, "\n")

				for _, extends in ipairs(def.extends) do
					local baseClass = assert(baseClasses[extends], string.format("unknown base class '%s'", extends))
					for _, func in ipairs(baseClass.funcs) do
						local result = genFunc(func, def)
						table.insert(cppDefs, result.cppFunction)
						table.insert(luaSignatures, result.luaBindingSignature)
						if result.luaFunction then
							table.insert(luaDefs, result.luaFunction)
						end
					end
				end

				for _, func in ipairs(def.funcs) do
					local result = genFunc(func, def)
					table.insert(cppDefs, result.cppFunction)
					table.insert(luaSignatures, result.luaBindingSignature)
					if result.luaFunction then
						table.insert(luaDefs, result.luaFunction)
					end
				end
			end
		elseif def.type == "enum" then
			local values, valueTypes = {}, {}
			for _, field in ipairs(def.fields) do
				table.insert(values, string.format(
					"    %s = %d,",
					field.name, field.value
				))
				table.insert(valueTypes, string.format(
					"---@field %s integer",
					field.name
				))
			end
			table.insert(luaDefs, string.format(
				"---@class %s\n"..
				"%s\n"..
				"%s = BindingEnum:new('%s', {\n"..
				"%s\n"..
				"})\n",
				def.name,
				table.concat(valueTypes, "\n"),
				def.name, def.name,
				table.concat(values, "\n")
			))
		elseif def.type == "struct" then
			local members = {}
			for _, field in ipairs(def.fields) do
				table.insert(members, string.format(
					"    %s %s;",
					field.type, field.name
				))
			end
			local struct = string.format(
				"typedef struct {\n"..
				"%s\n"..
				"} %s;\n",
				table.concat(members, "\n"),
				def.name
			):trim()
			table.insert(cppDefs, struct.."\n")
			table.insert(luaSignatures, struct)
		elseif def.type == "function" then
			local result = genFunc(def, nil)
			table.insert(cppDefs, result.cppFunction)
			table.insert(luaSignatures, result.luaBindingSignature)
			if result.luaFunction then
				table.insert(luaDefs, result.luaFunction)
			end
		end
	end

	writef(cppfile, table.concat(cppDefs, "\n"))
	writef(luafile, table.concat(luaDefs, "\n"))
end

-- Output Lua FFI bindings
local luafile = assert(io.open("src/lua/wpilib/bindings/init.lua", "w"))
writef(luafile,
	"-- Automatically generated by gen_bindings.lua. DO NOT EDIT.\n"..
	"\n"..
	"local ffi = require(\"ffi\")\n"..
	"ffi.cdef[[\n"..
	"%s\n"..
	"]]\n",
	table.concat(luaSignatures, "\n")
)
