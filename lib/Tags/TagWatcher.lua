local CollectionService = game:GetService("CollectionService")

local TagWatcher = {}
TagWatcher.__index = TagWatcher

function TagWatcher.new(rocs)
	local self = setmetatable({
		rocs = rocs;
		_tags = {};
	}, TagWatcher)

	rocs:registerLayerRegistrationHook(function(staticLens)
		if staticLens.tag then
			self:listenForTag(staticLens.tag, staticLens)
		end
	end)

	return self
end

function TagWatcher:listenForTag(tag, staticLens)
	assert(self._tags[tag] == nil, ("Tag %q is already in use!"):format(tag))
	self._tags[tag] = true

	local function addFromTag(instance)
		local data = {}
		if
			instance:FindFirstChild(staticLens.name)
			and instance[staticLens.name].ClassName == "ModuleScript"
		then
			data = require(instance[staticLens.name])
		end

		self.rocs:getPipeline(instance, "tags"):addBaseLayer(staticLens, data)
	end

	local function removeFromTag(instance)
		self.rocs:getPipeline(instance, "tags"):removeBaseLayer(staticLens)
	end

	CollectionService:GetInstanceRemovedSignal(tag):Connect(removeFromTag)
	CollectionService:GetInstanceAddedSignal(tag):Connect(addFromTag)
	for _, instance in ipairs(CollectionService:GetTagged(tag)) do
		addFromTag(instance)
	end
end

return TagWatcher
