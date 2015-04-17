-- extract here the namespace in which we will look for colors
local Color = Polyghtgons.Classes.Logic.Components.Polyghtgon;

--[[
We store in this matrix which is the subtraction relationship
between colors.
There's an entry for each color, so any color can receive subtractions. A missing entry in their subtables means they have no relationship, so base color won't be affected.
A color substracted to itself is NONE.
]]
local ColorSubtractionMatrix = {
	[Color.NONE] = {
		-- can't substract anything
	},
	[Color.RED] = {
		[Color.RED] = Color.NONE
	},
	[Color.GREEN] = {
		[Color.GREEN] = Color.NONE
	},
	[Color.BLUE] = {
		[Color.BLUE] = Color.NONE
	},
	[Color.CYAN] = {
		[Color.GREEN] = Color.BLUE,
		[Color.BLUE] = Color.GREEN,
		[Color.CYAN] = Color.NONE
	},
	[Color.MAGENTA] = {
		[Color.RED] = Color.BLUE,
		[Color.BLUE] = Color.RED,
		[Color.MAGENTA] = Color.NONE
	},
	[Color.YELLOW] = {
		[Color.RED] = Color.GREEN,
		[Color.GREEN] = Color.RED,
		[Color.YELLOW] = Color.NONE
	},
	[Color.WHITE] = {
		[Color.RED] = Color.CYAN,
		[Color.GREEN] = Color.MAGENTA,
		[Color.BLUE] = Color.YELLOW,
		[Color.CYAN] = Color.RED,
		[Color.MAGENTA] = Color.GREEN,
		[Color.YELLOW] = Color.BLUE,
		[Color.WHITE] = Color.NONE
	}
};

return {
	name = "subtractColors",
	value = function(base, colorToSubstract)
		if ColorSubtractionMatrix[base][colorToSubstract] then
			return ColorSubtractionMatrix[base][colorToSubstract];
		end

		return base;
	end
};