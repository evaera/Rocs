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
	defaults = t.optional(t.map(t.string, t.any));
	components = t.optional(t.map(t.string, t.any));
})

I.ComponentDefinition = t.intersection(I.InitDestroyable, I.Reducible, t.interface({
	tag = t.optional(t.string);
	entityCheck = t.optional(t.union(t.array(t.string), t.callback));
	data = t.none;
	lastData = t.none;
	set = t.none;
	get = t.none;
	getOr = t.none;
	getAnd = t.none;
	dispatch = t.none;
	listen = t.none;
	removeListener = t.none;
	_listeners = t.none;
	onAdded = t.optional(t.callback);
	onUpdated = t.optional(t.callback);
	onParentUpdated = t.optional(t.callback);
	onRemoved = t.optional(t.callback);
	shouldUpdate = t.optional(t.callback);
}))

I.StaticAggregate = t.intersection(t.ComponentDefinition, t.interface({
	new = t.callback;
}))

I.ComponentAggregate = t.interface({
	components = t.table;
	data = t.table;
	instance = t.Instance;
})

I.ComponentResolvable = t.union(t.string, I.StaticAggregate)

return I
