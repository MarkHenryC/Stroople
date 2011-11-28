-- Mark H Carolan
--
-- Stroople project
-- © 2010 Mark H Carolan, Gregory S Hooper

module(..., package.seeall)

require "score"
require "languages"
require "globals"

local distractorTracker = 0
local correctorBias = 2

local direction = 1
local directionCounter = 0
local directionChangeForward = 200
local directionChangeBackward = 50
local rotateTimeout = 2
local rotateCounter = 1

local function newSpiral(resolution, radius, radiusX)

	-- Radii:
	local minRadius = 5
	local maxRadius = radius or globals.H - globals.W4
	local minRadiusX = 3
	local maxRadiusX = radiusX or globals.W - globals.W4
	
	-- How many times around
	local nLoops = 3 
	local nPositions = resolution or 512
	local incr = (nLoops * 360.0) / nPositions
	local radIncr = (maxRadius - minRadius) / nPositions
	local radIncrX = (maxRadiusX - minRadiusX) / nPositions
	local radCntr = 0.0
	local radCntrX = 0.0
	local phase = 0.0
	local posList = {} -- {x, y}
	
	for i = 1, nPositions do
		
		posList[i] =
		{
			(minRadiusX + radCntrX) * math.sin(math.rad(phase)), 
			(minRadius + radCntr) * math.cos(math.rad(phase))
		}
			
		-- Increase radius:
		radCntr = radCntr + radIncr
		radCntrX = radCntrX + radIncrX
		
		-- Next angle step
		phase = phase + incr
		
	end
	
	return posList
end

function createWords(params, resolution)
	local words = display.newGroup()
	
	words.direction = direction
	words.directionCounter = directionCounter
	
	words.firstRunThru = true
	
	words.colorNames = params.colorNames	
	words.fontName = params.fontName
	words.textHeight = params.textHeight or 32
	
	words.points = 512
	
	words.list = newSpiral(words.points)
	
	words.items = 16
	
	words.positions = words.points/words.items			
	
	words.scales = {}
	
	words.scaleIncrement = 1.0 / words.points
	
	for i = 1, words.points do
		words.scales[i] = i * words.scaleIncrement
	end			
	
	function words:scroll(offset)

		local r, ix
		
		for i = 1, self.numChildren do
			r = self[i]
			ix = r.index
			
			if ix == 1 and self.direction == 1 then
				r.isVisible = true
			elseif ix == words.points then
				if r.FLAG and self.direction == 1 then 
					db.print("FLAG")
					self.firstRunThru = false
					r.FLAG = false
				elseif not self.firstRunThru then 
					if self.direction == -1 then 
						r.isVisible = true 
					end
				end
			end
			
			r.x = globals.W2 + self.list[ix][1]
			r.y = globals.H2 + self.list[ix][2]
			
			r.xScale = 0.3 + self.scales[ix]
			r.yScale = 0.4 + self.scales[ix]		
			
			if r.rotating then
				r.rotation = r.rotation + 1
			end
			
			ix = ix + self.direction
			
			if ix > self.points then
				if r.isVisible then
					r:recycle()
				end
				ix = 1			
			elseif ix < 1 then
				if self.firstRunThru then 
					r.isVisible = false
				elseif r.isVisible then
					r:recycle(false)
				end
				ix = self.points						
			end
			
			r.index = ix
		end
		
		self.directionCounter = self.directionCounter + 1
		if self.direction == 1 and self.directionCounter >= directionChangeForward then
			self.direction = -1
			self.directionCounter = 0
		elseif self.direction == -1 and self.directionCounter >= directionChangeBackward then
			self.direction = 1
			self.directionCounter = 0
		end
	end

	function words:newWord(text, font, size)
		local g = display.newGroup()
		
		g.rotateTimeout = rotateTimeout
		g.rotateCounter = rotateCounter
	
		local shadow = display.newText(text, 0, 0, font, size)
		shadow:setTextColor(0, 0, 0)
		shadow.x = 6; shadow.y = 6
		g:insert(shadow)
		
		local t = display.newText(text, 0, 0, font, size)
		t:setTextColor(255, 255, 255)	 -- white means unassigned
		t.x = 0; t.y = 0
		g:insert(t)
		
		g.colorWordIndex = 0 -- zero means unassigned
		g.colorDisplayIndex = 0
		g.clicked = false
		g:addEventListener("touch", g)
				
		function g:setData(wi, ci)
			self.colorWordIndex = wi
			self.colorDisplayIndex = ci
	
			local rgb = words.colorNames[ci][2]
			self[1].text = words.colorNames[wi][1]
			self[2].text = words.colorNames[wi][1]
			self[2]:setTextColor(rgb[1], rgb[2], rgb[3])
			self.clicked = false
		end
		
		function g:checkNotClicked()
			if not self.clicked then
				if self.colorWordIndex == self.colorDisplayIndex then
					-- A correct item was not clicked
					words.score = words.score - 1							
					score.miss(1)
				end
			end	
		end
		
		function g:matching()
			return self.colorWordIndex == self.colorDisplayIndex and true or false
		end
		
		function g:setRandomColor()
			distractorTracker = distractorTracker + 1
			if distractorTracker % globals.distractorProbability == 0 then
				local d, ci = languages.getDistractor()
				local rgb = d[2]
				self[1].text = d[1]
				self[2].text = d[1]
				self[2]:setTextColor(rgb[1], rgb[2], rgb[3])
				
				self.colorWordIndex = 0 -- as long as it doesn't match
				self.colorDisplayIndex = ci
				
				self.clicked = false				
			else
				local colorWordIndex = math.random(1, #words.colorNames)
				local pairing = math.random(1, #words.colorNames * correctorBias)
				if pairing > #words.colorNames then
					self:setData(colorWordIndex, colorWordIndex)
				else
					self:setData(colorWordIndex, pairing)
				end
			end
			
			self.rotateCounter = self.rotateCounter + 1
			if self.rotateCounter >= self.rotateTimeout then
				self.rotation = math.random(1, 360)
				self.rotating = true
			end
			
		end
	
		function g:recycle(penalise)
			if penalise then
				self:checkNotClicked()			
			end
			
			self.isVisible = true
			self.clicked = false
			self.rotation = 0
			self:setRandomColor(#words.colorNames)
		end
		
		function g:touch(event)
			if event.phase == "began" then
			
				local t = event.target
				if t.isVisible then
			
					if t:matching() then
						words.score = words.score + 1
						score.add(1)
					else
						words.score = words.score - 1
						score.sub(1)
					end
					t.clicked = true
					t.isVisible = false
				end
			end	
			return true
		end
		
		return g
	end	

	function words:init()
		self.score = 0
		
		for i = 1, self.items do
			local r = self:newWord(self.fontName, self.fontName, self.textHeight)
			r.index = 1 + (i-1) * self.positions
			r.isVisible = false
			if i == 1 then r.FLAG = true end
			self:insert(r)	
		end
		
		for i = 1, self.numChildren do
			self[i]:setRandomColor(#self.colorNames)
		end
	end
	
	function words:cleanup()

		for i = self.numChildren, 1, -1 do
			self[i]:removeSelf()
		end
	
	end
		
	return words
end