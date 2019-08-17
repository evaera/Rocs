--[[
	Instance
		ModuleScript (CollectionService tag: "__RocsChain")
			return {
				["server"|"client"|"shared"] = {
					<aggregateName> = {
						{
							event = <string eventName>,
							target = <Instance target>,
							name = <string aggregateName>,
							call = <string methodName>,
						}
					}
				},
				[...] = {
					...
				},
				...
			}
]]

rocs = ...

local function registerServer(entries)
	for name, entry in ipairs(entries) do
		-- if both aggregates already exist, do the binding
		-- if one of the two is removed, removeListener
		-- if one of the two is added, check if should bind
			-- if so do binding
	end
end




rocs.registerComponent(
	{
		Name = "Test"
	}
)

local rocs = {...}

aggregate1 = ...
aggregate2 = ...

aggregate1:listen("EventName", function(x, y, z) aggregate2:dispatch("ActionName", y, x, z) end)
