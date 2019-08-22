local types = require(script.Parent.Types)
local Constants = require(script.Parent.Constants)
local CollectionService = game:GetService("CollectionService")
local IS_SERVER = game:GetService("RunService"):IsServer()

local Chainer = {}
Chainer.__index = Chainer

function Chainer.new(rocs)
	local self = setmetatable({
		rocs = rocs
	}, Chainer)

	local tagName = self:getTagName()
	CollectionService:GetInstanceAddedSignal(tagName):Connect(function(...)
		self:_handleModule(...)
	end)

	for _, module in ipairs(CollectionService:GetTagged(tagName)) do
		self:_handleModule(module)
	end

	return self
end

function Chainer:getTagName()
	return Constants.TAG:format(self.rocs.name)
end

function Chainer:warn(text, ...)
	return self.rocs:warn("[Chaining] " .. text, ...)
end

function Chainer:_handleModule(module)
	if not module:IsA("ModuleScript") then
		return self:warn("%s is not a ModuleScript!", module)
	end

	local contents = require(module)

	local isValid, typeError = types.module(contents)
	if not isValid then
		self:warn("Invalid chaining configuration:\n\n%s", typeError)
	end

	local function chain(section)
		if contents[section] then
			self:chain(module.Parent, contents[section])
		end
	end

	if IS_SERVER then
		chain("server")
	else
		chain("client")
	end

	chain("shared")
end

function Chainer:_connect(aggregate, entries)
	for _, entry in ipairs(entries) do
		aggregate:listen(entry.event, function()
			local targetAggregate = self.rocs:getEntity(entry.target, "chaining"):getComponent(entry.component)

			if targetAggregate then
				targetAggregate[entry.call](targetAggregate) -- TODO: Arguments
			else
				self:warn(
					"Component %s is missing from %s which is needed for a component chain!",
					entry.component,
					entry.target
				)
			end
		end)
	end
end

function Chainer:_chainAggregate(sourceInstance, staticAggregate, entries)
	local entity = self.rocs:getEntity(sourceInstance, "chaining")

	local currentAggregate = entity:getComponent(staticAggregate)
	if currentAggregate then
		self:_connect(currentAggregate, entries)
	end

	self.rocs:registerEntityComponentHook(
		sourceInstance,
		staticAggregate,
		"initialize",
		function (aggregate)
			self:_connect(aggregate, entries)
		end
	)

	if staticAggregate.chainingEvents == nil then
		self:warn("chainingEvents array is missing from component %s! Please list all chainable events upon registration.", staticAggregate)
	end
end

function Chainer:chain(sourceInstance, structure)
	for componentResolvable, entries in pairs(structure) do
		local staticAggregate = self.rocs:resolveAggregate(componentResolvable)

		if staticAggregate then
			self:_chainAggregate(sourceInstance, staticAggregate, entries)
		else
			self:warn("Could not resolve component %s in chaining configuration for %s", componentResolvable, sourceInstance)
		end
	end
end

return Chainer
