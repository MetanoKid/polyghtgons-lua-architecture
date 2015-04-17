-- this object will represent a namespace within our global namespace, and we'll store some configuration data in it
local Config = {};

-- folder names section
local scriptsDirectoryName = "scripts";
local functionsBaseDirectory = "Functions";
local classesBaseDirectory = "Classes";
local localizationBaseDirectory = "Localization";

-- file names section
local scriptsLoaderName = "FileLoader.lua";

-- Config's own properties to load proper files when performing automatic loading
Config.mainLoaderFile = "MainLoader.lua";
Config.fileSeparator = "\\";
Config.scriptsDirectory = scriptsDirectoryName .. Config.fileSeparator;
Config.functionsDirectory = Config.scriptsDirectory .. functionsBaseDirectory .. Config.fileSeparator;
Config.classesDirectory = Config.scriptsDirectory .. classesBaseDirectory .. Config.fileSeparator;
Config.scriptsLoaderFile = Config.scriptsDirectory .. scriptsLoaderName;
Config.localizationDirectory = Config.scriptsDirectory .. localizationBaseDirectory .. Config.fileSeparator;

Config.maxClassLoadDepth = 3;	-- increment this for higher hierarchy levels

Config.Languages = {
	EN_GB = "en_gb",
	ES_ES = "es_es"
};

--[[
From C++ we may access some static configuration data, which we will consider constants.
Using this property in the namespace we store that data we want to access from C++. If we set it here it will be cached on game's start up and then will be available.
Whenever we want to access a property from C++, it will first check this cache for the property. If it doesn't exist then it will check for the same property in the Config namespace. If it doesn't exist either, it will assert with a message.

[Important] We can just store primitive values in this object:
	* int
	* float
	* double
	* bool
	* string

Arrays and objects aren't allowed (you can add them, but won't be processed from C++).
]]
Config.cacheOnStart = {
	info_file_path = "./media/maps/",
	blueprints_file_path = "./media/maps/",

	blueprints_file_name = "blueprints2.txt",
	archetypes_file_name = "archetypes/archetypes.json",
	level_file_name = "levels/LittleMainMenu.json",

	main_menu = "levels/LittleMainMenu.json",

	level_01 = "levels/FirstLevel.json",
	level_02 = "levels/Butterfly.json",
	level_03 = "levels/ThirdLevel.json",

	tutorial_01 = "levels/tutorial001.json",
	tutorial_02 = "levels/tutorial002.json",
	tutorial_03 = "levels/tutorial003.json",
	tutorial_04 = "levels/tutorial004.json",
	tutorial_05 = "levels/tutorial005.json",
	tutorial_06 = "levels/tutorial006.json",
	tutorial_07 = "levels/tutorial007.json",
	tutorial_08 = "levels/tutorial008.json",
	tutorial_09 = "levels/tutorial009.json",

	perceptionFrequency = 10,

	audio_mute_all = false,
	audio_mute_sfx = false,
	audio_mute_bgm = false,

	left_click_control = true,

	glow_enabled = true,

	language = Config.Languages.EN_GB
};

return Config;