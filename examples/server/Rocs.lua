local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Rocs = require(ReplicatedStorage:WaitForChild("Rocs"))

local rocs = Rocs.new()
Rocs.useReplication(rocs)
Rocs.useTags(rocs)
Rocs.useChaining(rocs)

return rocs
