local rocs = require(...)
-- ...

local system = rocs.system("Example", rocs.selectors.all("Health", "Regen"))

local entities = system:get() -- all entities with "Health" AND "Regen"
local aggregates = system:aggregates() -- all "Health" and all "Regen" aggregates that are on an entity that also has the other

for _, aggregate in pairs(aggregates) do
	-- use case?
	if aggregate.type == "Health" then
		-- what do
	elseif aggregate.type == "Regen" then

	end
end

-------

local system = rocs.system("Example", rocs.selectors.all(rocs.selectors.has("Health", {Value = 50}), "Regen"))

local entities = system:get() -- all entities with "Health" (with Value = 50) AND "Regen"
local aggregates = system:aggregates() --

-------

local system = rocs.system("Example", rocs.selectors.any("Health", "Regen"))


local data = system:get() -- all entities with "Health" (with Value = 50) AND "Regen"
--[[
	data = {
		[aggregateName] = {
			... aggregates ...
		},
		...
	}

	data = {
		[entity] = {
			aggregateName = aggregates,
			...
		},
		...
	}

	for entity in pairs(data) do

	for entity, aggregates in pairs(data) do

	end
]]

local entities = system:getEntities() --> { ... entities ... }
local aggregates = system:getAggregates() --> { ... aggregates ... }
local entityMapping = system:get() --> data

--[[
	rocs.selectors.all(X, Y) --> get the entities, return X and Y from each entity
	rocs.selectors.any(X, Y) --> get the entities, return every single X and Y that occurs on whatever entity in that list
	rocs.selectors.has(X, props, metas) -->
	<custom function> --> nothing
]]
