local objectPrinter = function(object, indentationLevel)
	indentationLevel = indentationLevel or 0;

	-- get some indentation for pretty printing
	local indentation = "";
	for i = 1, indentationLevel do
		indentation = indentation .. "\t";
	end

	-- now print it
	for k, v in pairs(object) do
		-- we might have to go a level deeper
		if type(v) == "table" then
			print(indentation .. k .. ":");
			Polyghtgons.Functions.objectPrinter(v, indentationLevel + 1);
		else
			print(indentation .. k .. ":", v);
		end
	end
end

return {
	name = "objectPrinter",
	value = objectPrinter
};