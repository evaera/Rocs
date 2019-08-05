local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local IS_SERVER = RunService:IsServer()
local EVENT_NAME = "RocsEvent"
local EVENT_NAME_INIT = "RocsInitial"
local inspect = require(script.Parent.Parent.Inspect).inspect

local Replicator = {}
Replicator.__index = Replicator

local function identity(...)
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

function Replicator.new(rocs)
	local self = {
		rocs = rocs;
		_serializers = {};
		_deserializers = {};
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

		self._component = rocs:registerComponent({
			name = "Replicated";
			reducer = rocs.reducers.last;
			onParentUpdated = function(replicated)
				local aggregate = replicated.instance

				local serializedTarget = self:_serialize(aggregate.instance)

				if replicated.data == true then
					for _, player in pairs(Players:GetPlayers()) do
						self:_replicate(
							player,
							aggregate.name,
							serializedTarget,
							aggregate.data
						)
					end
				else
					--[[
						mask: Structure of parent with trues being replicated
						players: List of players to replicate this to
					]]
					error("Replication masks are unimplmented")
				end
			end;

			Players.PlayerAdded:Connect(function(player)
				local payload = {}

				for _, replicated in ipairs(rocs:getComponents(self._component)) do
					local aggregate = replicated.instance
					table.insert(payload, {
						target = self:_serialize(aggregate.instance);
						data = aggregate.data;
						component = aggregate.name;
					})
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

			local entity = self.rocs:getEntity(instance, "_remote", self.rocs.Internal)

			entity:addComponent(entry.component, entry.data)
		else
			warn(("Missing target from payload, does the client have access to this instance? \n\n %s"):format(inspect(entry)))
		end
	end
end

function Replicator:_deserialize(serializedTarget)
	if typeof(serializedTarget) == "Instance" then
		return serializedTarget
	end

	local deserializer = self._deserializers[serializedTarget.name]
	if not deserializer then
		error("Unable to deserialize object") -- TODO: Dump inspect of object
	end

	local object = deserializer(serializedTarget)

	return object or error("Deserialization failed for object")
end

function Replicator:_serialize(object)
	local serializer =
		typeof(object) == "Instance"
			and identity
			or self:findSerializer(object)

	return serializer and serializer(object) or error(("Unable to serialize replicated component %s"):format(object))
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

function Replicator:registerDeserializer(class, callback)
	self._deserializers[class] = callback
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

function Replicator:findDeserializer(class)
	return find(class, self._deserializers)
end

return Replicator
