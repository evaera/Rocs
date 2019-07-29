local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RocsRoot = ReplicatedStorage:WaitForChild("Rocs")
local Rocs = require(RocsRoot)
local useReplication = require(RocsRoot.Replication)

local rocs = Rocs.new()
useReplication(rocs)

return rocs
