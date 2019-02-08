local Rocs = require(path.to.rocs.instance)
local Deps = Rocs:getDependencyFactory()

local dep = Deps:all(
	"Health",
	Deps:any(
		"Regen",
		Rocs.metadata("Replicated")
	)
)

local all = Deps:all("Health", "Regen", Rocs.metadata("Replicated"))

local HealthRegenSystem = {
	name = "HealthRegen";

	[dep] = {
		onAdded = function(self, entity, components)

		end
	};

	[all] = {
		onHeartbeat = function(self, entity, components)

		end
	}
}

return HealthRegenSystem
