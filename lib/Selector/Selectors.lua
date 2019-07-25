local AllSelector = require(script.Parent.AllSelector)
local AnySelector = require(script.Parent.AnySelector)
local ComponentSelector = require(script.Parent.ComponentSelector)

return function(rocs)
	local Selectors = {}

	function Selectors.isa(class)
		return function(entity)
			return entity.instance:IsA(class)
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
