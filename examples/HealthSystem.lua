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

Rocs.query:all(
	Rocs.query:isEntity(someHumanoid),
	Rocs.query:any(
		Rocs.query:has({
			[Rocs.metadata("_layer")] = Rocs.Exists,
			[Rocs.metadata("tags")] = {
				RemoveOnStun = true
			}
		}),
		Rocs.query:has({

		})
)
):findAll(function(array)
	for _, e in ipairs(array) do
		-- remove component
	end
end)

find --> Variant result, can pass transform
onAdded --> behavior
onInterval --> behavior
onEvent --> behavior

Rocs.query:all(
	......
)

Rocs:match(
	patterns...
)

Rocs:select(
	[entity or entity list],
	patterns...
)




return {
	{
		name = "hello";
	};
	{
		dep:onAdded(function(e, system)
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
