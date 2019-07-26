local BaseSelector = require(script.Parent.BaseSelector)
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

function AllSelector:instances()
	local instances = {}

	if #self._selectors > 0 then
		-- get first selection of entities
		for _, entity in pairs(self._selectors[1]:instances()) do
			instances[entity] = true
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

function AllSelector:check(instance)
	for _, check in pairs(self._checks) do
		if not check(instance) then
			return false
		end
	end

	for _, selector in pairs(self._selectors) do
		if not selector:check(instance) then
			return false
		end
	end

	return true
end

return AllSelector
