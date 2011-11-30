-- Mark H Carolan
--
-- Stroople project
-- © 2010 Mark H Carolan, Gregory S Hooper

-- Main is now start screen only
-- where language is selected

require "home"
require "ui"
require "globals"
require "db"

local background
local fontName
local lingoMenu
local lingoImages

if globals.usingOpenFeint then
	require "openfeint"
end

display.setStatusBar(display.HiddenStatusBar)

if globals.usingOpenFeint then
	-- client application ID: 182752
	if system.getInfo("environment") ~= "simulator" then
		openfeint.init( 
			"HbDUX6wwAFqFo4DRodoZLA", 
			"tRIneQGwfvk00Rn16X734egjus5YCPV6FLF6s3vQ", 
			"BlueIsRed" )
	end
end

local shortFontNameLookup =
{
	"FuturaBT-ExtraBlack", -- bundled font
	"FuturaXBlk BT", -- new addbreviation (from whence it came???)
	"verdana-bold" -- to be compatible with older iPods

}

local function match(str)
	--local s = string.lower(str)
	local sLen = string.len(str)
	
	for i = 1, #shortFontNameLookup do		

		local start, length = string.find(str, shortFontNameLookup[i], 1, true)
		if  start and length == sLen  then
			db.print("Found " .. str)
			return true
		end
	end
	return false
end

local function clickedLanguage(event)
	if event.phase == "ended" then
		lingoImages:removeSelf()
		
		math.randomseed(system.getTimer())
		
		home.oneTimeInit(fontName, event.target.id)
	end
end

--
-- startup: find font and wait for language choice
--

local function startup()
	globals.init()
	
	local imagePos = 
	{ 
		{ x = globals.W2,  y = globals.H24*4}, 
		{ x = globals.W2, y = 160}, 
		{ x = globals.W2, y = 240}, 
		{ x = globals.W2, y = 320} 
	}	

	background = display.newImage("background.png")
	
	local all_fonts = native.getFontNames()
	for i = 1, #all_fonts do	
		if match(all_fonts[i]) then
			fontName = all_fonts[i]
			break
		end
	end				

	lingoImages = display.newGroup()
	
	local img = display.newImage("entryLogo.png")
	
	lingoImages:insert(img)
	img.y = globals.H24*3
	img.x = globals.W2
	db.print(globals.W2, globals, W)
	for i = 1, #globals.languageNames do
		local button = ui.newButton
		{
			default = globals.languageNames[i] .. ".png",
			over = globals.languageNames[i] .. "H.png",
			onRelease = clickedLanguage
		}
		lingoImages:insert(button)
		button.x, button.y = globals.W2, 
			globals.H24*2 + img.stageBounds.yMax + (button.height) * (i-1)	
		button.id = i
	end
	
end

startup()