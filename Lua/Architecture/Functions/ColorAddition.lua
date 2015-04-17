-- extract here the namespace in which we will look for colors
local Color = Polyghtgons.Classes.Logic.Components.Polyghtgon;

--[[
We store here how colors are mixed.
A missing entry means there's no correct mix between those colors
although there won't be more than one Polyghtgon of a given color
at the same time, we understand that a color added to itself is the
same color. Useful if we test with more than one Polyghtgon of the
same color.
]]
local ColorMixMatrix = {
	[Color.RED] = {
		[Color.RED] = Color.RED,		-- idempotence
		[Color.GREEN] = Color.YELLOW,
		[Color.BLUE] = Color.MAGENTA,
		[Color.CYAN] = Color.WHITE
	},
	[Color.GREEN] = {
		[Color.GREEN] = Color.GREEN,	-- idempotence
		[Color.RED] = Color.YELLOW,
		[Color.BLUE] = Color.CYAN,
		[Color.MAGENTA] = Color.WHITE
	},
	[Color.BLUE] = {
		[Color.BLUE] = Color.BLUE,		-- idempotence
		[Color.RED] = Color.MAGENTA,
		[Color.GREEN] = Color.CYAN,
		[Color.YELLOW] = Color.WHITE
	},
	[Color.CYAN] = {
		[Color.CYAN] = Color.CYAN,		-- idempotence
		[Color.RED] = Color.WHITE
	},
	[Color.MAGENTA] = {
		[Color.MAGENTA] = Color.MAGENTA,-- idempotence
		[Color.GREEN] = Color.WHITE
	},
	[Color.YELLOW] = {
		[Color.YELLOW] = Color.YELLOW,	-- idempotence
		[Color.BLUE] = Color.WHITE
	},
	[Color.WHITE] = {
		[Color.WHITE] = Color.WHITE		-- idempotence
	}
};

return {
	name = "addColors",
	value = function(first, second)
		if not first or first == Color.NONE then
			return second;
		end

		-- check if there's an entry with the first color
		if ColorMixMatrix[first] then
			-- check if there's a mix
			if ColorMixMatrix[first][second] then
				-- then get it
				return ColorMixMatrix[first][second];
			end
		end

		-- if no mix is available, return NONE
		return Color.NONE;
	end
};