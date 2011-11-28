-- Mark H Carolan
--
-- Stroople project
-- © 2010 Mark H Carolan, Gregory S Hooper

module(..., package.seeall)

require "words"
require "wordsHoriz"
require "menu"
require "score"
require "letters"
require "languages"
require "db"
require "spiral"
require "carousel"

--
-- Constants
--

local textHeight = 40
local textSpacing = textHeight * 1.5
local textSpacingH = textHeight * 2
local startScrollSpeed = .5 --  0.1
local sectionLength = 3000
local topBorder = 40
local baseBorder = globals.H
local guagePosX = 90  -- (96 for my orig panel)
local guagePosMaxAddX = 40
local guagePosY =6
local deadScore = 0 -- make lower for debugging
local startLevel = 1 -- change for debugging
local gameTime = 120000
local extraTime = 30000
local levelComplete = false
local outgoingLevel, incomingLevel
local transitionTime = 1000 -- between levels
local normalLevels = 4 -- before master level
local masterLevel = 80
local maxMisses = 2

--
-- Tracking variables; reset each level play
--

local scrollSpeed
local scrollFunction

--
-- Created and destroyed each run thru the game
-- 
-- 

local levelMenu, mainMenu
local words1, wordsL, wordsR, wordsU, wordsD
local wordsH1, wordsH2, wordsH3, wordsH4, wordsCarousel, wordsSpiral
local endLevelLogo

--
-- Only needs to be created once
-- 
 
local scoreboard
local speedController
local blacking -- black backing for health display guage
local background

--
-- Set from main via init() only once
--

local fontName
local returnFunction

--
-- filled by entry dialog for high score
--

local nameField, hsRank, hsTime, hsScore
local nameIX = 1 -- create name in sim

local clearLevel, setLevel
local variableGameTime

local isAndroid = "Android" == system.getInfo("platformName")
local inputFontSize = 24
if isAndroid then
	inputFontSize = 18
end


local function getSpeedController(levels)
	local speedController = {}
	
	-- Delay times for increasing speed:	
	speedController.timeTable = {10000, 10000, 10000, 10000, 10000, 10000, 
												10000, 10000, 10000, 10000, 10000, 10000}
	-- Activate this one for quick testing
--	speedController.timeTable = {2000, 2000, 2000, 2000, 2000, 2000, 2000,
--												2000, 2000, 2000, 2000, 2000, 2000, 2000} -- test only
	
	-- Speed notch settings:
	speedController.speedTable = {0.10, 0.11, 0.12, 0.13, .14, .15, 
												.16, .17, .18, .19, .20, .21, .22}
	
	-- Level switches		
	
	local addLevelTime = 20000
--	for i = 1, #speedController.timeTable do
--		addLevelTime = addLevelTime + speedController.timeTable[i]
--	end
	
	speedController.levelTime = addLevelTime
	speedController.masterLevelTime = 40000
	
	speedController.levelCount = levels		
	
	speedController.stIndex = 1
	speedController.ttIndex = 1
	
	speedController.startTime = 0
	speedController.levelStartTime = 0	 

	speedController.speed = 0
	speedController.totalTime = 0
	
	function speedController:start(startT, curLevel)
		self.startLevel = curLevel
		
		if curLevel > self.levelCount then curLevel = self.levelCount end	

		if self.currentLevel == self.levelCount then
			self.hitLevelLimit = true
		else
			self.hitLevelLimit = false
		end
		
		self.currentLevel = curLevel
		self.stIndex, self.ttIndex = 1, 1
		self.totalTime = 0
		self.startTime = startT
		self.hitSpeedLimit = false
		self.speed = self.speedTable[self.stIndex]
		self.levelStartTime = startT
		setLevel(self.currentLevel)
	end

	function speedController:getSpeed(elapsed)		
		
		if not self.hitSpeedLimit then
			
			
			local curTimeOut = self.timeTable[self.ttIndex]
			local curSpeed = self.speedTable[self.stIndex]
			
			-- Commented out for testing constant speed
			
