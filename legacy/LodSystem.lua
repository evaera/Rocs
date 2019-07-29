local Rocs = require(path.to.rocs.instance)

local THRESHOLD = 350

local componentBase = Rocs:registerComponent({
	name = "LOD";
})

local componentNear = Rocs:registerComponent({
	name = "LOD_Near";
})

local event = game:GetService("RunService").Heartbeat
local camera = workspace.CurrentCamera

local query = Rocs.query:hasComponent(componentBase)
local queryNear = Rocs.query:hasComponent(componentNear)

return {
	{
		name = "LOD";
	},
	{
		query:onInterval(5, function()
			for entity in query:entities() do
				if (entity.instance.Position - camera.CFrame.p).magnitude < THRESHOLD then
					entity:addComponent("LOD_Near")
				end
			end
		end),

		queryNear:onAdded(function(system, e)
			print("Entered our vision range: ", e.entity.instance:GetFullName())
		end),

		queryNear:onInterval(0.5, function()
			for entity in queryNear:entities() do
				if (entity.instance.Position - camera.CFrame.p).magnitude > THRESHOLD then
					entity:removeComponent("LOD_Near")
				end
			end
		end)
	}
}
