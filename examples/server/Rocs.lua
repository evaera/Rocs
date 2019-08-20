local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RocsRoot = ReplicatedStorage:WaitForChild("Rocs")
local Rocs = require(RocsRoot)
local useReplication = require(RocsRoot.Replication)
local useChaining = require(RocsRoot.Chaining)

local rocs = Rocs.new()
useReplication(rocs)

spawn(function()
	useChaining(rocs)
end)

return rocs
