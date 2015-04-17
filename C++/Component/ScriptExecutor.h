#ifndef Logic_Components_ScriptExecutor_H
#define Logic_Components_ScriptExecutor_H

#include "Logic/Entity/Component.h"
#include "Logic/Messages/MessageType.h"
#include "Logic/Messages/EnumParser.h"
#include "ScriptManager/ScriptManager.h"

namespace Logic {

	class CScriptExecutor : public IComponent {
		DEC_FACTORY(CScriptExecutor);
	private:
		ScriptManager::CScriptManager *_scriptManager;

		static const std::string METHOD_MESSAGE_PREFIX;

		luabind::object _instance;

		bool cacheMethods();

		bool publishInstance();

		void unpublishInstance();

		// these variables cache Lua methods
		luabind::object _activateFunction;
		luabind::object _deactivateFunction;
		luabind::object _tickFunction;
		luabind::object _snapShotFunction;

		typedef map<MessageType, luabind::object> TMessageFunctionMap;
		TMessageFunctionMap _messageFunctionMap;

	public:
		CScriptExecutor();
		virtual ~CScriptExecutor();

		virtual bool spawn(CEntity *entity, const std::string &entityName, CBasicInfoCollection *basicInfo,
		                   Level::CLevel *level);

		virtual bool activate();

		virtual void deactivate();

		virtual bool accept(TMessage *message);

		virtual void process(TMessage *message);

		virtual void tick(unsigned int msecs);

		virtual void snapShot();
	};

	REG_FACTORY(CScriptExecutor);

}

#endif