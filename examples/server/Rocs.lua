local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RocsRoot = ReplicatedStorage:WaitForChild("Rocs")
local Rocs = require(RocsRoot)
local useReplication = require(RocsRoot.Replication)
local useChaining = require(RocsRoot.Chaining)
local useTags = require(RocsRoot.Tags)

local rocs = Rocs.new()
useReplication(rocs)
useTags(rocs)

spawn(function()
	useChaining(rocs)
end)

return rocs
