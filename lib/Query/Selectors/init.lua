local AllSelector = require(script.AllSelector)
local AnySelector = require(script.AnySelector)
local LayerSelector = require(script.LayerSelector)

return function(rocs)
	local Selectors = {}

	function Selectors.isa(class)
		assert(type(class) == "string")

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
		assert(type(name) == "string")
		assert(properties == nil or type(properties) == "table")
		assert(metacomponents == nil or type(metacomponents) == "table")

		return LayerSelector.new(rocs, name, properties, metacomponents)
	end

	return Selectors
end
