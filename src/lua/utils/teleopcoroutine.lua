
---@class FancyCoroutine
---@field coroutineFunc function
---@field coroutine any
---@field wasRunning boolean
---@field done boolean
FancyCoroutine = {}

---@param coroutineFunc function
---@return FancyCoroutine
function FancyCoroutine:new(coroutineFunc)
	local t = {
		coroutineFunc = coroutineFunc,
		coroutine = nil,
		wasRunning = false,
		done = false,
		-- runWhile = function(self, running)
		-- 	if running then
		-- 		if not self.wasRunning then
		-- 			self.coroutine = coroutine.create(self.coroutineFunc)
		-- 		end
		-- 		if coroutine.status(self.coroutine) ~= "dead" then
		-- 			local status, err = coroutine.resume(self.coroutine)
		-- 			if status == false then
		-- 				-- TODO: Better logging than this?
		-- 				print(err)
		-- 			end
		-- 		end
		-- 	end
		-- 	self.wasRunning = running
		-- 	return running
		-- end,
	}
	setmetatable(t, self)
	self.__index = self

	return t
end

function FancyCoroutine:reset() 
	self.wasRunning = false
	self.done = false
end

function FancyCoroutine:run()
	if not self.wasRunning then
		self.coroutine = coroutine.create(self.coroutineFunc)
		self.wasRunning = true
	end

	local ok, yield = coroutine.resume(self.coroutine)
	if not ok then
		self.done = true
		error(yield)
	end

	if coroutine.status(self.coroutine) == "dead" then
		self.done = true
	end

	return yield
end

function FancyCoroutine:runUntilDone()
	while not self.done do
		self:run()
		coroutine.yield()
	end
end
