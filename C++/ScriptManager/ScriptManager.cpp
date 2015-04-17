#include "ScriptManager.h"

#include "Logic/Messages/Message.h"

// include Lua, which was compiled in C
extern "C" {
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
}

#include <luabind/class_info.hpp>

// used to crawl a directory and list its files
#include <dirent.h>

namespace ScriptManager {

	CScriptManager *CScriptManager::_instance = 0;

	const std::string CScriptManager::FUNCTIONS_NAMESPACE = "Polyghtgons.Functions";
	const std::string CScriptManager::CLASSES_NAMESPACE = "Polyghtgons.Classes.Scripting";
	const std::string CScriptManager::CONFIG_NAMESPACE = "Polyghtgons.Config";

	bool CScriptManager::Init() {
		assert(_instance == NULL && "Can't call Init twice on the ScriptManager");
		_instance = new CScriptManager();

		if(!_instance->open()) {
			Release();
			return false;
		}

		return true;
	}

	void CScriptManager::Release() {
		assert(_instance && "Can't call Release on the ScriptManager. It's not initialized yet.");

		delete _instance;
		_instance = NULL;
	}

	CScriptManager *CScriptManager::getSingletonPtr() {
		assert(_instance && "Can't get ScriptManager's instance. It's not initialized.");
		return _instance;
	}

	CScriptManager::CScriptManager() : _lua(NULL) {

	}

	CScriptManager::~CScriptManager() {
		close();
	}

	int CScriptManager::customLuaErrorFunction(lua_State *L) {
		lua_Debug d;

		// if it returns 0 it means our second parameter is too high
		// if it returns 1 it means no errors ocurred
		if(lua_getstack(L, 0, &d) > 1) {
			lua_getinfo(L, "Sln", &d);
			std::string err = lua_tostring(L, -1);
			lua_pop(L, 1);
			std::stringstream msg;
			msg << d.short_src << ":" << d.currentline;

			if(d.name != 0) {
				msg << "(" << d.namewhat << " " << d.name << ")";
			}

			msg << " " << err;
			lua_pushstring(L, msg.str().c_str());
		}

		return 1;
	}

	int CScriptManager::customLuaPanicFunction(lua_State *L) {
		std::string msg("Lua panic, you fucked it up in C++. Check your code, boy!");
		lua_pushstring(L, msg.c_str());

		// throw exception so we can catch it when we called
		throw std::exception(msg.c_str());
		return 0;
	}

	bool CScriptManager::getObjectFromNamespace(const std::string &namespace_,
	                                            const std::string &name,
	                                            luabind::object &object) const {
		// start searching from the top of the namespaces: the global namespace
		luabind::object currentNamespace = luabind::globals(_lua);

		// now tokenize namespace into a vector
		std::istringstream istream(namespace_);
		std::vector<std::string> tokens;
		std::string token;

		while(std::getline(istream, token, '.')) {
			if(!token.empty()) {
				tokens.push_back(token);
			}
		}

		// now "walk" the vector and inspect if we have the full namespace
		for(int i = 0, limit = tokens.size(); i < limit; ++i) {
			if(currentNamespace[tokens[i]]) {
				currentNamespace = currentNamespace[tokens[i]];
			} else {
				printf("There's no valid namespace named %s\n", namespace_.c_str());
				return false;
			}
		}

		// we've walked the namespace, now retrieve the object
		if(!currentNamespace[name]) {
			printf("There's no object named %s in namespace %s\n", name.c_str(), namespace_.c_str());
			return false;
		}

		// finally, extract it
		object = currentNamespace[name];

		return true;
	}

	bool CScriptManager::open() {
		_lua = lua_open();

		if(!_lua) {
			return false;
		}

		luaopen_base(_lua);
		luaopen_table(_lua);
		luaopen_string(_lua);
		luaopen_math(_lua);
		luaL_openlibs(_lua);
		luabind::open(_lua);

		// bind class info data, so we can access it from Lua
		luabind::bind_class_info(_lua);

		luabind::set_pcall_callback(&customLuaErrorFunction);
		lua_atpanic(_lua, &customLuaPanicFunction);

		// set some global variables for scripts
#if _DEBUG
		luabind::globals(_lua)["_DEBUG"] = true;
#endif
#if WIN32
		luabind::globals(_lua)["_WIN32"] = true;
#endif

		// load base script
		loadScript("Polyghtgons.lua");

		return true;
	}

	void CScriptManager::close() {
		if(_lua) {
			lua_close(_lua);
			_lua = NULL;
		}
	}

	lua_State *CScriptManager::getCurrentLuaState() const {
		return _lua;
	}

	bool CScriptManager::loadScript(const std::string &fileName) {
		assert(_lua && "Can't execute Lua function. It's not initialized yet");

		std::stringstream stream;
		stream << LUA_BASE_PATH << fileName;

		int loadingValue = luaL_dofile(_lua, stream.str().c_str());

		if(loadingValue != 0) {
			printf("[Lua load script] %s\n", lua_tostring(_lua, -1));
			return false;
		}

		return true;
	}

	bool CScriptManager::loadScripts() {
		// after base script has been loaded, and thus global namespaces have been set up
		// and config file has been processed, we can load the rest of our scripts
		luabind::object data;
		bool extracted = getObjectFromNamespace(CONFIG_NAMESPACE, "mainLoaderFile", data);
		assert(extracted && "Main loader file name not defined in Config namespace");

		return loadScript(luabind::object_cast<std::string>(data));
	}

	bool CScriptManager::getFunction(const std::string &namespaceName,
	                                 const std::string &functionName,
	                                 luabind::object &object) const {
		assert(_lua, "Can't get any function from Lua. It's not initialized yet");

		try {
			luabind::object obj;

			if(getObjectFromNamespace(namespaceName, functionName, obj)) {
				if(luabind::type(obj) == LUA_TFUNCTION || luabind::type(obj) == LUA_TUSERDATA) {
					object = obj;
					return true;
				}
			}
		} catch(const luabind::error &error) {
			printf("%s: %s\n", error.what(), lua_tostring(_lua, -1));
		}

		return false;
	}

	bool CScriptManager::getObject(const std::string &namespaceName,
	                               const std::string &objectName,
	                               luabind::object &object) const {
		assert(_lua, "Can't get any function from Lua. It's not initialized yet");

		try {
			luabind::object obj;

			if(getObjectFromNamespace(namespaceName, objectName, obj)) {
				if(luabind::type(obj) != LUA_TFUNCTION || luabind::type(obj) == LUA_TUSERDATA) {
					object = obj;
					return true;
				}
			}
		} catch(const luabind::error &error) {
			printf("%s: %s\n", error.what(), lua_tostring(_lua, -1));
		}

		return false;
	}

	luabind::object CScriptManager::getLuaFileNames(const std::string &directory) {
		assert(_instance && "Can't get Lua file names: Lua isn't initialized");

		// we'll be returning file names as a Lua "array", thus we create a table
		luabind::object fileNames = luabind::newtable(_instance->_lua);
		// Lua "arrays" start at index 1
		int index = 1;

		// dirent stuff
		DIR *dir = NULL;
		dirent *entry = NULL;

		// open given directory
		dir = opendir(directory.c_str());

		// start reading it
		while(dir) {
			entry = readdir(dir);

			if(!entry) {
				break;
			}

			// only if extensions match
			if(strstr(entry->d_name, ".lua")) {
				// insert it and increment index
				fileNames[index] = entry->d_name;
				index++;
			}
		}

		// finally, close the directory we've opened
		closedir(dir);

		return fileNames;
	}
}