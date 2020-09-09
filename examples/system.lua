local rocs = require(...)
-- ...

local system = rocs.system("Example", rocs.selectors.all("Health", "Regen"))

local entities = system:get() -- all entities with "Health" AND "Regen"
local lenses = system:lenses() -- all "Health" and all "Regen" lenses that are on an pipeline that also has the other

for _, lens in pairs(lenses) do
	-- use case?
	if lens.type == "Health" then
		-- what do
	elseif lens.type == "Regen" then

	end
end

-------

local system = rocs.system("Example", rocs.selectors.all(rocs.selectors.has("Health", {Value = 50}), "Regen"))

local entities = system:get() -- all entities with "Health" (with Value = 50) AND "Regen"
local lenses = system:lenses() --

-------

local system = rocs.system("Example", rocs.selectors.any("Health", "Regen"))


local data = system:get() -- all entities with "Health" (with Value = 50) AND "Regen"
--[[
	data = {
		[lensName] = {
			... lenses ...
		},
		...
	}

	data = {
		[pipeline] = {
			lensName = lenses,
			...
		},
		...
	}

	for pipeline in pairs(data) do

	for pipeline, lenses in pairs(data) do

	end
]]

local entities = system:getEntities() --> { ... entities ... }
local lenses = system:getLenss() --> { ... lenses ... }
local pipelineMapping = system:get() --> data

--[[
	rocs.selectors.all(X, Y) --> get the entities, return X and Y from each pipeline
	rocs.selectors.any(X, Y) --> get the entities, return every single X and Y that occurs on whatever pipeline in that list
	rocs.selectors.has(X, props, metas) -->
	<custom function> --> nothing
]]
