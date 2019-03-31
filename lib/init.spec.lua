local t = require(script.Parent.t)
local Util = require(script.Parent.Util)
local Rocs = require(script.Parent)

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
			[Rocs.metadata("Replicated")] = true;
			testDefault = 5;
		};
		reducer = reducers.propertyReducer({
			nested = reducers.propertyReducer({
				value = reducers.last;
			})
		});
		check = t.interface({});
		entityCheck = t.instance("Workspace");
		tag = "Test";
	}
end

return function()
	describe("Components", function()
		local rocs = Rocs.new()
		local callCounts = Util.callCounter()
		local testCmp = makeTestCmp(rocs, callCounts)
		rocs:registerComponent(testCmp)

		local reducers = rocs.reducers
		rocs:registerMetadata({
			name = "MtTest";
			reducer = reducers.propertyReducer({
				num = reducers.add;
			});
			check = t.interface({
				num = t.number;
			})
		})

		it("should apply components", function()
			local ent = rocs:getEntity(workspace, "foo")

			expect(callCounts.testCmpInit).to.equal(0)
			ent:addComponent(testCmp, {
				one = 1;
				[Rocs.metadata("MtTest")] = {
					num = 2;
				}
			})
			expect(callCounts.testCmpInit).to.equal(1)
			ent:addBaseComponent("Test", {
				two = 2;
				[Rocs.metadata("MtTest")] = {
					num = 1;
				}
			})

			local cmpAg = rocs._entities[workspace] and rocs._entities[workspace][testCmp]

			expect(cmpAg).to.be.ok()

			expect(cmpAg.components.base).to.be.ok()
			expect(cmpAg.components.base.two).to.equal(2)

			expect(cmpAg.components.foo).to.be.ok()
			expect(cmpAg.components.foo.one).to.equal(1)

			expect(cmpAg:get()).to.equal(cmpAg.data)

			expect(cmpAg:get("one")).to.equal(1)
			expect(cmpAg:get("two")).to.equal(2)
			expect(cmpAg:get("testDefault")).to.equal(5)

			expect(cmpAg:get(Rocs.metadata("MtTest"), "num")).to.equal(3)

			expect(tostring(cmpAg)).to.equal("Aggregate(Test)")

			ent:removeComponent(testCmp)
			ent:removeBaseComponent(testCmp)
			expect(callCounts.testCmpDestroy).to.equal(1)
		end)
	end)

	describe("Systems", function()
		local rocs = Rocs.new()
		rocs:registerComponent(makeTestCmp(rocs))

		it("should fire lifecycle methods", function()
			local dep = rocs.dependencies:any(
				rocs.dependencies:all("Test")
			)

			local bindable = Instance.new("BindableEvent")
			local counter = Util.callCounter()
			rocs:registerSystem({
				name = "test";

				initialize = function(self)
					counter:call("initialize")
					expect(self).to.be.ok()
				end;

				destroy = function(self)
					counter:call("destroy")
					expect(self).to.be.ok()
				end;
			}, {
				dep:onAdded(function(self, e)
					expect(getmetatable(self).name).to.equal("test")
					expect(e.entity.scope).to.equal("system__test")
					expect(e.components.Test).to.be.ok()
					expect(e.components.Test:get("one")).to.equal(1)

					counter:call("added")
				end);

				dep:onUpdated(function(self, e)
					expect(getmetatable(self).name).to.equal("test")
					expect(e.entity.scope).to.equal("system__test")

					expect(e.components.Test).to.be.ok()
					if counter.updated == 0 then
						expect(e.components.Test:get("one")).to.equal(1)
					end

					counter:call("updated")
				end);

				dep:onRemoved(function(self, e)
					expect(getmetatable(self).name).to.equal("test")
					expect(e.entity.scope).to.equal("system__test")
					expect(e.components.Test).to.be.ok()
					expect(e.components.Test:get("one")).to.equal(nil)

					counter:call("removed")
				end);

				dep:onInterval(5, function(dt)
					counter:call("interval")
				end);

				dep:onEvent(bindable.Event, function(param)
					expect(param).to.equal("param")
					counter:call("event")
				end)
			})
			local ent = rocs:getEntity(workspace, "foo")

			bindable:Fire("foo")
			expect(counter.event).to.equal(0)

			expect(counter.initialize).to.equal(0)
			ent:addBaseComponent("Test", { one = 1})
			expect(counter.initialize).to.equal(1)

			expect(counter.event).to.equal(0)
			bindable:Fire("param")
			expect(counter.event).to.equal(1)

			expect(counter.destroy).to.equal(0)
			ent:removeBaseComponent("Test")
			expect(counter.destroy).to.equal(1)

			expect(counter.added).to.equal(1)
			expect(counter.updated).to.equal(2)
			expect(counter.removed).to.equal(1)

			bindable:Fire("bar")
			expect(counter.event).to.equal(1)

			expect(counter.interval).to.equal(0)
		end)
	end)

	describe("Layers", function()
		local rocs = Rocs.new()
		local callCounts = Util.callCounter()
		local testCmp = makeTestCmp(rocs, callCounts)
		rocs:registerComponent(testCmp)

		it("should add and remove components", function()
			local ent = rocs:getEntity(workspace, "rawr")

			local layerId = ent:addLayer({
				[workspace] = {
					Test = {
						one = 1
					}
				}
			})

			local aggregate = ent:getComponent("Test")
			expect(aggregate:get("one")).to.equal(1)

			ent:removeLayer(layerId)

			expect(aggregate:get("one")).to.equal(nil)
		end)
	end)
end
