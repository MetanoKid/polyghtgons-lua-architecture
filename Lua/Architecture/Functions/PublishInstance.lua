return {
	name = "publishInstance",
	value = function(entityName, luaInstance)
		-- this function may be invoked with or without an instance.
		-- if it's without an instance, it's used for cleaning up
		if luaInstance and Polyghtgons.Instances[entityName] then
			return false;
		end

		Polyghtgons.Instances[entityName] = luaInstance;
		return true;
	end
};