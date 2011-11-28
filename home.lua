-- Mark H Carolan
--
-- Stroople project
-- © 2010 Mark H Carolan, Gregory S Hooper

module(..., package.seeall)

-- Main is now start screen only
-- where language is selected

require "menu"
require "levels"
require "info"
require "globals"
require "highscores"
require "score"

local background

local memWarning = function(event)
	db.print("Warning Will Robinson!!!")
end

local function clearMenu()
	if mainMenu then mainMenu:removeSelf(); mainMenu = nil end
	background.isVisible = false
end

local function onStart()
	clearMenu()
	levels.startGame()
end

local function onInfo()
	clearMenu()
	info.showInfo()
end

local function onScore()
	clearMenu()
	score.showScoreMenu()
end

local function toggleAudio()
	globals.toggleSound()
	globals.savePrefs()
	score.testSound()
end

local function newToggle(on, off, default, handler) -- true on, false off
	local toggle = display.newGroup()
	local toggleOn = display.newImage(on)
	local toggleOff = display.newImage(off)

	toggle:insert(toggleOn)
	toggle:insert(toggleOff)	

	toggle.state = default
	toggle.handler = handler
	
	function toggle:setState(state)
		if state then
			self[1].isVisible = true
			self[2].isVisible = false
		else
			self[1].isVisible = false
			self[2].isVisible = true
		end	
		db.print("toggle state", state)
		
		self.state = state
	end
	
	function toggle:swapState()
		self.state = not self.state
		self:setState(self.state)
		
	end
	
	function toggle:touch(event)
		if event.phase == "ended" then
			self:swapState()
			self:handler()	
		end
	end
	
	toggle:addEventListener("touch", toggle)
	toggle:setState(default)
	toggle:setReferencePoint(display.CenterReferencePoint)

	return toggle
end

local function showMainMenu()	
	
	if not mainMenu then
		background.isVisible = true
		background.parent:insert(background)

		mainMenu = display.newGroup()

		db.print("audio?", globals.isSoundOn())
		local audioButton = newToggle(
			"speaker.png", "speakerOff.png", 
			globals.isSoundOn(), toggleAudio)
			
		audioButton.x = globals.W4/2
		audioButton.y = globals.H6/2
		mainMenu:insert(audioButton)
		
		local scoreButton = ui.newButton
		{
			default = "highscore.png",
			over = "highscoreH.png",
			onRelease = onScore,
			x = globals.W4 * 3 + globals.W4/2,
			y = globals.H6/2
		}

		mainMenu:insert(scoreButton)
		
		local startButton = ui.newButton
		{
			default = "start.png",
			over = "startH.png",
			onRelease = onStart,
			x = globals.W2,			
		}
		startButton.y = globals.H2 - startButton.height * 1.5
		mainMenu:insert(startButton)

		local infoButton = ui.newButton
		{
			default = "info.png",
--			over = "infoH.png",
			onRelease = onInfo,
			x = globals.W2,			
		}
		infoButton.y = globals.H2
		mainMenu:insert(infoButton)
		
		instructions = menu.createMenu
		{
			items = 
			{
				{ 
					text = languages.colorText(3), 
					foreColor = languages.colorNames[4][2], 
				},				
				{ 
					text = languages.colorText(3), 
					foreColor = languages.colorNames[3][2], 
				},										
			},
			spacing = 0,
			xSpacing = 170,
			x = display.contentWidth/4,
			y = 315,
			width = 100,
			itemHeight = 40,
			textHeight = 30,
			insetX = 0,
			insetY = 0,
		}		
		mainMenu:insert(instructions)
		
		local finger1 = display.newImage("finger.png")
		finger1.x = globals.W4
		finger1.y = globals.H4*3
		mainMenu:insert(finger1)
		
		local cross = display.newImage("cross.png")
		cross.x = globals.W4
		cross.y = globals.H4*3
		mainMenu:insert(cross)
		
		local finger2 = display.newImage("finger.png")
		finger2.x = globals.W4*3
		finger2.y = globals.H4*3
		
		local tick = display.newImage("tick.png")
		tick.x = globals.W4*3
		tick.y = globals.H4*3
	end
end

local onSystem = function(event)
	if event.type == "applicationStart" then
		db.print("applicationStart")			
	elseif event.type == "applicationSuspend" then
		levels.pause()
		db.print("applicationSuspend")
		globals.savePrefs()			
	elseif event.type == "applicationResume" then		
		globals.loadPrefs()
		levels.resume()
	elseif event.type == "applicationExit" then
		globals.savePrefs()
	end
end

--
-- One-time initialisation. These objects are kept in memory
--

function oneTimeInit(fontName, languageID)
	globals.init()				
	globals.loadPrefs()	
	
	highscores.init()
	levels.init(showMainMenu, fontName)
	info.init(showMainMenu)
	score.init(showMainMenu)
	
	globals.setSelectedLanguage(languageID)
	db.print("language", globals.getSelectedLanguage())
	languages.setColorNames()
	
	background = display.newImage("background.png")
	
	Runtime:addEventListener("system", onSystem)
	Runtime:addEventListener("memoryWarning", memWarning)

	math.randomseed(system.getTimer())
	
	showMainMenu()
end

