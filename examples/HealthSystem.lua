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

return {
	{
		name = "hello";
	};
	{
		dep:onAdded(function(system, e)
			for entity, components in dep:entities() do
				if components.Regen then
					print(entity .. " has a Regen component omg!!!")
				end
			end
		end),

		dep:onInterval(20, function(system)

		end),

		dep:onEvent(RunService.Stepped, function()

		end)
	}
}
