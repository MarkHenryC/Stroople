-- Mark H Carolan
--
-- Stroople project
-- © 2010 Mark H Carolan, Gregory S Hooper

module(..., package.seeall)

require "score"
require "globals"
require "languages"

local correctorBias = 2

function newWord(text, font, size, colorNames)
	local g = display.newGroup()
	
	g.distractorTracker = 0
	g.colorNames = colorNames
	
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

		local rgb = self.colorNames[ci][2]
		self[1].text = self.colorNames[wi][1]
		self[2].text = self.colorNames[wi][1]
		self[2]:setTextColor(rgb[1], rgb[2], rgb[3])
		self.clicked = false
	end
	
	function g:checkNotClicked()
		if not self.clicked then
			if self.colorWordIndex == self.colorDisplayIndex then
				-- A correct item was not clicked
				score.miss(1)
			end
		end	
	end
	
	function g:matching()
		return self.colorWordIndex == self.colorDisplayIndex and true or false
	end
	
	function g:setRandomColor()
		self.distractorTracker = self.distractorTracker + 1
		if self.distractorTracker % globals.distractorProbability == 0 then
			local d, ci = languages.getDistractor()
			local rgb = d[2]
			self[1].text = d[1]
			self[2].text = d[1]
			self[2]:setTextColor(rgb[1], rgb[2], rgb[3])
			
			self.colorWordIndex = 0 -- as long as it doesn't match
			self.colorDisplayIndex = ci
			
			self.clicked = false				
		else
			local colorWordIndex = math.random(1, #self.colorNames)
			local pairing = math.random(1, #self.colorNames * correctorBias)
			if pairing > #self.colorNames then
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
		self:setRandomColor(#self.colorNames)
	end
	
	function g:touch(event)
		if event.phase == "began" then
		
			local t = event.target
			if t.isVisible then
		
				if t:matching() then
					score.add(1)
				else
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
