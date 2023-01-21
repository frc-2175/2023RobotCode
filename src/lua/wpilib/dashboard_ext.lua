local ffi = require("ffi")

function SendableChooser:putChooser(options)
	self.options = options

	for i, option in ipairs(options) do
		self:addOption(option.name, i)
	end

	ffi.C.PutIntChooser(self._this)
end

function SendableChooser:getSelected()
	local selected = ffi.C.SendableChooser_GetSelected(self._this)

	return self.options[selected].value
end
