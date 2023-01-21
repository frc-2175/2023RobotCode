---@class Slideshow
---@field slides string[]
---@field index integer
Slideshow = {}

---@param slides string[]
---@return Slideshow
function Slideshow:new(slides)
	local t = {
		slides = slides,
		index = 1
	}
	setmetatable(t, self)
	self.__index = self

	return t
end

function Slideshow:next()
	self.index = (self.index) % #self.slides + 1
end

function Slideshow:prev()
	self.index = (self.index - 2) % #self.slides + 1
end

function Slideshow:draw()
	putString("Slide", self.slides[self.index])
end

function Slideshow:move(slides)
	self.index = (self.index + slides - 1) % #self.slides + 1
end
