-- depends on BaseEntity
if not BaseEntity then return end
class 'PuzzleElement' (BaseEntity)

-- status for puzzles
local PuzzleStatus = {
	INITIAL = 0,
	ACTIVATED = 1,
	ACTIVATING = 2,
	MOANING = 3
};
-- we keep a reference in our class so we can use it in child classes
PuzzleElement.PuzzleStatus = PuzzleStatus;

-- when adding colors, we may've been light up with the correct sequence of colors or not, and thus have these states
local ColorStates = {
	CORRECT = 0,
	IN_PROGRESS = 1,
	INCORRECT = 2
};

-- extract here the namespace in which we will look for colors
local Color = Polyghtgons.Classes.Logic.Components.Polyghtgon;

-- helper function to parse a color from a string to the enum
local parseColor = function(colorName)
	if colorName then
		colorName = colorName:upper();
	end

	assert(Color[colorName], "Non-existent color '" .. colorName .. "'");
	return Color[colorName];
end

-- PuzzleElement constructor
function PuzzleElement:__init(attributes, component)
	Polyghtgons.Classes.Scripting.BaseEntity.__init(self, attributes, component);

	-- initial data
	self.status = PuzzleStatus.INITIAL;
	self.color = parseColor(attributes.color);
	self.currentLightUpColor = Color.NONE;

	-- reactions when being light up
	self.lightReactions = {
		[ColorStates.CORRECT] = self.activatePuzzle,
		[ColorStates.INCORRECT] = self.moan,
		[ColorStates.IN_PROGRESS] = nil
	};
end

-- whenever we're light up or a light is turned off, we will compute what's
-- our current light up color (it may be NONE). Then, we will check if
-- it's our target color (and return CORRECT), a component of it (and return
-- IN_PROGRESS) or doesn't have any relationship (INCORRECT).
-- we're invoking this function passing which is the function to mix colors
function PuzzleElement:mixColors(current, color, mixFunction)
	self.currentLightUpColor = mixFunction(current, color);

	-- there may not be a color at all
	if self.currentLightUpColor == Color.NONE then
		return
	end

	-- is it our target color
	if self.currentLightUpColor == self.color then
		return ColorStates.CORRECT;
	end

	-- is it a component of our target color?
	if Polyghtgons.Functions.isComponent(self.currentLightUpColor, self.color) then
		return ColorStates.IN_PROGRESS;
	end

	return ColorStates.INCORRECT;
end

-- check the result of adding a color, using helper mixColors() method
function PuzzleElement:addColor(color)
	return self:mixColors(self.currentLightUpColor, color, Polyghtgons.Functions.addColors);
end

-- check the result of removing a color, using helper mixColors() method
function PuzzleElement:removeColor(color)
	return self:mixColors(self.currentLightUpColor, color, Polyghtgons.Functions.subtractColors);
end

function PuzzleElement:reactOnLightInteraction(interactionFunction, color)
	-- when we're light up, we react depending on our status
	if self.status ~= PuzzleStatus.ACTIVATED and self.status ~= PuzzleStatus.ACTIVATING then
		local result = interactionFunction(self, color);
		-- execute its reaction, if any
		if self.lightReactions[result] then
			self.lightReactions[result](self);
		end
	end
end

-- when light up, we receive this message from C++
function PuzzleElement:onLightUp(message)
	self:reactOnLightInteraction(self.addColor, message.color);
end

-- when turned off, we can clean up some data
function PuzzleElement:onTurnOff(message)
	self:reactOnLightInteraction(self.removeColor, message.color);
end

function PuzzleElement:activatePuzzle()
	-- called when the puzzle is light up with the correct color,
	-- to be implemented by children
end

function PuzzleElement:moan()
	-- called when the puzzle is light up with the wrong color,
	-- to be implemented by children
end

return {
	name = "PuzzleElement",
	value = PuzzleElement
};