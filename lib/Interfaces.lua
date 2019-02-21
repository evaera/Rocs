local t = require(script.Parent.t)

local I = {}

I.InitDestroyable = t.interface({
	initialize = t.optional(t.callback);
	destroy = t.optional(t.callback);
})

I.Reducible = t.interface({
	name = t.string;
	reducer = t.optional(t.callback);
	check = t.optional(t.callback);
})

I.ComponentDefinition = t.intersection(I.InitDestroyable, I.Reducible, t.interface({
	tag = t.optional(t.string);
	defaults = t.optional(t.map(t.string, t.any));
}))

I.staticAggregate = t.intersection(t.ComponentDefinition, t.interface({
	new = t.callback;
}))

I.aggregate = t.interface({
	components = t.table;
	data = t.table;
	instance = t.Instance;
})

I.ComponentResolvable = t.union(t.string, t.staticAggregate)

I.SystemDefinition = t.intersection(I.InitDestroyable, t.interface({
	name = t.string;
}))



return I
