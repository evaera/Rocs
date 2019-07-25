local Rocs = require(path.to.rocs.instance)
local Deps = Rocs.dependencies

local dep = Deps:all(
	"Health",
	Deps:any(
		"Regen",
		Rocs.metadata("Replicated")
	)
)

local all = Deps:all("Health", "Regen")   --, Rocs.metadata("Replicated"))




local selector = Rocs.select(
	Rocs.selectors.all {
		Health = {
			Rocs.selectors.hasmeta("Replicated"),
			Value = Rocs.selector.geq(50)
		},
		 Rocs.selectors.hascomponent(
			"Health",
			{
				Value = Rocs.selector.geq(50)
			},
			{
				Replicated = true
			}
		)
		"Regen",
		Rocs.selectors.any(
			"SuperBigHealth",
			"MiniHealth"
		),
		Rocs.selectors.class("Humanoid"),
		Rocs.selectors.check(function(entity) return Players:GetPlayerFromCharacter(entity.instance.Parent) ~= nil end)
	}
)
local selecto2 = Rocs.selectors.any("Slowdown", "Poison")

selector:onAdded(
	function(entity)
		print("A regenerating unit has appeared: ", entity.instance:GetFullName())
	end
)




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
