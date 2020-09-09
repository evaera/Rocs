local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BuiltInSerializers = require(script.Parent.BuiltInSerializers)
local Util = require(script.Parent.Util)

local IS_SERVER = RunService:IsServer()
local EVENT_NAME = "RocsEvent"
local EVENT_NAME_INIT = "RocsInitial"
local inspect = require(script.Parent.Parent.Shared.Inspect)

local Replicator = {}
Replicator.__index = Replicator

local function idpipeline(...)
	return ...
end

local function getOrCreate(parent, name, class)
	local instance = parent:FindFirstChild(name)

	if not instance then
		instance = Instance.new(class)
		instance.Name = name
		instance.Parent = parent
	end

	return instance
end

local function getData(data, replicated, player)
	return
		replicated and (
			replicated.playerMasks
			and replicated.playerMasks[player]
			and Util.clipMask(data, replicated.playerMasks[player])
			or replicated.mask
			and Util.clipMask(data, replicated.mask)
		) or data
end

function Replicator.new(rocs)
	local self = {
		rocs = rocs;
		_serializers = setmetatable({}, BuiltInSerializers.serializers);
		_deserializers = setmetatable({}, BuiltInSerializers.deserializers);
	}

	if IS_SERVER then
		self._event = getOrCreate(
			ReplicatedStorage,
			EVENT_NAME,
			"RemoteEvent"
		)

		self._eventInit = getOrCreate(
			ReplicatedStorage,
			EVENT_NAME_INIT,
			"RemoteEvent"
		)

		self._component = rocs:registerLayer({
			name = "Replicated";
			reducer = rocs.reducers.structure({
				players = rocs.reducers.concatArray;
				mask = rocs.reducers.mergeTable;
				playerMasks = rocs.reducers.mergeTable;
			});
			check = function(value)
				return type(value) == "table"
			end;
			onUpdated = function(replicated)
				replicated:dispatch("onParentUpdated", true)
			end;
			onParentUpdated = function(replicated, fromSelf)
				local lens = replicated.instance

				local serializedTarget = self:_serialize(lens.instance)

				local shouldBroadcast =
					not fromSelf
					or rocs.comparators.value(
						replicated.data and replicated.data.mask,
						replicated.lastData and replicated.lastData.mask
					)
					or rocs.comparators.value(
						replicated.data and replicated.data.playerMasks,
						replicated.lastData and replicated.lastData.playerMasks
					)

				local removedPlayers = {}
				local players
				if
					replicated.data
					and replicated.lastData
					and replicated.data.players
					and replicated.lastData.players
				then
					for _, player in ipairs(replicated.lastData.players) do
						if Util.find(replicated.data.players, player) == nil then
							removedPlayers = removedPlayers

							table.insert(removedPlayers, player)
						end
					end

					if not shouldBroadcast then
						for _, player in ipairs(replicated.data.players) do
							if Util.find(replicated.lastData.players) == nil then
								players = players or {}

								table.insert(players, player)
							end
						end
					end
				end

				players = players or (replicated.data and replicated.data.players) or Players:GetPlayers()

				for _, player in ipairs(players) do
					self:_replicate(
						player,
						lens.name,
						serializedTarget,
						getData(lens.data, replicated.data, player)
					)
				end

				for _, player in ipairs(removedPlayers) do
					self:_replicate(
						player,
						lens.name,
						serializedTarget,
						nil
					)
				end
			end;

			Players.PlayerAdded:Connect(function(player)
				local payload = {}

				for _, replicated in ipairs(rocs:getLayers(self._component)) do
					-- Only do this because if the player is added to an exclusive
					-- one, they'll be gotten in the onUpdated
					if replicated.data.players == nil then
						local lens = replicated.instance
						table.insert(payload, {
							target = self:_serialize(lens.instance);
							data = getData(lens.data, replicated.data, player);
							component = lens.name;
						})
					end
				end

				self:_replicatePayload(player, payload, self._eventInit)
			end)
		})
	else
		self._event = ReplicatedStorage:WaitForChild(EVENT_NAME)
		self._eventInit = ReplicatedStorage:WaitForChild(EVENT_NAME_INIT)

		local function handleEvent(rocsName, payload)
			if rocsName ~= self.rocs.name then
				return
			end

			self:_reifyPayload(payload)
		end

		-- Delay until later to allow registration to complete
		spawn(function()
			handleEvent(self._eventInit.OnClientEvent:Wait())
			self._event.OnClientEvent:Connect(handleEvent)
		end)
	end

	return setmetatable(self, Replicator)
end

function Replicator:_reifyPayload(payload)
	for _, entry in ipairs(payload) do

		if entry.target then
			local instance = self:_deserialize(entry.target)

			local pipeline = self.rocs:getPipeline(instance, "_remote", self.rocs.Internal)

			pipeline:addLayer(entry.component, entry.data)
		else
			warn(("Missing target from payload, does the client have access to this instance? \n\n %s"):format(inspect(entry)))
		end
	end
end

function Replicator:_deserialize(serializedTarget)
	if typeof(serializedTarget) == "Instance" then
		return serializedTarget
	end

	local deserializer = self._deserializers[serializedTarget.type]
	if not deserializer then
		error("Unable to deserialize object") -- TODO: Dump inspect of object
	end

	local object = deserializer(serializedTarget, self.rocs)

	return object or error("Deserialization failed for object")
end

function Replicator:_serialize(object)
	local serializer =
		typeof(object) == "Instance"
			and idpipeline
			or self:findSerializer(object)

	return
		serializer and serializer(object, self.rocs)
		or error(("Unable to serialize replicated component %s"):format(object))
end

function Replicator:_replicate(player, component, target, data)
	return self:_replicatePayload(player, {{
		target = target;
		data = data;
		component = component;
	}})
end

function Replicator:_replicatePayload(player, payload, eventOverride)
	(eventOverride or self._event):FireClient(player, self.rocs.name, payload)
end

function Replicator:registerSerializer(class, callback)
	self._serializers[class] = callback
end

function Replicator:registerDeserializer(name, callback)
	assert(type(name) == "string", "Deserializer type must be a string")
	self._deserializers[name] = callback
end

local function find(class, map)
	if map[class] then
		return map[class]
	end

	local metatable = getmetatable(class)

	if metatable then
		return find(metatable, map)
	end
end

function Replicator:findSerializer(class)
	return find(class, self._serializers)
end

function Replicator:findDeserializer(name)
	return self._deserializers[name]
end

return Replicator
