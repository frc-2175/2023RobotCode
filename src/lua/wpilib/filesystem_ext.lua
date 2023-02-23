local ffi = require("ffi")

local PathSep = package.config:sub(1,1)

function getDeployDirectory()
	local cstr = ffi.C.GetDeployDirectory()
	local luastr = ffi.string(cstr)
	ffi.C.liberate(ffi.cast("void*", cstr))
	return luastr or "./src/main/deploy/"
end
