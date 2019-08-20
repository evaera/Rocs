local CollectionService = game:GetService("CollectionService")

local TagWatcher = {}
TagWatcher.__index = TagWatcher

function TagWatcher.new(rocs)
	local self = setmetatable({
		rocs = rocs;
		_tags = {};
	}, TagWatcher)

	rocs:registerComponentRegistrationHook(function(staticAggregate)
		if staticAggregate.tag then
			self:listenForTag(staticAggregate.tag, staticAggregate)
		end
	end)

	return self
end

function TagWatcher:listenForTag(tag, staticAggregate)
	assert(self._tags[tag] == nil, ("Tag %q is already in use!"):format(tag))
	self._tags[tag] = true

	local function addFromTag(instance)
		local data = {}
		if
			instance:FindFirstChild(staticAggregate.name)
			and instance[staticAggregate.name].ClassName == "ModuleScript"
		then
			data = require(instance[staticAggregate.name])
		end

		self.rocs:getEntity(instance, "tags"):addBaseComponent(staticAggregate, data)
	end

	local function removeFromTag(instance)
		self.rocs:getEntity(instance, "tags"):removeBaseComponent(staticAggregate)
	end

	CollectionService:GetInstanceRemovedSignal(tag):Connect(removeFromTag)
	CollectionService:GetInstanceAddedSignal(tag):Connect(addFromTag)
	for _, instance in ipairs(CollectionService:GetTagged(tag)) do
		addFromTag(instance)
	end
end

return TagWatcher
