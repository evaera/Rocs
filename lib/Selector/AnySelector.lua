local BaseSelector = require(script.Parent.BaseSelector)
local Util = require(script.Parent.Util)

local AnySelector = setmetatable({}, BaseSelector)
AnySelector.__index = AnySelector

function AnySelector.new(rocs, ...)
	local self = setmetatable(BaseSelector.new(rocs), AnySelector)

	self._selectors = {}
	for _, property in pairs(...) do
		if type(property) == "function" then
			error("Cannot have functions in selectors.any", 2)
		else
			table.insert(self._selectors, Util.resolve(property))
		end
	end

	return self
end

function AnySelector:instances()
	local instances = {}

	if #self._selectors > 0 then
		-- accumulate entities into cache, only-once
		for _, selector in pairs(self._selectors) do
			for _, instance in pairs(selector:instances()) do
				instances[instance] = true
			end
		end

		-- turn lookup into array
		for instance in pairs(instances) do
			table.insert(instances, instance)
			instances[instance] = nil
		end
	end

	return instances
end

function AnySelector:check(instance)
	for _, selector in pairs(self._selectors) do
		if selector:check(instance) then
			return true
		end
	end

	return false
end

return AnySelector
