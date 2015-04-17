#include "Publisher.h"

// server
#include "AI/Server.h"

// perception
#include "AI/Perception/PerceptionEntity.h"
#include "AI/Perception/PerceptionTypes.h"

// include our ScriptManager
#include "ScriptManager/ScriptManager.h"

#include <luabind/adopt_policy.hpp>

namespace AI {

	namespace ScriptDataPublisher {

		void CPublisher::registerData(lua_State *lua) {
			luabind::module(lua, "Polyghtgons")
			[
			    luabind::namespace_("Classes") [
			        luabind::namespace_("AI") [
			            // server
			            luabind::class_<CServer>("Server")
			            .scope [
			                luabind::def("getSingleton", &CServer::getSingletonPtr)
			            ]
			            .def("addEdge", &CServer::setEdge)
			            .def("removeEdge", &CServer::removeEdge)
			            .def("changeHeight", &CServer::changeHeight),
			            // perception entity
			            luabind::class_<Perception::CPerceptionEntity>("PerceptionEntity")
			            .enum_("PerceptionType") [
			                luabind::value("UNKNOWN", AI::Perception::PerceptionType::UNKNOWN),
			                luabind::value("SIGHT", AI::Perception::PerceptionType::SIGHT),
			                luabind::value("LIGHT", AI::Perception::PerceptionType::LIGHT)
			            ]
			        ]
			    ]
			];
		}

	}

}