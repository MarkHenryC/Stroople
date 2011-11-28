-- Mark H Carolan
--
-- Stroople project
-- © 2010 Mark H Carolan, Gregory S Hooper

module(..., package.seeall)

require "score"
require "languages"
require "globals"
require "db"

local distractorTracker = 0
local correctorBias = 2

function createWords(params, resolution)
	local words = display.newGroup()
	
	words.direction = direction
	words.directionCounter = directionCounter
		
	words.colorNames = params.colorNames	
	words.fontName = params.fontName
	words.textHeight = params.textHeight or 32

	words.items = 8
	words.range = 360
	words.sectionSize = words.range / words.items
	words.xCentre = globals.W2
	words.yCentre = globals.H2
	words.diameter = globals.W - words.xCentre/2
	words.r = words.diameter / 2
	words.points = {}
	words.images = {}
	words.visual = display.newGroup()
	words.interval = 30
	words.yScale = .75
	words.depthCounter = 0	
			
	function words:sort()	
	
		table.sort(self.images,  
			function(a, b)
				return a.y < b.y
			end
		)
		
		--
		-- Just re-insert. Removing firstly seems to destroy DisplayObjects,
		-- even if the return value from remove() is put into a table.
		--
		
		for i = 1, #self.images do
			self.visual:insert(self.images[i])
		end
		
	end	
	
	function words:rotate()
	
		for i = 1, #self.images do
						
			local img = self.images[i]
			local cntr = img.counter
			
			if cntr == self.switchPoint then
				img:recycle(true)
			end
			
			local xy = self.points[cntr]
			
			img.width = img.origWidth
			img.height = img.origHeight
			img.x = xy[1]
			img.y = xy[2] * self.yScale
			local s = xy[2] / (self.yCentre + self.r)
			img.xScale = s
			img.yScale = s
			cntr = cntr + 1
			
			if cntr > self.range then
				cntr = 1
			end
			
			self.images[i].counter = cntr
			
		end		
			
	end	

	function words:scroll(offset)
		self:rotate()
		lastTime = curTime
		
		if self.depthCounter % self.sectionSize == 0 then
			self:sort()
		end
			
		self.depthCounter = self.depthCounter + 1
			
	end

	function words:newWord(text, font, size)
		local g = display.newGroup()
	
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
			
		end
	
		function g:recycle(penalise)
			if penalise and self.isVisible then
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
					
					t:recycle()
				end
			end	
			return true
		end
		
		return g
	end	

	function words:init()
		self.score = 0
		
		-- Defaults to first-in, furthest-back. Reverse i for opposite:

		local counter = 1
		for i = 1, words.items do
			local r = self:newWord(self.fontName, self.fontName, self.textHeight)
			
			r.counter = counter
			
			if i == 7 then
				self.switchPoint = counter
			end
			
			r.isVisible = false
			
			r.origWidth = r.width
			r.origHeight = r.height
			self.images[#self.images + 1] = r
			counter = counter + words.sectionSize -- placement in pairs array
			
			self:insert(r)	
		end
		
		for i = 1, words.range do
		
			local x = self.r * math.cos(math.rad(i))
			local y = self.r * math.sin(math.rad(i))
			self.points[#self.points + 1] = {x + self.xCentre, y + self.yCentre}
			
		end
		
		for i = 1, self.numChildren do
			self[i]:setRandomColor(#self.colorNames)
		end
		
		self:sort()
		self.visual.isVisible = false
		
		--words:rotate() 
		
	end
	
	function words:cleanup()

		for i = self.numChildren, 1, -1 do
			self[i]:removeSelf()
		end
	
	end		
	
	return words
end