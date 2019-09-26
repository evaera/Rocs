local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Rocs = require(ReplicatedStorage:WaitForChild("Rocs"))

local rocs = Rocs.new()
Rocs.useReplication(rocs)

return rocs
