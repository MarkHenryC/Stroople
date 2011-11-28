-- Mark H Carolan
--
-- Stroople project
-- © 2010 Mark H Carolan, Gregory S Hooper

module(..., package.seeall)

local strokeWidthRegular = 3
local strokeWidthHilite = 10
local none, emboss, dropShadow = 0, 1, 2
local dropShadowDistance = 6

function createMenu(params)
	local menu = display.newGroup()
	
	menu.items = params.items
	menu.isToggle = params.isToggle
	menu.highlight = { 240, 250, 240, 255 }
	menu.mode = none
	
	local yPos = params.y or 0
	local xPos = params.x or display.contentWidth/2
	local spacing = params.spacing or 40 -- y spacing
	local xSpacing = params.xSpacing or 0
	local width = params.width or 100
	local itemHeight = params.itemHeight or 40	
	local textHeight = params.textHeight or 32
	local insetX = params.insetX or 0
	local insetY = params.insetY or 0
	
	function menu:setText(i, t)
		self[i][2].text = t
		self[i][3].text = t
	end
	
	function menu:getText(i)
		return self[i][2].text
	end
	
	function menu:button(item, width, height, textHeight, insetX, insetY, emboss)
		local button = display.newGroup()
		
		if emboss then
			self.mode = emboss
			self.highlight = { 240, 250, 240, 255 }
			
			if not item.backColor then item.backColor = {32, 32, 32} end
			if not item.foreColor then item.foreColor = {0, 0, 0} end
					
			local r = display.newRoundedRect(0, 0, width, height, 5)
			r:setFillColor(item.backColor[1], item.backColor[2], item.backColor[3])
			r.savedFillColor = item.backColor
			r.strokeWidth = strokeWidthRegular
			r:setStrokeColor(item.foreColor[1], item.foreColor[2], item.foreColor[3])
			r.x = insetX
			r.y = insetY
			
			button:insert(r)
			
			-- Fake emboss.
			local t0 = display.newText(item.text, 0, 0, "Verdana-Bold", textHeight)	
			t0.x = -1
			t0.y = -1
			t0:setTextColor(220,220, 220)	
			button:insert(t0) -- index 2	
			
			local t1 = display.newText(item.text, 1, 1, "Verdana-Bold", textHeight)
			t1.x = 0
			t1.y = 0
			t1:setTextColor(item.foreColor[1], item.foreColor[2], item.foreColor[3])
			button:insert(t1) -- index 3			
		
		else -- drop shadow version
		
			self.mode = dropShadow
			self.highlight = { 240, 250, 240, 32 }
			
			if not item.backColor then item.backColor = {0, 0, 0, 0} end
			if not item.foreColor then item.foreColor = {32, 32, 32} end
					
			local r = display.newRoundedRect(0, 0, width, height, 5)
			r:setFillColor(item.backColor[1], item.backColor[2], item.backColor[3], 0)
			r.savedFillColor = item.backColor
			r.strokeWidth = strokeWidthRegular
			r:setStrokeColor(item.foreColor[1], item.foreColor[2], item.foreColor[3], 0)
			r.x = insetX
			r.y = insetY
			r.isVisible = false
			r.isHitTestable = true
			
			button:insert(r) -- [1]
			
			-- drop shadow.
			local t0 = display.newText(item.text, 0, 0, "Verdana-Bold", textHeight)	
			t0.x = dropShadowDistance
			t0.y = dropShadowDistance
			t0:setTextColor(0, 0, 0)	
			button:insert(t0) -- index [2]
			
			local t1 = display.newText(item.text, 1, 1, "Verdana-Bold", textHeight)
			t1.x = 0
			t1.y = 0
			t1:setTextColor(item.foreColor[1], item.foreColor[2], item.foreColor[3])
			button:insert(t1) -- index [3]			
		
		end
				
		button.listener = item.handler -- store for removal
		button.listenerParam = item.handlerParam
		if button.listener then button:addEventListener("touch", button) end
		
		function button:inside(event)
			if event.x < self.	stageBounds.xMin or
				event.x > self.stageBounds.xMax or
				event.y < self.stageBounds.yMin or
				event.y > self.stageBounds.yMax then
				return false
			else
				return true
			end
		end
		
		function button:touch(event)

			if event.phase == "began" then
				display.getCurrentStage():setFocus(self)
				if self.parent.mode == emboss then
					self[1]:setFillColor(self.parent.highlight[1], self.parent.highlight[2], self.parent.highlight[3], self.parent.highlight[4])
				elseif self.parent.mode == dropShadow then
					self[2].x = self[2].x - dropShadowDistance/2
					self[2].y = self[2].y - dropShadowDistance/2			
					self[3].x = self[3].x + dropShadowDistance/2
					self[3].y = self[3].y + dropShadowDistance/2
				end

			elseif event.phase == "ended" then

				if self.parent.mode == emboss then
					self[1]:setFillColor(self[1].savedFillColor[1],
						self[1].savedFillColor[2], self[1].savedFillColor[3], self[1].savedFillColor[4])
				elseif self.parent.mode == dropShadow then	
					self[2].x = self[3].x + dropShadowDistance/2
					self[2].y = self[3].y + dropShadowDistance/2				
					self[3].x = self[3].x - dropShadowDistance/2
					self[3].y = self[3].y - dropShadowDistance/2
				end

				display.getCurrentStage():setFocus(nil)

				if self:inside(event) then				
					self.listener(event, self.listenerParam)
					if self.parent.isToggle then
						if self.parent.savedHilite then
							self.parent[self.parent.savedHilite][1].strokeWidth = strokeWidthRegular
						end
						self[1].strokeWidth = strokeWidthHilite
						self.parent.savedHilite = self.myIndex
					end
				end

			elseif event.phase == "cancelled" then

				if self.parent.mode == emboss then
					self[1]:setFillColor(self[1].savedFillColor[1],
						self[1].savedFillColor[2], self[1].savedFillColor[3], self[1].savedFillColor[4])
				elseif self.parent.mode == dropShadow then	
					self[2].x = self[3].x + dropShadowDistance/2
					self[2].y = self[3].y + dropShadowDistance/2				
					self[3].x = self[3].x - dropShadowDistance/2
					self[3].y = self[3].y - dropShadowDistance/2
				end
				display.getCurrentStage():setFocus(nil)
			end
		end
		
		return button
	end
	
	function menu:cleanup()

		for i = self.numChildren, 1, -1 do	
			local button = self[i]
			if button then
				if button.listener then
					button:removeEventListener("touch", button.listener)
				end
				button:removeSelf()				
			else
				db.print("NULL BUTTON!")
			end
		end
	end
	
	for i = 1, #menu.items do
		local item = menu:button(menu.items[i], width, itemHeight, textHeight, insetX, insetY)
		item.x = xPos
		item.y = yPos
		yPos = yPos + spacing
		xPos = xPos + xSpacing
		item.myIndex = i -- for managing toggle lists; so item knows its index
		if menu.isToggle then
			if  item.myIndex == params.defaultItem then
				item[1].strokeWidth = strokeWidthHilite
				menu.savedHilite = item.myIndex
			end
		end		
		
		menu:insert(item)
	end
	
	return menu
end