local BaseSelector = require(script.Parent.BaseSelector)
local ComponentSelector = require(script.Parent.ComponentSelector)
local Util = require(script.Parent.Util)

local AllSelector = setmetatable({}, BaseSelector)
AllSelector.__index = AllSelector

function AllSelector.new(rocs, ...)
	local self = setmetatable(BaseSelector.new(rocs), AllSelector)

	self._selectors = {}
	self._checks = {}
	for _, property in pairs(...) do
		if type(property) == "function" then
			table.insert(self._checks, property)
		else
			table.insert(self._selectors, Util.resolve(property))
		end
	end

	return self
end

function AllSelector:setup()
	if self._ready then
		return
	end
	self._ready = true

	for _, selector in pairs(self._selectors) do
		selector:setup()

		selector:onAdded(
			function(aggregate, ...)
				local entity = self._rocs:getEntity(aggregate.instance)
				if self:check(entity) then
					self:_trigger("onAdded", aggregate, ...)
				end
			end
		)

		selector:onRemoved(
			function(...)
				self:_trigger("onRemoved", ...)
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

function AllSelector:get()
	local cache = {}

	if #self._selectors > 0 then
		-- get first selection of entities
		for _, entity in pairs(self._selectors[1]:get()) do
			cache[entity] = true
		end

		-- filter the ones out that don't match function checks
		for _, check in pairs(self._checks) do
			for entity in pairs(cache) do
				if not check(entity) then
					cache[entity] = nil
				end
			end
		end

		-- filter the ones out that don't match other selectors
		for i = 2, #self._selectors do
			local selector = self._selectors[i]
			for entity in pairs(cache) do
				if not selector:check(entity) then
					cache[entity] = nil
				end
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

function AllSelector:check(entity)
	for _, check in pairs(self._checks) do
		if not check(entity) then
			return false
		end
	end

	for _, selector in pairs(self._selectors) do
		if not selector:check(entity) then
			return false
		end
	end

	return true
end

return AllSelector
