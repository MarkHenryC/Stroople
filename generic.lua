-- Mark H Carolan
--
-- Stroople project
-- © 2010 Mark H Carolan, Gregory S Hooper

module(..., package.seeall)

require "globals"
require "word"

function newWordGroup(params)
	local wordGroup = display.newGroup()
		
	if not params.colorNames then
		error("Must supply colorName table")
	end
	wordGroup.colorNames = params.colorNames	
	wordGroup.fontName = params.fontName
	wordGroup.textHeight = params.textHeight or 32
	wordGroup.wordCount = params.wordCount or 4
	
	function wordGroup:init()
		
		for i = 1, self.wordCount do
			local r = word.newWord(self.fontName, self.fontName, self.textHeight, self.colorNames)
			r.isVisible = false
			self:insert(r)	
		end
		
		for i = 1, self.numChildren do
			self[i]:setRandomColor(#self.colorNames)
		end
	end
	
	function wordGroup:cleanup()

		for i = self.numChildren, 1, -1 do
			self[i]:removeSelf()
		end
	
	end
		
	return wordGroup
end