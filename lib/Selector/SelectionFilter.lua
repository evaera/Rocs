Rocs.system( -- {workspace, game}
	Rocs.selectors.all(
		Rocs.selectors.any(...), :onAdded/:onRemoved/:check/:onChanged
		Rocs.selectors.any(...)
	),
	"Health"
)

Rocs.get(
	Rocs.selectors.all(
		Rocs.selectors.any(...), :onAdded/:onRemoved/:check/:onChanged
		Rocs.selectors.any(...)
	),
	"Health"
)

Rocs.select(
	"Health",
	"Regen"
)

local selector = Rocs.select(
	Rocs.selectors.hascomponent(
		"Health",
		{
			Value = Rocs.selector.geq(50) -- 55 --> 60
		},
		{
			Replicated = true
		}
	)
)

:onAdded

:onRemoved

:onEvent(Heartbeat, function(self, ...)
	
end)