local I = require(script.Parent.Parent.Types)
local Util = require(script.Parent.Parent.Parent.Shared.Util)
local Lens = require(script.Parent.Lens)
local Constants = require(script.Parent.Parent.Constants)

local LensCollection = {}
LensCollection.__index = LensCollection

function LensCollection.new(rocs)
	return setmetatable({
		rocs = rocs;
		_components = {};
		_entities = {};
		_lenses = {};
	}, LensCollection)
end

local function makeArrayPipelineCheck(array)
	return function(instance)
		for _, className in ipairs(array) do
			if instance:IsA(className) then
				return true
			end
		end

		return
			false,
			("Instance type %q is not allowed to have this component!")
				:format(instance.ClassName)
	end
end

function LensCollection.runPipelineCheck(staticLens, instance)
	if staticLens.pipelineCheck == nil then
		return true
	end

	if type(staticLens.pipelineCheck) == "table" then
		staticLens.pipelineCheck = makeArrayPipelineCheck(staticLens.pipelineCheck)
	end

	return staticLens.pipelineCheck(instance)
end

function LensCollection:register(componentDefinition)
	assert(I.LayerDefinition(componentDefinition))
	assert(self._components[componentDefinition.name] == nil, "A component with this name is already registered!")

	setmetatable(componentDefinition, Lens)

	componentDefinition.__index = componentDefinition
	componentDefinition.__tostring = Lens.__tostring
	componentDefinition.rocs = self.rocs

	componentDefinition.new = componentDefinition.new or function()
		return setmetatable({}, componentDefinition)
	end

	self._components[componentDefinition.name] = componentDefinition
	self._components[componentDefinition] = componentDefinition

	return componentDefinition
end

function LensCollection:construct(staticLens, instance)
	local lens = staticLens.new()

	assert(
		getmetatable(lens) == staticLens,
		"Metatable of constructed component lens must be static component lens"
	)

	lens.components = {}
	lens.instance = instance

	self:_dispatchLifecycle(lens, "initialize")

	return lens
end

function LensCollection:deconstruct(lens)
	-- destroy is called in removeLayer for correct timing

	local staticLens = getmetatable(lens)
	self._entities[lens.instance][staticLens] = nil

	local array = self._lenses[staticLens]

	for i, v in ipairs(array) do
		if v == lens then
			table.remove(array, i)
			break
		end
	end

	if #array == 0 then
		self._lenses[staticLens] = nil
	end

	if next(self._entities[lens.instance]) == nil then
		self._entities[lens.instance] = nil
	end

	self:removeAllLayers(lens)
end

function LensCollection:addLayer(instance, staticLens, scope, data, metacomponents)
	if data == nil then
		return self:removeLayer(instance, staticLens, scope), false
	end

	assert(LensCollection.runPipelineCheck(staticLens, instance))

	if self._entities[instance] == nil then
		self._entities[instance] = {}
	end

	if self._lenses[staticLens] == nil then
		self._lenses[staticLens] = {}
	end

	local lens = self._entities[instance][staticLens]
	local isNew = false

	if lens == nil then
		isNew = true
		lens = self:construct(staticLens, instance)
		self._entities[instance][staticLens] = lens

		table.insert(self._lenses[staticLens], lens)
	end

	lens.components[scope] = data

	self:_dispatchLayerChange(lens)

	local pendingParentUpdated = {}

	if isNew and staticLens.components then
		for componentResolvable, metacomponentData in pairs(staticLens.components) do
			local metacomponentstaticLens = self:getStatic(componentResolvable)

			local metacomponentLens = self:addLayer(
				lens,
				metacomponentstaticLens,
				Constants.SCOPE_BASE,
				metacomponentData
			)

			pendingParentUpdated[metacomponentLens] = true
		end
	end

	if metacomponents then
		for componentResolvable, metacomponentData in pairs(metacomponents) do
			local metacomponentstaticLens = self:getStatic(componentResolvable)

			local metacomponentLens, wasNew = self:addLayer(
				lens,
				metacomponentstaticLens,
				scope,
				metacomponentData
			)

			if wasNew then
				pendingParentUpdated[metacomponentLens] = true
			end
		end
	end

	-- De-duplicate onParentUpdated calls in case both tables have same
	for metacomponentLens in pairs(pendingParentUpdated) do
		self:_dispatchLifecycle(
			metacomponentLens,
			Constants.LIFECYCLE_PARENT_UPDATED
		)
	end

	return lens, isNew
