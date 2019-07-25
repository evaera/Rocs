local BaseSelector = require(script.Parent.BaseSelector)

local ComponentSelector = setmetatable({}, BaseSelector)
ComponentSelector.__index = ComponentSelector

function ComponentSelector.new(rocs, componentResolvable)
	return setmetatable(BaseSelector.new(rocs), ComponentSelector)
end

function ComponentSelector:register(componentResolvable)
	self.componentResolvable = componentResolvable

	self.rocs:registerComponentHook(
		self.componentResolvable,
		"onAdded",
		function(...)
			self:_trigger("onAdded", ...)
		end
	)

	self.rocs:registerComponentHook(
		self.componentResolvable,
		"onRemoved",
		function(...)
			self:_trigger("onRemoved", ...)
		end
	)

	self.rocs:registerComponentHook(
		self.componentResolvable,
		"onUpdated",
		function(...)
			self:_trigger("onUpdated", ...)
		end
	)

	self.rocs:registerComponentHook(
		self.componentResolvable,
		"onParentUpdated",
		function(...)
			self:_trigger("onParentUpdated", ...)
		end
	)
end

function ComponentSelector:check(entity)
	return entity:getComponent(self.componentResolvable)
end

return ComponentSelector
