function AssertInt(value)
	if not (type(value) == "number" and value % 1 == 0) then
		local msg = "Expected an integer, but got " .. tostring(value) .. " instead."
		io.stderr:write(Red .. "ERROR" .. ResetColor .. ":\n")
		io.stderr:write("    " .. msg .. "\n")
		error(msg, 2)
	end
	return value
end

function AssertNumber(value)
	if type(value) ~= "number" then
		local msg = "Expected a number, but got " .. tostring(value) .. " instead."
		io.stderr:write(Red .. "ERROR" .. ResetColor .. ":\n")
		io.stderr:write("    " .. msg .. "\n")
		error(msg, 2)
	end
	return value
end
