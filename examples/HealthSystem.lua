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
		dep:onAdded(function()

		end),

		dep:onInterval(20, function()

		end),

		dep:onEvent(RunService.Stepped, function()

		end)
	}
}
