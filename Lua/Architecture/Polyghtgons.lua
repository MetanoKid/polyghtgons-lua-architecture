-- temporal function to show debug messages
local DEBUG = function(...)
	if(_DEBUG) then
		print(...);
	end
end

DEBUG("--------------------------------------------------");
DEBUG("Loading Lua:");

DEBUG("", "* Setting up global namespaces");
Polyghtgons = {
	Classes = {
		Logic = {
			Components = {},
			Messages = {}
		},
		Graphics = {},
		Scripting = {},
		Utils = {}
	},
	Functions = {},
	Config = {},
	Instances = {},
	L10N = {}
};

DEBUG("", "* Loading configuration data");
Polyghtgons.Config = assert(loadfile("scripts\\Configuration.lua"));
Polyghtgons.Config = Polyghtgons.Config();

DEBUG("\nSuccessfully loaded first part of Lua data.");

-- control is returned to C++ now that we've set up our static data
-- script load will return in other file, found in Polyghtgons.Config.mainLoaderFile
DEBUG("--------------------------------------------------");