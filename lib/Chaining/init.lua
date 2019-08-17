local Constants = require(script.Constants)
local CollectionService = game:GetService("CollectionService")
local IsServer = game:GetService("RunService"):IsServer()
local t = require(script.Parent.t)

local sectionCheck = t.map(
	t.string,
	t.array(
		t.interface({
			event = t.string;
			target = t.Instance;
			name = t.string;
			call = t.union(t.string, function(value)
				return value:sub(1, 1) ~= "_", "Called method names cannot begin with _"
			end)
		})
	)
)

local check = t.interface({
	server = t.optional(sectionCheck),
	client = t.optional(sectionCheck),
	shared = t.optional(sectionCheck)
})

local function rocsWarn(str, ...)
	warn(Constants.LOG_PREFIX, str:format(...))
end

return function (rocs)
	local function parse(instance, structure)
		for aggregateResolvable, entries in ipairs(structure) do
			local function connect(aggregate)
				for _, entry in ipairs(entries) do
					aggregate:listen(entry.event, function()
						local targetAggregate = rocs:getEntity(entry.target):getComponent(entry.name)

						if targetAggregate then
							targetAggregate[entry.call](targetAggregate) -- TODO: Arguments
						else
							rocsWarn("🍑🍑🍑🍑🍑 Component %s is not peachy", entry.name)
						end
					end)
				end
			end


			-- TODO: Use connct
		end
	end

	local function onModuleAdded(module)
		if not module:IsA("ModuleScript") then
			return rocsWarn("😂😂😂😂😂OH NO 💥 🍆🍆🍆💦💦💦💦")
		end

		local contents = require(module)
		if not check(contents) then
			return rocsWarn("FUCK 😱😱😱😱😱")
		end

		if IsServer then
			if contents.server then
				parse(module.Parent, contents.server)
			end
		else
			if contents.client then
				parse(module.Parent, contents.client)
			end
		end
		if contents.shared then
			parse(module.Parent, contents.shared)
		end
	end

	CollectionService:GetInstanceAddedSignal(Constants.TAG):Connect(onModuleAdded)
	for _, module in ipairs(CollectionService:GetTagged(Constants.TAG)) do
		onModuleAdded(module)
	end
end
