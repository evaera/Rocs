local BaseSelector = require(script.Parent.BaseSelector)
local Util = require(script.Parent.Util)

local AllSelector = setmetatable({}, BaseSelector)
AllSelector.__index = AllSelector

function AllSelector.new(rocs)
	return setmetatable(BaseSelector.new(rocs), AllSelector)
end

function AllSelector:register(...)
	for _, property in pairs(...) do
		if typeof(property) == "function" then
			table.insert(self.checks, property)
		else
			local selector = Util.resolve(property)
			table.insert(self.selectors, selector)
			self:_registerHooks(selector)
		end
	end
end

function AllSelector:setup()
	for _, selector in pairs(self.selectors) do
		selector:onAdded(
			function(aggregate, ...)
				local entity = self.rocs:getEntity(aggregate.instance)
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
end

function AllSelector:check(entity)
	for _, selector in pairs(self.selectors) do
		if not selector:check(entity) then
			return false
		end
	end
	return true
end

return AllSelector