end

function LensCollection:removeAllLayers(instance)
	if self._entities[instance] == nil then
		return
	end

	for _, lens in ipairs(self:getAll(instance)) do
		lens.components = {}

		self:deconstruct(lens)

		self:_dispatchLayerChange(lens)

		self:_dispatchLifecycle(lens, "destroy")
	end
end

function LensCollection:removeLayer(instance, staticLens, scope)
	if
		self._entities[instance] == nil
		or self._entities[instance][staticLens] == nil
	then
		return
	end

	local lens = self._entities[instance][staticLens]

	lens.components[scope] = nil

	self:_dispatchLayerChange(lens)

	local shouldDestroy = next(lens.components) == nil
	if shouldDestroy then
		self:deconstruct(lens)
	end

	if shouldDestroy then
		self:_dispatchLifecycle(lens, "destroy")
	end

	-- TODO: Should destroy be deffered to end-of-frame?
end

function LensCollection:getLayer(instance, staticLens, scope)
	if
		self._entities[instance] == nil
		or self._entities[instance][staticLens] == nil
	then
		return
	end

	return self._entities[instance][staticLens].components[scope]
end

function LensCollection:getAll(instance)
	local lenses = {}

	if self._entities[instance] ~= nil then
		for _, lens in pairs(self._entities[instance]) do
			table.insert(lenses, lens)
		end
	end

	return lenses
end

function LensCollection:get(instance, staticLens)
	return
		self._entities[instance]
		and self._entities[instance][staticLens]
end

function LensCollection:getStatic(componentResolvable)
	return
		self:resolve(componentResolvable)
		or error(("Cannot resolve component %s"):format(componentResolvable))
end

function LensCollection:resolve(componentResolvable)
	return self._components[componentResolvable]
		or (
			type(componentResolvable) == "table"
			and getmetatable(componentResolvable) == Lens
			and componentResolvable
		)
end

function LensCollection:reduce(lens)
	if next(lens.components) == nil then
		return
	end

	local values = { lens.components[Constants.SCOPE_REMOTE] }
	table.insert(values, lens.components[Constants.SCOPE_BASE])

	for name, component in pairs(lens.components) do
		if Constants.RESERVED_SCOPES[name] == nil then
			table.insert(values, component)
		end
	end

	local staticLens = getmetatable(lens)

	local reducedValue = (staticLens.reducer or self.rocs.reducers.default)(values)

	local data = reducedValue
	if staticLens.defaults and type(reducedValue) == "table" then
		staticLens.defaults.__index = staticLens.defaults
		data = setmetatable(
			reducedValue,
			staticLens.defaults
		)
	end

	if staticLens.check then
		assert(staticLens.check(data))
	end

	return data
end

function LensCollection:_dispatchLifecycle(lens, stage)
	lens:dispatch(stage)

	self.rocs:_dispatchLifecycle(lens, stage)
end

function LensCollection:_dispatchLayerChange(lens)
	local lastData = lens.data
	local newData = self:reduce(lens)

	lens.data = newData
	lens.lastData = lastData

	if lastData == nil and newData ~= nil then
		self:_dispatchLifecycle(lens, Constants.LIFECYCLE_ADDED)
	end

	local staticLens = getmetatable(lens)

	if (staticLens.shouldUpdate or self.rocs.comparators.default)(newData, lastData) then
		self:_dispatchLifecycle(lens, Constants.LIFECYCLE_UPDATED)

		local childLenss = self:getAll(lens)
		for _, childLens in ipairs(childLenss) do
			self:_dispatchLifecycle(
				childLens,
				Constants.LIFECYCLE_PARENT_UPDATED
			)
		end
	end

	if newData == nil then
		self:_dispatchLifecycle(lens, Constants.LIFECYCLE_REMOVED)
	end

	lens.lastData = nil
end

return LensCollection
