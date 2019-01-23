local t = require(script.Parent.t)

local I = {}

I.System = t.interface({
	name = t.string;
	dependencies = t.array(
		t.union(t.array(t.any))
	)
})

I.ComponentDefinition = t.interface({
	name = t.string;
	reducer = t.optional(t.callback);
	check = t.optional(t.callback);
})

return I
