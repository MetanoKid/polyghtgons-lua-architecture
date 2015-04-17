local userDataPrinter = function(object)
	local info = class_info(object);

	print(info.name);

	for methodName, _ in pairs(info.methods) do
		print("[M]", methodName);
	end

	for _, attributeName in ipairs(info.attributes) do
		print("[A]", attributeName);
	end
end

return {
	name = "userDataPrinter",
	value = userDataPrinter
};