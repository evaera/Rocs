local AllSelector = require(script.AllSelector)
local AnySelector = require(script.AnySelector)
local ComponentSelector = require(script.ComponentSelector)

return function(rocs)
	local Selectors = {}

	function Selectors.isa(class)
		return function(instance)
			return instance:IsA(class)
		end
	end

	function Selectors.any(...)
		return AnySelector.new(rocs, ...)
	end

	function Selectors.all(...)
		return AllSelector.new(rocs, ...)
	end

	function Selectors.has(name, properties, metacomponents)
		return ComponentSelector.new(rocs, name, properties, metacomponents)
	end

	return Selectors
end