--			if (elapsed - self.startTime) >= curTimeOut then
--				
--				self.startTime = elapsed
--				self.ttIndex = self.ttIndex + 1
--				if self.ttIndex >= #self.timeTable then
--					self.hitSpeedLimit = true
--					self.speed = self.speedTable[#self.speedTable] -- last element
--				else
--					self.stIndex = self.stIndex + 1
--					if self.stIndex >= #self.speedTable then
--						self.hitSpeedLimit = true -- speed already set in previous iteration
--					else
--						self.speed = self.speedTable[self.stIndex]
--					end
--				end
--			end
		end
		
		if not self.hitLevelLimit then			
			
			if elapsed - self.levelStartTime >= self.levelTime then
				self.levelStartTime = elapsed
				
--				This is only if we are resetting speed at each level step-up				
--				self.startTime = elapsed
--				self.hitSpeedLimit = false
--				self.ttIndex = 1
--				self.stIndex = 1
				
				clearLevel(self.currentLevel)
				self.currentLevel = self.currentLevel + 1
				
				-- level 4 is double time
				if self.currentLevel == 4 then
					self.levelTime = self.levelTime * 2
				end
				
				if self.currentLevel >= self.levelCount then					
					self.hitLevelLimit = true
					self.currentLevel = self.levelCount					
					db.print("final level", self.currentLevel)
				else
					db.print("Next level", self.currentLevel)										
				end
				
--				self.speed = self.speedTable[self.stIndex]
			
				if self.currentLevel == self.startLevel then
					setLevel(self.currentLevel)
				end
				
			end	
		else -- must be master level
			if elapsed - self.levelStartTime >= self.masterLevelTime then
				db.print("calling clearLevel", self.currentLevel)
				self.levelStartTime = elapsed
				clearLevel(self.currentLevel)
			end
		end -- not hitLevelLimit
		
		return self.speed, self.currentLevel
		
	end
	
	function speedController:endLevel()
		clearLevel(self.currentLevel)
	end
	
	function speedController:startLevel()
		setLevel(self.currentLevel)
	end
	
	return speedController
end

-- Not a pretty visual. For testing.
local function plainTextDisplay(c, f, h)
	local rgb = c or {0, 0, 0}
	local box = display.newText("0", 0, 0, f, h)
	box:setTextColor(rgb[1], rgb[2], rgb[3])		
	return box
end

local function createScoreboard()
	local sb = display.newGroup()
	sb:setReferencePoint(display.TopLeftReferencePoint)
	sb.y = 0 -- globals.H
	
	local pole = display.newRect(0, 0, 50, 30)
	pole:setReferencePoint(display.TopLeftReferencePoint)
	pole:setFillColor(255, 0, 0)
	pole.y = guagePosY
	pole.x = guagePosX
	sb:insert(pole, false)				-- index 1
	sb.guage = pole
	
	-- Now using bitmap
	--local scoreBacking = display.newRect(0, 	0,  globals.W, 40)
	--scoreBacking:setFillColor(0, 0, 0)
	
	local scoreBacking = display.newImage("scoring_bar_3.png")
	scoreBacking:setReferencePoint(display.TopLeftReferencePoint)
	
	sb:insert(scoreBacking) 	-- index 2
	scoreBacking.x = 0
	scoreBacking.y = 0
	
	local scoreBox = plainTextDisplay({200, 200, 200}, native.systemFont, 24)	
	sb:insert(scoreBox)		-- index 3
	scoreBox.x = 90
	scoreBox.y = 20
	sb.scoreBoxIndex = 3
	
	local timeBox = plainTextDisplay({200, 200, 200}, native.systemFont, 24)
	sb:insert(timeBox)			-- index 4
	timeBox.x = 240
	timeBox.y = 20
	sb.timeBoxIndex = 4
	
	local miss = display.newCircle(0, 0, 5)
	miss:setFillColor(255, 0, 0)
	miss.strokewidth = 2
	miss:setStrokeColor(100, 100, 100)
	sb:insert(miss)				-- index 5
	miss.x = 40
	miss.y = 22
	sb.missIndex = 5
	
	local hit = display.newCircle(0, 0, 5)
	hit:setFillColor(0, 255, 0)
	hit.strokewidth = 2
	hit:setStrokeColor(100, 100, 100)
	sb:insert(hit)					-- index 6
	hit.x = globals.W - 40
	hit.y = 22		
	sb.hitIndex = 6			
					
	function sb:score(n)
		self[self.scoreBoxIndex].text = n		
		if n > guagePosMaxAddX then n = guagePosMaxAddX end
		pole.x = guagePosX + n
	end

	function sb:time(n)
		local s = string.format("%.1f", n / 1000)
		self[self.timeBoxIndex].text = s
	end
	
	return sb
end

local function lightController(object, max)
	local on = false
	local counter = 0
	object.isVisible = false
	return function(trigger)
		if trigger then
			object.isVisible = true
			on = true
		elseif on then
			counter = counter + 1
			if counter >= max then
				on = false
				counter = 0
				object.isVisible = false
			end
		end
	end
end

local function createWords()
	words1 = words.createWords
	{
		fontName = fontName,
		textHeight = textHeight,
		textSpacing = textSpacing,
		colorNames = languages.colorNames,	
		topBorder = topBorder,
		baseBorder = baseBorder,
		direction = 1
	}	
	words1.x = globals.W2
end

local function createWordsLR()
	wordsL = words.createWords
	{
		fontName = fontName,
		textHeight = textHeight,
		textSpacing = textSpacing,
		colorNames = languages.colorNames,		
		topBorder = topBorder,
		baseBorder = baseBorder,
		direction = 1
	}
	
	wordsL.x = globals.W4
	
	wordsR = words.createWords
	{
		fontName = fontName,
		textHeight = textHeight,
		textSpacing = textSpacing,
		colorNames = languages.colorNames,
		topBorder = topBorder,
		baseBorder = baseBorder,
		direction = 1
	}
	
	wordsR.x = 3 * globals.W4
end

local function createWordsUD()
	wordsD = words.createWords
	{
		fontName = fontName,
		textHeight = textHeight,
		textSpacing = textSpacing,
		colorNames = languages.colorNames,
		topBorder = topBorder,
		baseBorder = baseBorder,
		direction = 1
	}
	
	wordsD.x = globals.W4
	
	wordsU = words.createWords
	{
		fontName = fontName,
		textHeight = textHeight,
		textSpacing = textSpacing,
		colorNames = languages.colorNames,
		topBorder = topBorder,
		baseBorder = baseBorder,
		direction = -1
	}
	
	wordsU.x = 3 * globals.W4
end



local function createWordsH()
	local leftX = -globals.W
	local rightX = globals.W*2
	
	wordsH1 = wordsHoriz.createWords
	{
		fontName = fontName,
		textHeight = textHeight,
		textSpacing = textSpacingH,
		colorNames = languages.colorNames,
		xMin = leftX,
		xMax = globals.W + globals.W4,
		topBorder = topBorder,
		baseBorder = baseBorder,
		direction = 1
	}
	
	wordsH1.x = -globals.W
	wordsH1.y = textHeight + textHeight/2
	
	wordsH2 = wordsHoriz.createWords
	{
		fontName = fontName,
		textHeight = textHeight,
		textSpacing = textSpacingH,
		colorNames = languages.colorNames,
		xMin = leftX,
		xMax = globals.W + globals.W4,	
		topBorder = topBorder,
		baseBorder = baseBorder,
		direction = 1
	}
	
	wordsH2.x = 0
	wordsH2.y = textHeight + textHeight/2	
	
	wordsH3 = wordsHoriz.createWords
	{
		fontName = fontName,
		textHeight = textHeight,
		textSpacing = textSpacingH,
		colorNames = languages.colorNames,
		xMin = -globals.W4,
		xMax = rightX,	
		topBorder = topBorder,
		baseBorder = baseBorder,
		direction = -1
	}

	wordsH3.x = globals.W
	wordsH3.y = textHeight + textHeight * 2
	
	wordsH4 = wordsHoriz.createWords
	{
		fontName = fontName,
		textHeight = textHeight,
		textSpacing = textSpacingH,
		colorNames = languages.colorNames,
		xMin = -globals.W4,
		xMax = rightX,	
		topBorder = topBorder,
		baseBorder = baseBorder,
		direction = -1
	}
	
	wordsH4.x = globals.W*2
	wordsH4.y = textHeight + textHeight * 2
	
end

local function createWordsSpiral()
	wordsSpiral = spiral.createWords
	{
		fontName = fontName,
		textHeight = textHeight,
		colorNames = languages.colorNames,	
	}	
end

local function createWordsCarousel()
	wordsCarousel = carousel.createWords
	{
		fontName = fontName,
		textHeight = textHeight,
		colorNames = languages.colorNames,	
	}	
end

local function removeMenuButtons()
	if levelMenu then levelMenu:cleanup(); levelMenu = nil end
	if mainMenu then mainMenu:cleanup(); mainMenu = nil end
end

local function onMainMenu()
	if endLevelLogo then
		endLevelLogo:removeSelf()
		endLevelLogo = nil
	end
	removeMenuButtons()	
	returnFunction()
end

local function showScores()	
	if endLevelLogo then
		endLevelLogo:removeSelf()
		endLevelLogo = nil
	end
		
	score.showScoreMenu(hsScore)
end

local function showLevelMenu()	
	if endLevelLogo then
		endLevelLogo:removeSelf()
		endLevelLogo = nil
	end
	
	background.parent:insert(background)	
	
	if not mainMenu then
		mainMenu = menu.createMenu
		{
			items =
			{ 
				{ 
					text = languages.menuText(), handler = onMainMenu,
					foreColor = { 200, 200, 200 }, backColor = { 0, 0, 0 },
				}
			},
			spacing = 80,
			x = globals.W2,
			y = 460,
			itemHeight = 30,
			textHeight = 25,			
		}
	else
		mainMenu.parent:insert(mainMenu)
	end
end

local function textListener(event)
	if event.phase == "submitted" then

		if globals.getIsSimulator() then
			highscores.submitName(hsScore, "person" .. nameIX)
			nameIX = nameIX + 1
		else
			globals.setCurrentPlayer(nameField.text) -- may be blank
			if nameField.text and string.len(nameField.text) > 0 then				
				local txt = nameField.text -- make sure no colons as they're delimiters
				highscores.submitName(hsScore, nameField.text)
			end		
			native.setKeyboardFocus(nil)
			nameField:removeSelf()
			nameField = nil		
		end
		
		showScores()
		
	elseif event.phase == "ended" then
		native.setKeyboardFocus(nil)
		nameField:removeSelf()
		nameField = nil
		
		showScores()	
	end
	
end

local function addPlayer()	
	if endLevelLogo then
		endLevelLogo:removeSelf()
		endLevelLogo = nil
	end	

	if globals.getIsSimulator() then
		textListener{phase = "submitted"}
	else	
		nameField = native.newTextField( 20, 180, globals.W-40, 30, textListener )
		nameField.font = native.newFont( native.systemFontBold, inputFontSize )	
		nameField.text = globals.getCurrentPlayer()
		native.setKeyboardFocus(nameField)	
	end
	
end

local function endLevel()	
	
	hsScore = score.getScore()
	db.print("score", hsScore)
	
	local isTop, isIn, txt, rank, time = score.endLevel(hsScore)		
	db.print("isTop, isIn, txt, rank, time:", isTop, isIn, txt, rank, time)		
	
	score.setScore(0)		
	
	if words1 then words1:cleanup(); words1 = nil end
	if wordsL then wordsL:cleanup(); wordsL = nil end
	if wordsR then wordsR:cleanup(); wordsR = nil end
	if wordsH1 then wordsH1:cleanup(); wordsH1 = nil end
	if wordsH2 then wordsH2:cleanup(); wordsH2 = nil end
	if wordsH3 then wordsH3:cleanup(); wordsH3 = nil end
	if wordsH4 then wordsH4:cleanup()	; wordsH4 = nil end
	if wordsCarousel then wordsCarousel:cleanup(); wordsCarousel = nil end
	if wordsSpiral then wordsSpiral:cleanup(); wordsSpiral = nil end

	if speedController then speedController = nil end
	
	endLevelLogo = letters.newLetters()
	if isTop then endLevelLogo:addText(txt or "New High Score!")
	elseif isIn then endLevelLogo:addText(txt or "Made it to top 10!") 
	else endLevelLogo:addText(txt or "Bad luck") end
	
	endLevelLogo:drop(globals.H, false, 300)	
	
	hsRank = rank
	hsTime = time
	
	if isIn then
		endLevelLogo:addText("Achieved ranking of " .. rank, 110)	
		endLevelLogo:addText("Enter your name", 140)		
		timer.performWithDelay(3000, addPlayer)
	else
		timer.performWithDelay(3000, showScores)
	end
	
end

local function scrollRow(displacement)
	words1:scroll(displacement)
end

local function scrollRowLR(displacement)
	wordsL:scroll(displacement)
	wordsR:scroll(displacement)
end

local function scrollRowUD(displacement)
	wordsU:scroll(displacement)
	wordsD:scroll(displacement)
end

local function scrollRowH(displacement)
	wordsH1:scroll(displacement)
	wordsH2:scroll(displacement)
	wordsH3:scroll(displacement)
	wordsH4:scroll(displacement)
end

local function scrollRowCarousel(displacement)
	wordsCarousel:scroll(displacement)
end

local function scrollRowSpiral(displacement)
	wordsSpiral:scroll(displacement)
end

local scrollFunc = { scrollRow, scrollRowLR, scrollRowUD, scrollRowH, scrollRowCarousel, scrollRowSpiral, }

local function enterFrame(event)

	local elapsed = score.elapsedSinceLastFrame()
	local levelTime = score.getCurLevelTime()

	scoreboard:time(levelTime)
	scoreboard:score(score.getScore())
	
	scrollSpeed, level = speedController:getSpeed(levelTime)
	
--	if levelTime >= variableGameTime then
--		db.print("levelTime >= variableGameTime")
--		if level == normalLevels and score.getScore() >= masterLevel then
--			db.print("level == normalLevels and score.getScore() >= masterLevel")
--			variableGameTime = gameTime + extraTime
--		else
--			-- game over
--			Runtime:removeEventListener("enterFrame", enterFrame)
--			speedController:endLevel()						
--		end	
--	else
--		scrollSpeed, level = speedController:getSpeed(levelTime)
	
		scrollFunc[level](scrollSpeed * elapsed)
			
		if score.getScore() < deadScore then
			Runtime:removeEventListener("enterFrame", enterFrame)
			return endLevel()
		end
		
		score.frame()
--	end
end

function startGame()
	scrollSpeed = startScrollSpeed
	
	background.parent:insert(background)

	createWords()
	words1:init()
	
	createWordsLR()
	wordsL:init()
	wordsR:init()
	
	createWordsUD()
	wordsU:init()
	wordsD:init()
	
	createWordsH()
	wordsH1:init()
	wordsH2:init()
	wordsH3:init()
	wordsH4:init()
	
	createWordsCarousel()
	wordsCarousel:init()
	
	createWordsSpiral()
	wordsSpiral:init()
	
	variableGameTime = gameTime
	
	score.startLevel(startLevel)
	
	speedController = getSpeedController(#scrollFunc)
	speedController:start(score.getCurLevelTime(), startLevel)
	levelComplete = false;
	
	-- make sure cover is over all other graphics
	
	blacking.parent:insert(blacking)
	scoreboard.parent:insert(scoreboard)
	
	Runtime:addEventListener("enterFrame", enterFrame)			

end


--
-- These functions accessible from outside:
--

function pause()
	score.pause()
	db.print("paused")
end

function resume()
	db.print("resumed")
	score.resume()
end

function init(returnFunc, font)
	returnFunction = returnFunc
	fontName = font
	
	background = display.newImage("background.png")
	
	blacking = display.newRect(0, 0, globals.W, topBorder * 2 + 8)
	blacking:setReferencePoint(display.TopLeftReferencePoint)
	blacking.x = 0
	blacking.y = -(topBorder+8)
	blacking:setFillColor(40, 40, 40)
	
	-- All this stuff only done once.
	scoreboard = createScoreboard()
	
	score.lightMiss = lightController(scoreboard[scoreboard.missIndex], 10)
	score.lightHit  = lightController(scoreboard[scoreboard.hitIndex], 10)		
			
end

function cleanup()
	removeMenuButtons()
	scoreboard:removeSelf()
	blacking:removeSelf()
	background:removeSelf()
end

--
-- Move locals
--

local function endLevel1Out()
	words1.isVisible = false

	Runtime:addEventListener("enterFrame", enterFrame)
	setLevel(2)
	
	resume()
	
end

local function level1Out(ob)	
	transition.to(words1, 
	{ 
		time = transitionTime,
		y = -globals.H, 
		transition = easing.outExpo,
		onComplete = endLevel1Out,
	})
end

local function endLevel2Out()
	wordsL.isVisible = false
	wordsR.isVisible = false
	
	Runtime:addEventListener("enterFrame", enterFrame)	
	setLevel(3)
	
	resume()
	
end

local function level2Out(ob)
	transition.to(wordsL, 
	{ 
		time = transitionTime,
		x = -globals.W, 
		transition = easing.outExpo,
		onComplete = endLevel2Out,
	})
	transition.to(wordsR, 
	{ 
		time = transitionTime,
		x = globals.W * 1.5, 
		transition = easing.outExpo,
	})
	
end

local function endLevel3Out()
	wordsD.isVisible = false
	wordsU.isVisible = false

	Runtime:addEventListener("enterFrame", enterFrame)	
	setLevel(4)
	
	resume()
	
end

local function level3Out(ob)
	transition.to(wordsD, 
	{ 
		time = transitionTime,
		x = -globals.W, 
		transition = easing.outExpo,
		onComplete = endLevel3Out,
	})
	transition.to(wordsU, 
	{ 
		time = transitionTime,
		x = globals.W * 1.5, 
		transition = easing.outExpo,
	})	
end

local function endLevel4Out()
	wordsH1.isVisible = false
	wordsH2.isVisible = false
	wordsH3.isVisible = false
	wordsH4.isVisible = false		
	
	local hits, misses = score.getHitsAndMisses()
	
	if misses <= maxMisses then
		setLevel(5)
		Runtime:addEventListener("enterFrame", enterFrame)
		resume()
	else
		Runtime:removeEventListener("enterFrame", enterFrame)
		return endLevel()
	end
	
end

local function level4Out(ob)
	transition.to(wordsH1, 
	{ 
		time = transitionTime,
		x = -globals.W, 
		transition = easing.outExpo,
		onComplete = endLevel4Out,
	})
	transition.to(wordsH2, 
	{ 
		time = transitionTime,
		x = -globals.W, 
		transition = easing.outExpo,
	})
	transition.to(wordsH3, 
	{ 
		time = transitionTime,
		x = globals.W * 1.5, 
		transition = easing.outExpo,
	})
	transition.to(wordsH4, 
	{ 
		time = transitionTime,
		x = globals.W * 1.5, 
		transition = easing.outExpo,
	})
	
end

local function endLevel5Out()
	wordsCarousel.visual.isVisible = false

	Runtime:addEventListener("enterFrame", enterFrame)	
	setLevel(6)
	
	resume()
	
end

local function level5Out(ob)	
	transition.to(wordsCarousel.visual, 
	{ 
		time = transitionTime,
		y = globals.H + globals.H4, 
		transition = easing.outExpo,
		onComplete = endLevel5Out,
	})
end

local function endLevel6Out()
	wordsSpiral.isVisible = false

	Runtime:removeEventListener("enterFrame", enterFrame)
	
	return endLevel()
	
end

local function level6Out(ob)	
	transition.to(wordsSpiral, 
	{ 
		time = transitionTime,
		y = globals.H + globals.H4, 
		transition = easing.outExpo,
		onComplete = endLevel6Out,
	})
end

--
-- pre-declared
--

function clearLevel(n)
	-- suspend animations

	pause()
	Runtime:removeEventListener("enterFrame", enterFrame)
	
	if n == 1 then
		level1Out()
	elseif n == 2 then
		level2Out()
	elseif n == 3 then
		level3Out()
	elseif n == 4 then
		level4Out()
	elseif n == 5 then
		level5Out()	
	elseif n == 6 then
		level6Out()
	end
end

function setLevel(n)
	if n == 1 then
		words1.isVisible = true	
	elseif n == 2 then
		wordsL.isVisible = true
		wordsR.isVisible = true
	elseif n == 3 then
		wordsU.isVisible = true
		wordsD.isVisible = true
	elseif n == 4 then
		wordsH1.isVisible = true
		wordsH2.isVisible = true
		wordsH3.isVisible = true
		wordsH4.isVisible = true
	elseif n == 5 then
		wordsCarousel.visual.isVisible = true		
	elseif n == 6 then
		wordsSpiral.isVisible = true
	end
end