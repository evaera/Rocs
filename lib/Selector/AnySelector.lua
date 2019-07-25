local BaseSelector = require(script.Parent.BaseSelector)
local Util = require(script.Parent.Util)

local AnySelector = setmetatable({}, BaseSelector)
AnySelector.__index = AnySelector

function AnySelector.new(rocs, ...)
	local self = setmetatable(BaseSelector.new(rocs), AnySelector)

	self._selectors = {}
	for _, property in pairs(...) do
		if type(property) == "function" then
			error("Cannot have check functions in selectors.any", 2)
		else
			table.insert(self._selectors, Util.resolve(property))
		end
	end

	return self
end

function AnySelector:setup()
	if self._ready then
		return
	end
	self._ready = true

	for _, selector in pairs(self._selectors) do
		selector:setup()

		selector:onAdded(
			function(...)
				self:_trigger("onAdded", ...)
			end
		)

		selector:onRemoved(
			function(entity, ...)
				if not self:check(entity) then
					self:_trigger("onRemoved", entity, ...)
				end
			end
		)

		selector:onChanged(
			function(...)
				self:_trigger("onChanged", ...)
			end
		)

		selector:onParentChanged(
			function(...)
				self:_trigger("onParentChanged", ...)
			end
		)
	end

	return self
end

function AnySelector:get()
	local cache = {}

	if #self._selectors > 0 then
		-- accumulate entities into cache, only-once
		for _, selector in pairs(self._selectors) do
			for _, entity in pairs(selector:get()) do
				cache[entity] = true
			end
		end

		-- turn lookup into array
		for entity in pairs(cache) do
			table.insert(cache, entity)
			cache[entity] = nil
		end
	end

	return cache
end

function AnySelector:check(entity)
	for _, selector in pairs(self._selectors) do
		if selector:check(entity) then
			return true
		end
	end

	return false
end

return AnySelector
