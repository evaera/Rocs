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

function Chainer:_connect(lens, entries)
	for _, entry in ipairs(entries) do
		lens:listen(entry.event, function()
			local targetLens = self.rocs:getPipeline(entry.target, "chaining"):getLayer(entry.component)

			if targetLens then
				targetLens[entry.call](targetLens) -- TODO: Arguments
			else
				self:warn(
					"Layer %s is missing from %s which is needed for a component chain!",
					entry.component,
					entry.target
				)
			end
		end)
	end
end

function Chainer:_chainLens(sourceInstance, staticLens, entries)
	local pipeline = self.rocs:getPipeline(sourceInstance, "chaining")

	local currentLens = pipeline:getLayer(staticLens)
	if currentLens then
		self:_connect(currentLens, entries)
	end

	self.rocs:registerPipelineLayerHook(
		sourceInstance,
		staticLens,
		"initialize",
		function (lens)
			self:_connect(lens, entries)
		end
	)

	if staticLens.chainingEvents == nil then
		self:warn("chainingEvents array is missing from component %s! Please list all chainable events upon registration.", staticLens)
	end
end

function Chainer:chain(sourceInstance, structure)
	for componentResolvable, entries in pairs(structure) do
		local staticLens = self.rocs:resolveLens(componentResolvable)

		if staticLens then
			self:_chainLens(sourceInstance, staticLens, entries)
		else
			self:warn("Could not resolve component %s in chaining configuration for %s", componentResolvable, sourceInstance)
		end
	end
end

return Chainer
