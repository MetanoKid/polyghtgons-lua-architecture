#ifndef Graphics_ScriptDataPublisher_Publisher_H
#define Graphics_ScriptDataPublisher_Publisher_H

struct lua_State;

namespace Graphics {

	namespace ScriptDataPublisher {

		class CPublisher {
		public:
			static void registerData(lua_State *lua);
		};

	}

}

#endif