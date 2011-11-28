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

function createWords(params)
	local words = display.newGroup()
	words.wordCount = params.wordCount or 3
	words.colorNames = params.colorNames		
	words.fontName = params.fontName
	words.textHeight = params.textHeight or 32
	words.textSpacing = params.textSpacing or params.textHeight * 3
	words.direction = params.direction or 1
	words.topBorder = params.topBorder or 0
	words.baseBorder = params.baseBorder or globals.H
	words.xMax = params.xMax or globals.W *3
	words.xMin = params.xMin or -globals.W
	
	function words:scroll(offset)
		
		self.x = self.x + words.direction * offset
		if words.direction < 0 then
			if self.x <= self.xMin then
				self.x = self.xMax
				self:recycle()
			end
		elseif words.direction > 0 then
			if self.x >= self.xMax then
				self.x = self.xMin
				self:recycle()
			end
		end
			
	end
	
	function words:recycle()
		for i = 1, self.numChildren do
			self[i]:recycle()
		end
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
			
			if distractorTracker % globals.rotatorProbability == 0 then
				self:setData(math.random(1, #words.colorNames), math.random(1, #words.colorNames))
				self.rotation = 180			
			elseif distractorTracker % globals.distractorProbability == 0 then
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
	
		function g:recycle()
			
			self:checkNotClicked()
			
			self.clicked = false
			self.isVisible = true
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
		end
		
		return g
	end	
	
	function words:init()
		self.score = 0
		
		-- Initialise
		for i = 1, self.wordCount do
			local y = self. topBorder + (i - 1) * (self.textHeight + self.textSpacing)

			local t = self:newWord(
				self.fontName, self.fontName, self.textHeight)

			t.x = 0
			t.y = y
			
			self:insert(t)
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
	words.isVisible = false	
	return words
end
