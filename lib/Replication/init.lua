local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local IS_SERVER = RunService:IsServer()
local EVENT

return function (rocs)
	if IS_SERVER then
		EVENT = ReplicatedStorage:FindFirstChild("RocsEvent")

		if not EVENT then
			EVENT = Instance.new("RemoteEvent")
			EVENT.Name = "RocsEvent"
			EVENT.Parent = ReplicatedStorage
		end
	else
		EVENT = ReplicatedStorage:WaitForChild("RocsEvent")
	end
end
