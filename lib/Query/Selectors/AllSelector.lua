local BaseSelector = require(script.Parent.BaseSelector)
local Util = require(script.Parent.Util)

local AllSelector = setmetatable({}, BaseSelector)
AllSelector.__index = AllSelector

function AllSelector.new(rocs, ...)
	local self = setmetatable(BaseSelector.new(rocs), AllSelector)

	self._checks = {}
	for _, property in pairs(...) do
		if type(property) == "function" then
			table.insert(self._checks, property)
		else
			table.insert(self._selectors, Util.resolve(rocs, property))
		end
	end

	return self
end

function AllSelector:_listen()
	for _, selector in pairs(self._selectors) do
		selector:onAdded(
			function(lens)
				local instance = lens.instance
				if not self._lookup[instance] and self:check(instance, selector) then
					self._lookup[instance] = true
					self:_trigger("onAdded", lens)
				end
			end
		)

		selector:onRemoved(
			function(lens)
				local instance = lens.instance
				if self._lookup[instance] then
					self._lookup[instance] = nil
					self:_trigger("onRemoved", lens)
				end
			end
		)

		selector:onUpdated(
			function(lens)
				local instance = lens.instance
				if self._lookup[instance] then
					if self:check(instance, selector) then
						self:_trigger("onUpdated", lens)
					else
						self._lookup[instance] = nil
						self:_trigger("onRemoved", lens)
					end
				else
					if self:check(instance, selector) then
						self._lookup[instance] = true
						self:_trigger("onAdded", lens)
					else
						self:_trigger("onUpdated", lens)
					end
				end
			end
		)

		-- TODO: is this right?
		selector:onParentUpdated(
			function(lens)
				if self._lookup[lens.instance] then
					self:_trigger("onParentUpdated", lens)
				end
			end
		)
	end
end

function AllSelector:instances()
	local instances = {}

	if #self._selectors > 0 then
		-- get first selection of entities
		for _, instance in pairs(self._selectors[1]:fetch()) do
			instances[instance] = true
		end

		-- filter the ones out that don't match function checks
		for _, check in pairs(self._checks) do
			for instance in pairs(instances) do
				if not check(instance) then
					instances[instance] = nil
				end
			end
		end

		-- filter the ones out that don't match other selectors
		for i = 2, #self._selectors do
			local selector = self._selectors[i]
			for instance in pairs(instances) do
				if not selector:check(instance) then
					instances[instance] = nil
				end
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

function AllSelector:check(instance, exceptSelector)
	for _, check in pairs(self._checks) do
		if not check(instance) then
			return false
		end
	end

	for _, selector in pairs(self._selectors) do
		if exceptSelector ~= selector and not selector:check(instance) then
			return false
		end
	end

	return true
end

return AllSelector
