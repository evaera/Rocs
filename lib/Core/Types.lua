local t = require(script.Parent.Parent.Shared.t)

local Types = {}

Types.LayerDefinition = t.interface({
	name = t.string;
	reducer = t.optional(t.callback);
	check = t.optional(t.callback);
	defaults = t.optional(t.map(t.string, t.any));
	components = t.optional(t.map(t.string, t.any));
	tag = t.optional(t.string);
	pipelineCheck = t.optional(t.union(t.array(t.string), t.callback));
	chainingEvents = t.optional(t.array(t.string));

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
	instance = t.none;

	onAdded = t.optional(t.callback);
	onUpdated = t.optional(t.callback);
	onParentUpdated = t.optional(t.callback);
	onRemoved = t.optional(t.callback);
	shouldUpdate = t.optional(t.callback);
	initialize = t.optional(t.callback);
	destroy = t.optional(t.callback);
})

Types.staticLens = t.intersection(t.LayerDefinition, t.interface({
	new = t.callback;
}))

Types.LayerLens = t.interface({
	components = t.table;
	data = t.table;
	instance = t.Instance;
})

Types.LayerResolvable = t.union(t.string, Types.staticLens)

return Types
