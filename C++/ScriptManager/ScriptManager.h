#ifndef ScriptManager_ScriptManager_H
#define ScriptManager_ScriptManager_H

#include "BaseSubsystems/Math.h"

// include luabind
#include <luabind/luabind.hpp>

// forward declarations
struct lua_State;

namespace ScriptManager {

#define LUA_BASE_PATH "scripts/"

	/**
	When executing luabind functions via luabind::object(), they may fail.
	It's cumbersome writing a try-catch block for every call, so we can wrap the code in which
	we execute a function with this macro.
	*/
#define EXEC_PROTECTED_REACT_ON_EXCEPTION(body, onFail) \
try {\
	body;\
} catch(const luabind::error &ex) {\
	printf("%s -> %s\n", ex.what(), lua_tostring(ScriptManager::CScriptManager::getSingletonPtr()->getCurrentLuaState(), -1));\
	onFail;\
}

	/**
	When we don't want to perform any action when a luabind function execution fails, we can just
	use this macro to wrap it in a protected environment.
	@see EXEC_PROTECTED_REACT_ON_EXCEPTION
	*/
#define EXEC_PROTECTED(body) EXEC_PROTECTED_REACT_ON_EXCEPTION(body, );

	class CScriptManager {
	private:
		CScriptManager();
		~CScriptManager();

		bool open();
		void close();

		static int customLuaErrorFunction(lua_State *lua);
		static int customLuaPanicFunction(lua_State *lua);

		bool getObjectFromNamespace(const std::string &namespace_,
		                            const std::string &name,
		                            luabind::object &object) const;

		lua_State *_lua;
		static CScriptManager *_instance;

	public:
		static const std::string FUNCTIONS_NAMESPACE;
		static const std::string CLASSES_NAMESPACE;
		static const std::string CONFIG_NAMESPACE;

		static bool Init();
		static void Release();
		static CScriptManager *getSingletonPtr();

		lua_State *getCurrentLuaState() const;

		bool loadScript(const std::string &fileName);
		bool loadScripts();
		bool getFunction(const std::string &namespaceName,
		                 const std::string &functionName,
		                 luabind::object &object) const;
		bool getObject(const std::string &namespaceName,
		               const std::string &objectName,
		               luabind::object &object) const;

		static luabind::object getLuaFileNames(const std::string &directory);
	};

}

#endif