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
			table.insert(self._selectors, Util.resolve(rocs, property))
		end
	end

	return self
end

function AnySelector:_listen()
	for _, selector in pairs(self._selectors) do
		selector:onAdded(
			function(aggregate)
				local instance = aggregate.instance
				if not self._lookup[instance] then
					self._lookup[instance] = true
					self:_trigger("onAdded", aggregate)
				end
			end
		)

		selector:onRemoved(
			function(aggregate)
				local instance = aggregate.instance
				if self._lookup[instance] and not self:check(instance) then
					self._lookup[instance] = nil
					self:_trigger("onRemoved", aggregate)
				end
			end
		)

		selector:onUpdated(
			function(aggregate)
				local instance = aggregate.instance
				if self._lookup[instance] then
					self:_trigger("onUpdated", aggregate)
				else
					self._lookup[instance] = true
					self:_trigger("onAdded", aggregate)
				end
			end
		)

		-- TODO: is this right?
		selector:onParentUpdated(
			function(aggregate)
				if self._lookup[aggregate.instance] then
					self:_trigger("onParentUpdated", aggregate)
				end
			end
		)
	end
end

function AnySelector:instances()
	local instances = {}

	if #self._selectors > 0 then
		-- accumulate entities into cache, only-once
		for _, selector in pairs(self._selectors) do
			for _, instance in pairs(selector:fetch()) do
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
