-- Mark H Carolan
--
-- Stroople project
-- © 2010 Mark H Carolan, Gregory S Hooper

module(..., package.seeall)

local chars = { 's', 't', 'r', 'o', 'o2', 'p', 'l', 'e' }
local w = display.contentWidth
local h = display.contentHeight
local startTimes = {0,.314,.520,.683,.824,.843,.935,1.098}
--local soundEndLevel = media.newEventSound( "endLevel.aif" )

function newLetters()
	local letters = display.newGroup()
	letters:setReferencePoint(display.TopLeftReferencePoint)
	
	for i = 1, #chars do
		local img = display.newImage(chars[i] .. ".png")
		img:setReferencePoint(display.TopLeftReferencePoint)
		img.id = i
		
		letters:insert(img)
	end
	
	function letters:onComplete(event)

	end
	
	function letters:onStart(event)

	end
	
	function letters:addText(t, y)
		self.text = display.newText(t, 0, 0, nil, 24)
		self.text.y = y or 80
		self.text.x = display.contentWidth/2
		self.text:setTextColor(200, 200, 200)
	end
	
	function letters:drop(dropTo, up, time)
		if up then
			transition.from(self, { time = 300, y = h })
		end
		
		for i = 1, self.numChildren do
			transition.to(self[i], 
			{ 
				time=time, 
				y = dropTo,
				x = self[i].x, 
				onStart = self,
				delay = startTimes[i] * 1000,
				transition = easing.inOutExpo,
				onComplete = self,
			})
		end	
		if globals.isSoundOn() then
			media.playSound("endLevel.aif")
		end
	end

	return letters
end
	