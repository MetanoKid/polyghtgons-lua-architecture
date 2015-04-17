-- extract here the namespace in which we will look for colors
local Color = Polyghtgons.Classes.Logic.Components.Polyghtgon;

-- we store color components here
-- a missing entry is nil by default, which evaluates to false
local ColorComponents = {
	[Color.RED] = {
		[Color.RED] = true
	},
	[Color.GREEN] = {
		[Color.GREEN] = true
	},
	[Color.BLUE] = {
		[Color.BLUE] = true
	},
	[Color.CYAN] = {
		[Color.GREEN] = true,
		[Color.BLUE] = true
	},
	[Color.MAGENTA] = {
		[Color.RED] = true,
		[Color.BLUE] = true
	},
	[Color.YELLOW] = {
		[Color.RED] = true,
		[Color.GREEN] = true
	},
	[Color.WHITE] = {
		[Color.RED] = true,
		[Color.GREEN] = true,
		[Color.BLUE] = true,
		[Color.CYAN] = true,
		[Color.MAGENTA] = true,
		[Color.YELLOW] = true
	}
};

return {
	name = "isComponent",
	value = function(component, color)
		return ColorComponents[color] and ColorComponents[color][component];
	end
};