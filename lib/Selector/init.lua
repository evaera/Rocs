local Selectors = require(script.Selectors)

return function(rocs)

	rocs.select = function()
		error("Not implemented", 2)
	end

	local connection = rocs:registerLifecycleHook("Health", "onAdded", function() end)

	rocs.selectors = Selectors

end
