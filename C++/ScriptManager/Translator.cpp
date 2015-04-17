#include "Translator.h"
#include "Logic/Maps/BasicInfoCollection.h"
#include "Logic/Maps/EntityInfoCollection.h"
#include "Logic/Maps/BasicInfoExtractor.h"

namespace ScriptManager {

	void CTranslator::entityInfoToLua(Logic::CEntityInfoCollection *info,
	                                  const std::string &entityName,
	                                  luabind::object &luaObject) {
		// cache this so we have it handy
		lua_State *luaState = ScriptManager::CScriptManager::getSingletonPtr()->getCurrentLuaState();

		// we might have received no info, which would be stupid but just in case
		if(!info) {
			return;
		}

		// let's get its properties
		const rapidjson::Value &properties = info->getProperties();

		jsonToLua(properties, luaObject);

		// now get parent: we will be getting data from archetypes
		Logic::CBasicInfoCollection *parent = info->getParent();

		// there might be no archetype
		if(parent) {
			std::string archetypeName;

			// there might be an archetype but not a name in the info, so we wouldn't be able to retrieve it
			if(Logic::BasicInfoExtractor::getString(info, entityName, "archetype", archetypeName)) {
				// this is the data related to its archetype
				rapidjson::Value &archetypeData = parent->getValue(archetypeName);
				luabind::object parentData;
				jsonToLua(archetypeData, parentData);

				extend(luaObject, parentData);
			}
		}
	}

	void CTranslator::jsonToLua(const rapidjson::Value &json, luabind::object &luaObject) {
		luaObject = luabind::newtable(
		                ScriptManager::CScriptManager::getSingletonPtr()->getCurrentLuaState());

		if(json.IsArray()) {
			int i = 1;

			for(rapidjson::Value::ConstValueIterator itValue = json.Begin(); itValue != json.End();
			    ++itValue, ++i) {
				switch(itValue->GetType()) {
					case rapidjson::kFalseType:
					case rapidjson::kTrueType:
						luaObject[i] = itValue->GetBool();
						break;

					case rapidjson::kNumberType: {
							luaObject[i] = itValue->IsInt() ? itValue->GetInt() :
							               itValue->GetDouble();
						}
						break;

					case rapidjson::kStringType: {
							luaObject[i] = itValue->GetString();
						}
						break;

					case rapidjson::kArrayType: {
							luabind::object arrayData;
							jsonToLua(*itValue, arrayData);
							luaObject[i] = arrayData;
						}
						break;

					case rapidjson::kObjectType: {
							luabind::object objectData;
							jsonToLua(*itValue, objectData);
							luaObject[i] = objectData;
						}
						break;
				}
			}
		} else if(json.IsObject()) {
			std::string propertyName;

			for(rapidjson::Value::ConstMemberIterator itMember = json.MemberBegin(); itMember != json.MemberEnd();
			    ++itMember) {
				propertyName = itMember->name.GetString();

				switch(itMember->value.GetType()) {
					case rapidjson::kFalseType:
					case rapidjson::kTrueType:
						luaObject[propertyName] = itMember->value.GetBool();
						break;

					case rapidjson::kNumberType: {
							luaObject[propertyName] = itMember->value.IsInt() ? itMember->value.GetInt() :
							                          itMember->value.GetDouble();
						}
						break;

					case rapidjson::kStringType: {
							luaObject[propertyName] = itMember->value.GetString();
						}
						break;

					case rapidjson::kArrayType: {
							luabind::object arrayData;
							jsonToLua(itMember->value, arrayData);
							luaObject[propertyName] = arrayData;
						}
						break;

					case rapidjson::kObjectType: {
							luabind::object objectData;
							jsonToLua(itMember->value, objectData);
							luaObject[propertyName] = objectData;
						}
						break;
				}
			}
		}
	}

	void CTranslator::extend(luabind::object &objectToExtend, const luabind::object &other,
	                         bool overrideValues) {
		for(luabind::iterator it(other), end; it != end; ++it) {
			if(!objectToExtend[it.key()] || overrideValues) {
				objectToExtend[it.key()] = *it;
			}
		}
	}

}