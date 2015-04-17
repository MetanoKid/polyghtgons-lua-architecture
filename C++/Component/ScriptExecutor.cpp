#include "ScriptExecutor.h"

#include "Logic/Maps/BasicInfoExtractor.h"
#include "Logic/Level/Level.h"
#include "Logic/Entity/Entity.h"
#include "ScriptManager/Translator.h"

#include <luabind/class_info.hpp>

namespace Logic {

	IMP_FACTORY(CScriptExecutor);

	const std::string CScriptExecutor::METHOD_MESSAGE_PREFIX = "on";

	CScriptExecutor::CScriptExecutor() : IComponent(), _instance() {
		_scriptManager = ScriptManager::CScriptManager::getSingletonPtr();
	}

	CScriptExecutor::~CScriptExecutor() {
		_scriptManager = 0;

		if(_instance) {
			unpublishInstance();
		}
	}

	bool CScriptExecutor::spawn(CEntity *entity, const std::string &entityName, CBasicInfoCollection *basicInfo,
	                            Level::CLevel *level) {
		if(!IComponent::spawn(entity, entityName, basicInfo, level)) {
			return false;
		}

		// process data
		std::string luaConstructorName;

		if(BasicInfoExtractor::getString(basicInfo, entityName, "lua_constructor", luaConstructorName)) {
			// we will call constructor and keep built instance
			luabind::object constructor;

			// is there any Lua class named the way we received?
			if(!_scriptManager->getFunction(
			       ScriptManager::CScriptManager::CLASSES_NAMESPACE, luaConstructorName, constructor)) {
				return false;
			}

			// we're passing received info as a Lua object
			luabind::object infoAsLuaObject;
			ScriptManager::CTranslator::entityInfoToLua((CEntityInfoCollection *) basicInfo, entityName,
			                                            infoAsLuaObject);
			// get it
			EXEC_PROTECTED_REACT_ON_EXCEPTION(
			    _instance = constructor(infoAsLuaObject, this),
			    return false
			);

			// cache some methods like activate, deactivate, tick, methods for message handling...
			if(!cacheMethods()) {
				return false;
			}

			// now publish our instance into Lua, so other scripts may access it directly
			if(!publishInstance()) {
				return false;
			}
		}

		return true;
	}

	bool CScriptExecutor::activate() {
		bool activated = true;

		// invoke Lua instance's activate, passing it as first parameter (self)
		if(_activateFunction) {
			EXEC_PROTECTED(activated = luabind::object_cast<bool>(_activateFunction(_instance)));
		}

		return activated;
	}

	void CScriptExecutor::deactivate() {
		// invoke Lua instance's deactivate, passing it as first parameter (self)
		if(_deactivateFunction) {
			EXEC_PROTECTED(_deactivateFunction(_instance));
		}
	}

	bool CScriptExecutor::accept(TMessage *message) {
		// we accept messages which are indexed in our map
		return _messageFunctionMap.count(message->GetType()) > 0;
	}

	void CScriptExecutor::process(TMessage *message) {
		TMessageFunctionMap::const_iterator it = _messageFunctionMap.find(message->GetType());

		// we shouldn't need to check if we've got it, but we overprotect ourselves
		if(it != _messageFunctionMap.end()) {
			luabind::object function = it->second;
			EXEC_PROTECTED(function(_instance, message));
		}
	}

	void CScriptExecutor::tick(unsigned int msecs) {
		IComponent::tick(msecs);

		// invoke Lua instance's tick, passing it as first parameter (self)
		if(_tickFunction) {
			EXEC_PROTECTED(_tickFunction(_instance, msecs * 0.001f));
		}
	}

	bool CScriptExecutor::cacheMethods() {
		// get Lua's activate method, if any
		if(_instance["activate"]) {
			_activateFunction = _instance["activate"];
		}

		// get Lua's deactivate method, if any
		if(_instance["deactivate"]) {
			_deactivateFunction = _instance["deactivate"];
		}

		// get Lua's tick method, if any
		if(_instance["tick"]) {
			_tickFunction = _instance["tick"];
		}

		// get Lua's snapShot method, if any
		if(_instance["snapShot"]) {
			_snapShotFunction = _instance["snapShot"];
		}

		// get all message processing methods
		luabind::object function;
		// we're going to inspect instance methods now
		// it's a bit hacky but there's no official way to do this. Let's explain it step by step:
		lua_State *lua = _scriptManager->getCurrentLuaState();
		// push our object to Lua stack
		_instance.push(lua);
		// get it back as an argument
		luabind::argument arg = luabind::from_stack(lua, lua_gettop(lua));
		// now get its info
		luabind::class_info info = luabind::get_class_info(arg);
		// we've got our data, so we can pop our object from Lua stack
		lua_pop(lua, 1);
		// iterate over methods
		std::string methodNameWithoutOn;
		std::size_t prefixPosition;

		for(luabind::iterator it(info.methods), end; it != end; ++it) {
			std::string methodName = luabind::object_cast<std::string>(it.key());
			// every message processing method begins with a prefix and then has the message name
			prefixPosition = methodName.find(METHOD_MESSAGE_PREFIX);

			if(prefixPosition != std::string::npos) {
				methodNameWithoutOn = methodName.substr(prefixPosition + METHOD_MESSAGE_PREFIX.length());

				// this exception is intentional and necessary
				try {
					MessageType type = MessageTypeEnumParser.parseString(methodNameWithoutOn);
					_messageFunctionMap[type] = *it;
				} catch(const std::exception &ex) {
					// didn't find message name in map, so it's not mapped and we do nothing
				}
			}
		}

		return true;
	}

	void CScriptExecutor::snapShot() {
		// invoke Lua instance's snapShot, passing it as first parameter (self)
		if(_snapShotFunction) {
			EXEC_PROTECTED(_snapShotFunction(_instance));
		}
	}

	bool CScriptExecutor::publishInstance() {
		// here we'll store the Lua function to publish instances into the correct namespace
		luabind::object function;

		if(!ScriptManager::CScriptManager::getSingletonPtr()->getFunction(
		       ScriptManager::CScriptManager::FUNCTIONS_NAMESPACE, "publishInstance", function)) {
			return false;
		}

		// now publish it, and get its returning value
		bool result = luabind::object_cast<bool>(function(_entity->getName(), _instance));
		assert(result && "There's something with the same name already published into the instances namespace");
		return result;
	}

	void CScriptExecutor::unpublishInstance() {
		luabind::object function;

		if(ScriptManager::CScriptManager::getSingletonPtr()->getFunction(
		       ScriptManager::CScriptManager::FUNCTIONS_NAMESPACE, "publishInstance", function)) {
			function(_entity->getName());
		}
	}
}