local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local function server(rocs, remoteEvent)

	local dep = rocs.dependencies:hasMetadata(rocs.metadata("replicated"))

	Players.PlayerAdded:Connect(function(player)
		-- TODO: replicate existing replicated components to player


		for _, v in dep:entities() do
			-- ...
		end


		remoteEvent:FireClient(player, "some thing here")
	end)

	rocs:registerSystem({
		name = "Replication"
	},
	{
		dep:onUpdated(function(_, e)
			if typeof(e.entity.instance) ~= "Instance" then
				return
			end

			local mask = e.data[rocs.metadata("replicated")]

			-- remove previous registration if present

			-- add registration:
			-- whenever a property changes on the entity
				-- check if property is replicated?
					-- send to everyone / all players
		end)
	})

end

local function client(rocs, remoteEvent)




end

return function(rocs)
	local remoteName = "RocsRemote_" .. rocs.name
	local remoteEvent

	if RunService:IsClient() then
		remoteEvent = ReplicatedStorage:WaitForChild(remoteName)

		client(rocs, remoteEvent)
	else
		remoteEvent = ReplicatedStorage:FindFirstChild(remoteName)
		if not remoteEvent then
			remoteEvent = Instance.new("RemoteEvent")
			remoteEvent.Name = remoteName
			remoteEvent.Parent = ReplicatedStorage
		end

		server(rocs, remoteEvent)
	end
end
