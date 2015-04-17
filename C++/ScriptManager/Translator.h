#ifndef ScriptManager_Translator_H
#define ScriptManager_Translator_H

#include "ScriptManager.h"
#include <document.h>

// predeclarations
namespace Logic {
	class CEntityInfoCollection;
}

namespace ScriptManager {

	class CTranslator {
	private:
		/**
		Translates a JSON value object into a Lua object
		*/
		static void jsonToLua(const rapidjson::Value &json, luabind::object &luaObject);

		/**
		Extends a Lua object with the properties of another Lua object, with optional value overriding
		*/
		static void extend(luabind::object &objectToExtend, const luabind::object &other,
		                   bool overrideValues = false);

	public:
		/**
		Translates the info received by an entity to a Lua object, ready to be passed into Lua.
		*/
		static void entityInfoToLua(Logic::CEntityInfoCollection *info,
		                            const std::string &entityName,
		                            luabind::object &luaObject);
	};

}

#endif