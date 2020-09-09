local System = require(script.System)
local Selectors = require(script.Selectors)
local Util = require(script.Selectors.Util)

return function(rocs)
	rocs.selectors = Selectors(rocs)

	rocs.query = function(scope, ...) -- optimized for reuse
		assert(type(scope) == "string")
		return System.new(rocs, scope, ...):setup()
	end

	rocs.get = function(scope, ...) -- single use pipeline list getter
		assert(type(scope) == "string")

		local entities = {}
		for _, instance in pairs(System.new(rocs, ...):instances()) do
			table.insert(entities, rocs:getPipeline(instance, scope))
		end

		return entities
	end

	rocs.system = function(scope, selector, props, init) -- syntactic sugar around rocs.query
		assert(type(scope) == "string")
		assert(Util.inheritsBase(selector))
		assert(props == nil or type(props) == "table")
		assert(init == nil or type(init) == "function")

		local system = System.new(rocs, scope, selector)

		if props then
			for key, value in pairs(props) do
				if system[key] then
					error("at least one property already in use by system", 2)
				end
				system[key] = value
			end
		end

		if init then
			init(system)
		end

		return system:setup():catchup()
	end

	return rocs
end
