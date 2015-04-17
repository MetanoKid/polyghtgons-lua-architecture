-- temporal function to show debug messages
local DEBUG = function(...)
	if(_DEBUG) then
		print(...);
	end
end

DEBUG("--------------------------------------------------");
DEBUG("Loading second part of Lua data:");
DEBUG("", "* Loading scripts loader");
local scriptsLoader = assert(loadfile(Polyghtgons.Config.scriptsLoaderFile));
scriptsLoader = scriptsLoader();

DEBUG("", "* Loading global functions");
Polyghtgons.Functions = scriptsLoader(Polyghtgons.Config.functionsDirectory);

DEBUG("", "* Loading Lua class definitions");
Polyghtgons.Classes.Scripting = scriptsLoader(Polyghtgons.Config.classesDirectory);

DEBUG("", "* Loading language data");
Polyghtgons.L10N = scriptsLoader(Polyghtgons.Config.localizationDirectory);

DEBUG("", "* Cleaning and packing up");
for className, _ in pairs(Polyghtgons.Classes.Scripting) do
	_G[className] = nil;
end

DEBUG("\nSuccessfully loaded second part of Lua data.");

-- finished successfully
DEBUG("Lua OK, baby.");
DEBUG("--------------------------------------------------");