local BaseSelector = require(script.Parent.BaseSelector)
local Util = require(script.Parent.Util)

local AnySelector = setmetatable({}, BaseSelector)
AnySelector.__index = AnySelector

function AnySelector.new(rocs, ...)
	local self = BaseSelector.new(rocs)
	self = setmetatable(self, AnySelector)

	self.selectors = {}
	self.checks = {}

	for _, property in pairs(...) do
		if typeof(property) == "function" then
			table.insert(self.checks, property)
		else
			local selector = Util.resolve(property)
			table.insert(self.selectors, selector)
			self:_registerHooks(selector)
		end
	end

	return self
end

function AnySelector:_registerHooks(selector)

	selector:onAdded(
		function(entity)
			self:_trigger("onAdded")
		end
	)

	selector:onRemoved(
		function(entity)
			if not self:check(entity) then
				self:_trigger("onRemoved")
			end
		end
	)

	selector:onChanged(
		function(entity)
			self:_trigger("onChanged")
		end
	)

	selector:onParentChanged(
		function(entity)
			self:_trigger("onParentChanged")
		end
	)

end

function AnySelector:check(entity)
	for _, check in pairs(self.checks) do
		if check(entity) then
			return true
		end
	end
	for _, selector in pairs(self.selectors) do
		if selector:check(entity) then
			return true
		end
	end
	return false
end

return AnySelector
