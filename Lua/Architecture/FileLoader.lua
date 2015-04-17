local loadClassInto = function(targetTable, data)
	-- check if we're adding a duplicate key
	if targetTable[data.name] then
		local message = "Duplicate name found when loading file '" .. path .. fileName .. "'\n";
		message = message .. "\tTrying to add key '" .. data.name .. "'. Current table keys:\n";
		for key, _ in pairs(targetTable) do
			message = message .. "\t\t" .. key .. "\n";
		end

		assert(false, message);
	end

	-- add it to the table
	targetTable[data.name] = data.value;
end

local FileLoader = function(path)
	-- we will load every file in a table and return it later on
	local targetTable = {};

	-- we may load some files which depend on others which aren't loaded yet, so we need to note them down
	local dependentClasses = {};

	-- get the list of Lua files in a given path
	local fileNames = Polyghtgons.Classes.Utils.getFileNames(path);

	-- start crawling the directory
	for _, fileName in ipairs(fileNames) do
		-- let's load a file, which is a module
		local module = assert(loadfile(path .. fileName));

		-- module returns an object { name = _, value = _ }
		local data = module();

		-- if data is nil, it's our convention to say it depends on something which isn't yet loaded, else we can load it
		if data == nil then
			table.insert(dependentClasses, fileName);
		else
			loadClassInto(targetTable, data);
		end
	end

	-- load dependent classes
	local classLoadDepth = 0;
	while #dependentClasses > 0 and classLoadDepth < Polyghtgons.Config.maxClassLoadDepth do
		local remainingDependentClasses = {};

		-- let's try to load all scripts which were dependent on something
		for _, fileName in ipairs(dependentClasses) do
			-- it's a module, like we did before
			local module = assert(loadfile(path .. fileName));

			-- it returns our { name = _, value = _ } object
			local data = module();

			-- it may still be dependent on other thing, so we have to check
			if data == nil then
				table.insert(remainingDependentClasses, fileName);
			else
				loadClassInto(targetTable, data);
			end
		end

		dependentClasses = remainingDependentClasses;
		classLoadDepth = classLoadDepth + 1;
	end

	if #dependentClasses > 0 and classLoadDepth == Polyghtgons.Config.maxClassLoadDepth then
		local message = "Reached max depth when loading classes. Remaining dependent files:";
		for _, fileName in ipairs(dependentClasses) do
			message = message .. "\n\t" .. fileName;
		end

		assert(false, message);
	end

	return targetTable;
end

return FileLoader;