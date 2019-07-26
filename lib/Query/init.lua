local System = require(script.System)
local Selectors = require(script.Selectors)
local AllSelector = require(script.Selectors.AllSelector)

return function(rocs)

	rocs.system = function(scope, ...) -- optimized for reuse
		return System.new(rocs, scope, ...):setup()
	end

	rocs.get = function(scope, ...) -- single use entity list getter
		local entities = {}
		for _, instance in pairs(AllSelector.new(rocs, ...):get()) do
			table.insert(entities, rocs:getEntity(instance, scope))
		end
		return entities
	end

	rocs.selectors = Selectors(rocs)

	return rocs
end
