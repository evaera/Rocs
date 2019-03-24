local Rocs = require(path.to.rocs.instance)
local Deps = Rocs.dependencies

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
		onAdded = function(self, e)

		end;
	};

	[all] = {
		onHeartbeat = function(self, e)

		end
	}
}

return HealthRegenSystem
