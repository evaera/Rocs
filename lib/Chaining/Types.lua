local t = require(script.Parent.Parent.Shared.t)

local section = t.map(
	t.string,
	t.array(
		t.interface({
			event = t.string;
			target = t.Instance;
			component = t.string;
			call = t.intersection(t.string, function(value)
				return value:sub(1, 1) ~= "_", "Called method names cannot begin with _"
			end)
		})
	)
)

local module = t.interface({
	server = t.optional(section),
	client = t.optional(section),
	shared = t.optional(section)
})

return {
	module = module;
	section = section;
}
