return {
	name = "localize",
	value = function (key)
		local L10N = Polyghtgons.L10N;
		local lang = Polyghtgons.Config.language or Polyghtgons.Config.cacheOnStart.language;

		if L10N and lang and L10N[lang] then
			return L10N[lang][key];
		end

		return "Key '" .. key .. "' not found for current locale '" .. lang .. "'";
	end
};