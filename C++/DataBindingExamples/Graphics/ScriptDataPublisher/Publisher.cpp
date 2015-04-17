#include "Publisher.h"

// include our ScriptManager
#include "ScriptManager/ScriptManager.h"

namespace Graphics {

	namespace ScriptDataPublisher {

		void CPublisher::registerData(lua_State *lua) {
			luabind::module(lua, "Polyghtgons")
			[
			    luabind::namespace_("Classes") [
			        luabind::namespace_("Graphics") [
			            // Vector2 definition
			            luabind::class_<Vector2>("Vector2")
			            .def(luabind::constructor<float, float>())
			            .def_readonly("x", &Vector2::x)
			            .def_readonly("y", &Vector2::y),

			            // Vector3 definition
			            luabind::class_<Vector3>("Vector3")
			            .def(luabind::constructor<float, float, float>())
			            .def_readonly("x", &Vector3::x)
			            .def_readonly("y", &Vector3::y)
			            .def_readonly("z", &Vector3::z)
			            .def("angleBetween", &Vector3::angleBetween)
			            .def("cross", &Vector3::crossProduct)
			            .def("dot", &Vector3::dotProduct)
			            .property("normalized", &Vector3::normalisedCopy),

			            // Vector4 definition
			            luabind::class_<Vector4>("Vector4")
			            .def(luabind::constructor<float, float, float, float>())
			            .def_readonly("x", &Vector4::x)
			            .def_readonly("y", &Vector4::y)
			            .def_readonly("z", &Vector4::z)
			            .def_readonly("w", &Vector4::w),

			            // Radians
			            luabind::class_<Ogre::Radian>("Radian")
			            .property("degrees", &Ogre::Radian::valueDegrees)
			        ]
			    ]
			];
		}

	}

}