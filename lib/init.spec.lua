local t = require(script.Parent.t)
local inspect = require(script.Parent.Inspect).inspect -- luacheck: ignore 211
local Util = require(script.Parent.Util)
local Rocs = require(script.Parent)
local Constants = require(script.Parent.Constants)

local function makeTestCmp(rocs, callCounts)
	callCounts = callCounts or Util.callCounter()

	local reducers = rocs.reducers

	-- TODO: Test onUpdated in components

	return {
		name = "Test";
		initialize = function(self)
			expect(self).to.be.ok()
			callCounts:call("testCmpInit")
		end;
		destroy = function(self)
			expect(self).to.be.ok()
			callCounts:call("testCmpDestroy")
		end;
		defaults = {
			testDefault = 5;
		};
		reducer = reducers.structure({
			nested = reducers.structure({
				value = reducers.last;
			})
		});
		shouldUpdate = rocs.comparators.structure({
			shouldUpdateTest = function() return false end
		});
		check = t.interface({});
		entityCheck = t.union(t.instance("Workspace"), t.instance("DataModel"));
		tag = "Test";
		onUpdated = function()
			callCounts:call("onUpdated")
		end;
	}
end

-- TODO: Test life cycle hooks

return function()
	describe("Components", function()
		local rocs = Rocs.new()
		local callCounts = Util.callCounter()
		local testCmp = makeTestCmp(rocs, callCounts)
		rocs:registerComponent(testCmp)

		local reducers = rocs.reducers
		local mtTest = rocs:registerComponent({
			name = "MtTest";
			reducer = reducers.structure({
				num = reducers.add;
			});
			check = t.interface({
				num = t.number;
			});
			onParentUpdated = function(self)
				callCounts:call("onParentUpdated")
			end
		})

		it("should apply components", function()
			local ent = rocs:getEntity(workspace, "foo")

			expect(callCounts.testCmpInit).to.equal(0)
			ent:addComponent(testCmp, {
				one = 1;
			}, {
				MtTest = {
					num = 1;
				}
			})
			expect(callCounts.testCmpInit).to.equal(1)
			expect(callCounts.onParentUpdated).to.equal(1)
			ent:addBaseComponent("Test", {
				two = 2;
			}, {
				MtTest = {
					num = 2;
				}
			})
			expect(callCounts.onParentUpdated).to.equal(2)

			local cmpAg = rocs._aggregates._entities[workspace] and rocs._aggregates._entities[workspace][testCmp]

			expect(cmpAg).to.be.ok()

			expect(cmpAg.components[Constants.SCOPE_BASE]).to.be.ok()
			expect(cmpAg.components[Constants.SCOPE_BASE].two).to.equal(2)

			expect(cmpAg.components.foo).to.be.ok()
			expect(cmpAg.components.foo.one).to.equal(1)

			expect(cmpAg:get()).to.equal(cmpAg.data)

			expect(cmpAg:get("one")).to.equal(1)
			expect(cmpAg:get("two")).to.equal(2)
			expect(cmpAg:get("testDefault")).to.equal(5)


			local cmpAgEnt = rocs._aggregates._entities[cmpAg][mtTest]

			expect(cmpAgEnt).to.be.ok()

			expect(cmpAgEnt:get("num")).to.equal(3)

			expect(cmpAg:get("three")).to.never.be.ok()
			cmpAg:set("three", 3)
			expect(cmpAg:get("three")).to.equal(3)
			cmpAg:set("three", Rocs.None)
			expect(cmpAg:get("three")).to.never.be.ok()

			expect(tostring(cmpAg)).to.equal("Aggregate(Test)")

			ent:removeComponent(testCmp)
			ent:removeBaseComponent(testCmp)
			expect(callCounts.testCmpDestroy).to.equal(1)
			expect(callCounts.onUpdated).to.equal(3)
			expect(callCounts.onParentUpdated).to.equal(3)
		end)

		it("should allow looping over components", function()
			local entWorkspace = rocs:getEntity(workspace, "foo")
			entWorkspace:addComponent(testCmp)

			local componentArray = rocs:getComponents(testCmp)

			expect(#componentArray).to.equal(1)

			entWorkspace:addBaseComponent(testCmp, {num = 1})
			expect(#componentArray).to.equal(1)

			local entGame = rocs:getEntity(game, "foo")
			entGame:addComponent(testCmp)

			expect(#componentArray).to.equal(2)
		end)
	end)

	-- describe("Systems", function()
	-- 	local rocs = Rocs.new()
	-- 	rocs:registerComponent(makeTestCmp(rocs))

	-- 	it("should fire lifecycle methods", function()
	-- 		local dep = rocs.dependencies:any(
	-- 			rocs.dependencies:all("Test")
	-- 		)

	-- 		local bindable = Instance.new("BindableEvent")
	-- 		local counter = Util.callCounter()
	-- 		local registeredSystem
	-- 		registeredSystem = rocs:registerSystem({
	-- 			name = "test";

	-- 			initialize = function(self)
	-- 				counter:call("initialize")
	-- 				expect(self).to.be.ok()
	-- 			end;

	-- 			destroy = function(self)
	-- 				counter:call("destroy")
	-- 				expect(self).to.be.ok()
	-- 			end;
	-- 		}, {
	-- 			dep:onAdded(function(self, e)
	-- 				expect(getmetatable(self).name).to.equal("test")
	-- 				expect(e.entity.scope).to.equal("system__test")
	-- 				expect(e.components.Test).to.be.ok()
	-- 				expect(e.components.Test:get("one")).to.equal(1)

	-- 				counter:call("added")
	-- 			end);

	-- 			dep:onUpdated(function(self, e)
	-- 				expect(getmetatable(self).name).to.equal("test")
	-- 				expect(e.entity.scope).to.equal("system__test")

	-- 				expect(e.components.Test).to.be.ok()
	-- 				if counter.updated == 0 then
	-- 					expect(e.components.Test:get("one")).to.equal(1)
	-- 				end

	-- 				counter:call("updated")
	-- 			end);

	-- 			dep:onRemoved(function(self, e)
	-- 				expect(getmetatable(self).name).to.equal("test")
	-- 				expect(e.entity.scope).to.equal("system__test")
	-- 				expect(e.components.Test).to.be.ok()
	-- 				expect(e.components.Test:get("one")).to.equal(nil)

	-- 				counter:call("removed")
	-- 			end);

	-- 			dep:onInterval(5, function(system, dt)
	-- 				counter:call("interval")
	-- 			end);

	-- 			dep:onEvent(bindable.Event, function(system, param)
	-- 				expect(getmetatable(system)).to.equal(registeredSystem)
	-- 				expect(param).to.equal("param")
	-- 				counter:call("event")
	-- 			end)
	-- 		})
	-- 		local ent = rocs:getEntity(workspace, "foo")

	-- 		bindable:Fire("foo")
	-- 		expect(counter.event).to.equal(0)

	-- 		expect(dep:entities()()).to.equal(nil)

	-- 		expect(counter.initialize).to.equal(0)
	-- 		ent:addBaseComponent("Test", { one = 1 })
	-- 		expect(counter.initialize).to.equal(1)
	-- 		expect(counter.added).to.equal(1)
	-- 		expect(counter.updated).to.equal(1)

	-- 		ent:getComponent("Test"):set("shouldUpdateTest", 1)

	-- 		-- TODO: Write more tests for entities
	-- 		expect(dep:entities()()).to.equal(ent.instance)

	-- 		expect(counter.event).to.equal(0)
	-- 		bindable:Fire("param")
	-- 		expect(counter.event).to.equal(1)

	-- 		expect(counter.destroy).to.equal(0)
	-- 		ent:removeBaseComponent("Test")
	-- 		expect(counter.destroy).to.equal(1)

	-- 		expect(counter.updated).to.equal(2)
	-- 		expect(counter.removed).to.equal(1)

	-- 		bindable:Fire("bar")
	-- 		expect(counter.event).to.equal(1)

	-- 		expect(counter.interval).to.equal(0)
	-- 	end)
	-- end)

	-- describe("Layers", function()
	-- 	local rocs = Rocs.new()
	-- 	local callCounts = Util.callCounter()
	-- 	local testCmp = makeTestCmp(rocs, callCounts)
	-- 	rocs:registerComponent(testCmp)

	-- 	it("should add and remove components", function()
	-- 		local ent = rocs:getEntity(workspace, "rawr")

	-- 		local layerId = ent:addLayer({
	-- 			[workspace] = {
	-- 				Test = {
	-- 					one = 1
	-- 				}
	-- 			}
	-- 		})

	-- 		local aggregate = ent:getComponent("Test")
	-- 		expect(aggregate:get("one")).to.equal(1)

	-- 		ent:removeLayer(layerId)

	-- 		expect(aggregate:get("one")).to.equal(nil)
	-- 	end)
	-- end)
end
