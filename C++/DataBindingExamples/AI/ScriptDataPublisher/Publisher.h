#ifndef AI_ScriptDataPublisher_Publisher_H
#define AI_ScriptDataPublisher_Publisher_H

struct lua_State;

namespace AI {

	namespace ScriptDataPublisher {

		class CPublisher {
		public:
			static void registerData(lua_State *lua);
		};

	}

}

#endif