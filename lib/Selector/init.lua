local Selectors = require(script.Selectors)
local System = require(script.Parent.System)
local AllSelector = require(script.Parent.AllSelector)

return function(rocs)

	rocs.system = function(scope, ...) -- optimized for reuse
		return System.new(rocs, scope):setup() -- TODO use scope
	end

	rocs.get = function(scope, ...) -- single use entity list getter
		return AllSelector.new(rocs, ...):get() -- TODO use scope
	end

	rocs.selectors = Selectors(rocs)

	return rocs
end
