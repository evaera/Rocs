local Rocs = require(path.to.rocs.instance)

local component = Rocs:registerComponent({
	name = "Collectible";
})

local event = game:GetService("RunService").Heartbeat
local rand = Random.new()

local query = Rocs.query:all(
	Rocs.query:hasComponent(component)
)

local near = Rocs.query:all(
	Rocs.query:hasComponent(component),
	Rocs.query:hasComponent("LOD_Near")
)

return {
	{
		name = "Collectibles";
		phases = {};
		origins = {};
	},
	{
		query:onAdded(function(e, system)
			system.phases[e.entity.instance] = rand:NextNumber(0, math.pi)
			system.origins[e.entity.instance] = e.entity.instance.CFrame
		end),

		query:onRemoved(function(e, system)
			system.phases[e.entity.instance] = nil
			system.origins[e.entity.instance] = nil
		end),

		near:onEvent(
			event,
			function(system, _)
				for entity in near:entities() do
					local phase = system.phases[entity.instance]
					local origin = system.origins[entity.instance]
					entity.instance.CFrame = origin + Vector3.new(0, math.sin(tick() + phase), 0)
				end
			end
		)
	}
}
