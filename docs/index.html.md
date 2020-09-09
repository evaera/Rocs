---
title: Rocs 

language_tabs:
  - lua
  - typescript

toc_footers:
  - <a href='https://github.com/rocs-rbx/Rocs'>GitHub Repository</a>
  - <a href='https://github.com/rocs-rbx/Rocs/tree/master/examples'>Examples</a>

includes:

search: true
---

# Rocs

**Rocs** is a *progressive* entity-component-system (ECS) library developed for use in the [Roblox](http://developer.roblox.com) game engine.

Rocs also performs the role of a general game state management library. Specifically, Rocs facilitates managing resources from multiple, unrelated places in your code base in a generic way.

To that end, Rocs allows more than one of the same component to exist at the same time on a single entity. After every mutation, Rocs uses functions that you define to determine the single source of truth for that component. This allows disparate locations in your code base to influence a shared state.

The Rocs workflow encourages compositional patterns, decoupled separation of concerns, and generic components which are reusable across many games. Because of this, patterns such as higher order components emerge naturally and allow you to keep grouped state changes atomic and concise. 

Additionally, Rocs supports middleware by means of life cycle hooks and augmenting core functionality. By default, two optional middleware are included:

- Selectors, which offer a way to query against your current set of components within your game and create systems with behaviors which are only active when those queries are met.
- Replication, which offers a batteries-included way to replicate components (or parts of components) you choose to clients.

To get started with Rocs, sync in with [Rojo](https://rojo.space) or [download the latest release](https://github.com/rocs-rbx/Rocs/releases).

<!-- Rocs is compatible with both Lua and TypeScript via [roblox-ts](https://roblox-ts.github.io). -->

## Use cases

> Register the component:

```lua
rocs:registerComponent({
  name = "WalkSpeed";
  reducer = function (values)
    return math.min(unpack(values))
  end;
  check = t.number;
  entityCheck = t.instance("Humanoid");
  onUpdated = function (self)
    self.instance.WalkSpeed = self:getOr(16)
  end;
})
```

> Inside your weapon code:

```lua
local entity = rocs:getEntity(humanoid, "weapon")

-- On Equipped:
entity:addComponent("WalkSpeed", 10)

-- On Unequipped:
entity:removeComponent("WalkSpeed")
```

> Inside your menu code:

```lua
local entity = rocs:getEntity(humanoid, "menu")

-- On Opened:
entity:addComponent("WalkSpeed", 0)

-- On Closed:
entity:removeComponent("WalkSpeed")
```

### Influencing shared state from disparate code locations

A classic example of the necessity to share resources is changing the player's walk speed. 

Let's say you have a heavy weapon that you want to have slow down the player when he equips it. That's easy enough, you just set the walk speed when the weapon is equipped, and set it back to default when the weapon is unequipped.

But what if you want something else to change the player's walk speed as well, potentially at the same time? For example, let's say you want opening a menu to set the character's WalkSpeed to `0`.

If we follow the same flow as when we implemented the logic for the heavy weapon above, we now have a problem: The player can equip the heavy weapon and then open and close the menu. Now, the player can walk around at full speed with a heavy weapon equipped when they should still be slowed!

Rocs solves this problem correctly by allowing you to apply a movement speed component from each location in the code base that needs to modify the walk speed. Each component can provide its own intensity level for which to affect the movement speed. Then, every time a component is added, modified, or removed, Rocs will group all components of the same type and determine a single value to set the WalkSpeed to, based on your defined [reducer function](#component-aggregates). 

In this case, the function will find the lowest value from all of the components, and then the player's WalkSpeed will be set to that number. ￼Now, there is only one source of truth for the player's WalkSpeed, which solves all of our problems. When there are no longer any components of this type, you can clean up by setting the player's walk speed back to default in a destructor.

<!-- TODO: Rewrite this section -->
<!-- ### Generic Level-of-Detail with Systems

```lua
rocs:registerSystem({
  name = "LOD"
}, {
  rocs.dependencies:hasComponent("LOD"):onInterval(1, function()

  end)
})
```

Systems can depend on groups of components being present on a single entity, so you can make a `LOD` component which has a distance field, and a system that looks for `LOD` components and checks if the player is near them, and if so, adds a `LOD_Near` component to the entity.

Then you could have a secondary system (like, an animator that runs on a tighter loop, for something like bobbing coins up and down in the world) that depends on `all(Coin, LOD_Near)`. Then that system would only receive coins which are near to the player.

Because systems are automatically deconstructed when none of their dependencies are met, you can make systems which have more specific dependencies which automatically free their resources for performance when they aren't in use. -->

# Concepts

This section will give an overview of the fundamental concepts used in Rocs so that you can understand the details in the following sections. Don't focus too much on the code right now, that will come later.

## Rocs instance

> Instantiating an instance of Rocs:

```lua
local rocs = Rocs.new()
```
```typescript
const rocs = new Rocs()
```

Multiple versions of Rocs can exist at the same time in the same place and do not affect each other. **Rocs instance** refers to the instance of Rocs that you instantiated. Typically, you should only have one instance of Rocs per game. However, this allows Rocs to be used by libraries independently of the containing game.

## Entities

> Getting an entity wrapper for Workspace, with the scope `"my scope"`:

```lua
local entity = rocs:getEntity(workspace, "my scope")
```
```typescript
const entity = rocs.getEntity(workspace, 'my scope')
```

**Entities** are the objects that we put components on. These can be Roblox Instances or objects that you create yourself. "Instance" will generally be used to refer to these objects for purposes of conciseness, but remember that it does not need to be an actual Roblox Instance.

For the sake of ergonomic API, Rocs provides an entity wrapper class which has many of the methods you will use to modify components. However, state is associated internally with the instance for which the wrapper belongs, and not within the wrapper itself. Multiple entity wrappers can exist for one instance.

Entity wrappers must be created with a **scope**, which is some value associated with the source of the state change. For example, if you wanted to stop a player from moving when they open a menu, then the entity wrapper you create to enact that change could be created with the scope `"menu"` (a string). If instead some state change on a player was coming from within a tool, you could use the `Tool` object as the scope.

The rationale behind this requirement is explained in the next section.

## Components

> Adding a component to an entity:

```lua
entity:addComponent("MyComponent", {
  foo = "bar";
})
```
```typescript
import { MyComponent } from 'path/to/component'

entity.addComponent(MyComponent, {
  foo: 'bar'
})
```

**Components** are, in essence, named <dfn data-t="Typically, a component is a well-structured dictionary table.">groups of related data</dfn> which can be associated with an entity. Every type of component you want to use must be explicitly registered on the Rocs instance with a <dfn data-t="Components must have unique names to ensure that we can keep server and client components straight when replicating. It also enables some shorthands within the API. We recommend that you give your components specific enough names so that naming collisions do not occur. Attempting to register two components with the same name is an error.">unique name</dfn> along with various other options.

In Rocs, components are a little different from a typical ECS library. In order to allow disparate locations of your code to influence and mutate the same state in a safe way, multiple of the same component can exist on one entity.

As discussed in the previous section, entity wrappers must be created with a scope. Multiple of the same component on one entity are distinguished by the scopes that you choose when adding the component. When you add or remove a component from an entity, you only affect components which are also branded with your scope.

### Reduced values

Every time you add, modify, or remove a component, all components of the same type are grouped and fed into a <dfn data-t="A function which you define that accepts an array of all values of components of the same type, and returns a single value. The function decides how the values should be combined to reach the final value.">**reducer function**</dfn>. The resultant value is now referred to as a **reduced value**.

### Component Aggregates

When you register a component type with Rocs, the table you register becomes the metatable of that component's **Aggregate**. Aggregates are essentially class instances which are used to represent all components of the same type on a single entity. They provide methods and have properties where you can access data from this component externally.

Aggregates may have their own constructors and destructors, <dfn data-t="Functions which fire when the component is added, updated, and removed">life cycle hooks</dfn>, and custom methods if you wish.

Only one instance of an Aggregate will exist per entity per component type. So if you have an entity with two components of type `"MyComponent"`, there will only be one `MyComponent` Aggregate for this entity.

### Tags and Base Scope Components

Component types may also be optionally registered with a [CollectionService] tag. Rocs will then automatically add and remove this component from the Instance when the tag is added or removed.

For situations like this where there is a component that exists at a more fundamental level, the **base scope** is used. The base scope is just like any other component scope, except it has special significance in performing the role as the "bottom-most" component (or in other words, the component that holds data for a component type without any additional modifiers from other places in the code base).

> Changing the `name` field of the *base component*.

```lua
entity:getBaseComponent("Character"):set("name", "New name")
```

The base scope is used for CollectionService tags, but is also useful in your own code. For example, if you had a component that represents a character, situations may arise where you want to modify data destructively, such as in changing a character's name. We aren't *influencing* the existing name, but instead we are completely changing it. In this case, you should change the `"name"` field on the base component directly. (This assumes that you initialized the base component earlier in your code, which should be the case if you have *basic* data like this).

Base components also have special precedence when passed to reducer functions: the base component is always the first value. Values from other scopes subsequently follow in the array in any order. This is useful for situations when you want non-base scopes to partially override fields from the base scope.

## Patterns

### Higher-Order Components

```lua
rocs:registerComponent({
  name = "Empowered";
  reducer = rocs.reducers.structure({
    intensity = rocs.reducers.highest;
  });
  check = t.interface({
    intensity = t.number;
  });
  onUpdated = function (self)
    local entity = rocs:getEntity(self.instance, self) -- This component is the scope.

    entity:addComponent("Health", self:getAnd("intensity", function(intensity)
      return {
        MaxHealthModifier = intensity;
      }
    end))

    entity:addComponent("WalkSpeed", self:getAnd("intensity", function(intensity)
      return intensity * 16
    end))
  end;
})
```

When creating games, it is often useful to have multiple levels of abstraction when dealing with state changes.

For example, you might have a `WalkSpeed` component which is only focused on dealing with the player's movement speed and nothing more. You might also have a `Health` component which only deals with the player's health. It's a good idea to create small components like this with each of their concerns wholly separated and decoupled.

However, it can become tiresome to modify these components individually if you often find yourself changing them in tandem. For example, if your game had a mechanic where players regularly received a buff that makes them walk faster *and* have more health, it's a good idea to group these state changes together so that they stay in sync and are applied <dfn data-t="An atomic change is an indivisible grouping of operations such that either all occur or none occur, thus preventing desynchronization.">atomically</dfn>.

Higher-order components allow you to do just this. A higher-order component is simply just a component that creates other components within their life cycle methods. In the code sample, we use the `onUpdated` life cycle method to add two components to the instance that this component is already attached to. 

`getAnd` is a helper function on Aggregates which gets a field from the current component's data and then calls the callback only if that value is non-nil. If the value is nil, `getAnd` just returns `nil` immediately. Adding a component with the value of `nil` is the same as removing it.

<aside class="notice">Higher-order components are not a Rocs feature per se. They are a pattern that emerges from Rocs' compositional nature.</aside>

### Meta-components

```lua
entity:addComponent("ComponentName", data, {
  Replicated = true
})
```
> The above code is equivalent to:

```lua
local component = entity:addComponent("ComponentName", data)
local componentEntity = rocs:getEntity(component)
componentEntity:addComponent("Replicated", true)
```

Not only can components create other components, but components can actually be *on* other components. We refer to these components which are on other components as **meta-components**. Meta-components exist on the Aggregate instance of another component.

Meta-components are useful to store state about components themselves rather than whatever the component manages. For example, the optional built-in `Replication` component, when present on another component, will cause that parent component to automatically be replicated over the network to clients.

A short hand exists in the `addComponent` method on entity wrappers to add meta-components quickly immediately after adding your main component. You can also define implicit meta-components upon component registration which will always be added to those specific components via the `components` field.

# Components API

## Registering a component
```lua
rocs:registerComponent({
  name = "MyComponent";
  reducer = rocs.reducers.structure({
    field = rocs.reducers.add;
  });
  check = t.interface({
    field = t.number;
  });
  entityCheck = t.instanceIsA("BasePart");
  tag = "MyComponentTag";
})
```

`rocs:registerComponent` is used to register a component.

### Component registration fields

Field | Type | Description | Required
----- | ---- | ----------- | --------
name | string | The name of the component. Must be unique across all registered components. | ✓
reducer | function `(values: Array) -> any` | A function that reduces component data into a reduced value. | 
check | function `(value: any) -> boolean` | A function which is invoked to type check the reduced value after reduction. |
entityCheck | function | A function which is invoked to ensure this component is allowed to be on this entity. |
defaults | dict | Default values for fields within this component. Becomes the metatable of the `data` field if it is a table. Does nothing if `data` is not a table. |
components | dict | Default meta-components for this component. |
initialize | method | Called when the Aggregate is instantiated
destroy | method | Called when the Aggregate is destroyed
onAdded | method | Called when the component is added for the first time
onUpdated | method | Called when the component's reduced value is updated
onParentUpdated | method | called when the component this meta-component is attached to is updated. (Only applies to meta-components).
onRemoved | method | Called when the component is removed
shouldUpdate | function `(a: any, b: any) -> boolean` | Called before onUpdated to decide if onUpdated should be called.
tag | string | A CollectionService tag. When added to an Instance, Rocs will automatically create this component on the Instance when using the Tags middleware. |

<small>All *method*s above are called with `self` as their only parameter.</small>

## Aggregate methods and fields

The following fields are inherited from the base Aggregate class and must not be present in registered components.

### get
`component:get(...fields) -> any`

```lua
local component = entity:getComponent("MyComponent")

local allData = component:get()

local field = component:get("field")

local nested = component:get("very", "nested", "field")
```

Retrieves a field from the current reduced value, or the entire thing if no parameters are given.

Short circuits and returns `nil` if any value in the path to the last field is `nil`.

```lua
local nestedField = component:get("one", "two", "three")
```

You can also get nested values from sub-tables in the component.

### getOr
`component:getOr(...fields, default)`

```lua
local value = component:getOr("field", "default value if nil")

local value = component:getOr("field", function(field)
  return "default value if nil"
end)
```

Similar to `get`, except returns the last parameter if the given field happens to be `nil`.

If the last parameter is a function, the function will be called and its return value will be returned.

### getAnd
`component:getAnd(...fields, callback)`

```lua
local value = component:getAnd("field", function(field)
  return field or "default value"
end)
```

Similar to `get`, except the retrieved field is fed through the given callback and its return value is returned from `getAnd` if the field is non-nil.

If the field *is* `nil`, then `getAnd` always returns `nil` and the callback is never invoked. This function is useful for transforming a value before using it.

### set
`component:set(...fields, value) -> void`

```lua
component:set("field", 1)

component:set("one", "two", "three", Rocs.None)
```

Sets a field on the base scope within component. If you want to set a field to `nil`, you must use `Rocs.None` instead of `nil`.

### dispatch
`component:dispatch(eventName: string, ...params) -> void`

Dispatch an event on this component. Invokes the callback of any listeners which are registered for this event name.

If there is a method on this component sharing the same name as `eventName`, it is also invoked.

### listen
`component:listen(eventName: string, listener: callback) -> listener`

Adds a listener for this specific event name. Works for custom events which are fired with `dispatch`, and built-ins such as `onAdded` and `onUpdated`.

Returns the passed listener.

### removeListener
`component:removeListener(eventName: string, listener: callback) -> void`

Removes a previously registered listener from this component. Send the same function that you registered previously as `listener` to unregister it.

### data
`data: any`

The current reduced value from this component.

### lastData
`lastData: any`

The previous reduced value from this component. This is only available during life cycle methods such as `onUpdated`.

# Built-in Operators 

Rocs provides a number of composable reducer and reducer utilities, so you only have to spend time writing a function for when you need something very specific.

<aside class="notice">Remember that these functions exist for convenience, and you are encouraged to implement custom functions for whatever you might need to do.</aside>

## Reducers

Reducer | Description
- | -
`last` | Returns the *last* value of the set. base scope components are always first, so `last` will be any non-base scope (unless the base component is the only value)
`first` | Returns the *first* value of the set. Opposite of `last`.
`truthy` | Returns the first truthy value in the set (or nil if there is none)
`falsy` | Returns the first falsy value in the set (or nil if none)
`add` | Adds the values from the set together (for numbers)
`multiply` | Multiplies the values from the set together (for numbers)
`lowest` | Lowest value (for numbers)
`highest` | Highest value (for numbers)
`concatArray` | Concatenates arrays
`mergeTable` | Merges tables together, with keys from later values overriding earlier.
`collect` | Returns all values this property is set to in each component as an array

## Reducer Utilities

### structure

```lua
reducer = rocs.reducers.structure({
  field = rocs.reducers.add;
});
```

Reduces a dictionary with a separate reducer for each field.

Accepts the default reducer to use for omitted properties as a secondary parameter. By default, `Reducers.last` is used for omitted properties.

### map

```lua
reducer = rocs.reducers.map(
  rocs.reducers.structure({
    one = rocs.reducers.multiply;
    two = table.concat;
    three = function (values)
      return values[3]
    end
  })
)
```

Reduces a table, using the same reducer for each key.

### concatString

```lua
reducer = rocs.reducers.concatString(" - ")
```

Concatenates strings with a given delimiter.

### priorityValue

```lua
reducer = rocs.reducers.priorityValue(rocs.reducers.concatString(" - "))
```

Takes values in the form `{ priority: number, value: any }` and produces the `value` with the highest `priority`, reducing any values with equivalent priorities through the given reducer. If the reducer is omitted, `Reducers.last` is implicit.

### exactly

```lua
reducer = rocs.reducers.exactly("some value")
```

Creates a reducer which always results in the same value.

### try

```lua
reducer = rocs.reducers.try(
  rocs.reducers.truthy,
  rocs.reducers.exactly("Default")
)
```

Tries a set of reducer functions until one of them returns a non-nil value.

### compose

```lua
reducer = rocs.reducers.compose(
  rocs.reducers.structure({
    base = rocs.reducers.last;
    add = rocs.reducers.add;
    mult = rocs.reducers.multiply;
  }),
  function (value)
    return value.base + value.add * value.mult;
  end
)
```

Composes a set of reducers together such that the return value from each is passed into the next. Uses the return value of the last reducer.

### thisOr

```lua
reducer = rocs.reducers.thisOr(
  rocs.reducers.truthy,
  1
)
```

Runs the given reducer, and provide a default value in case that reducer returns nil.

### lastOr

```lua
reducer = rocs.reducers.lastOr(1)
```

Returns the last non-nil value or a default value if there is none.

### truthyOr

```lua
reducer = rocs.reducers.truthyOr(1)
```

Same as `thisOr`, except the `truthy` reducer is always used.

### falsyOr

Same as `truthyOr`, except for falsy values.

## Comparators

Comparator | Description
---------- | -----------
`reference` | Compares two values by reference.
`value` | Compares two objects by value with a deep comparison.
`near` | Compares two numbers and only allows an update if the difference is greater than 0.001.

## Comparator Utilities

### structure

```lua
shouldUpdate = rocs.comparators.structure({
  propertyOne = rocs.comparators.reference;
  propertyTwo = rocs.comparators.near;
})
```

Compares tables with a different function for each field within the table. If any of the properties should update, the entire structure will update. Omitted properties are compared by reference.

### within

```lua
shouldUpdate = rocs.comparators.within(1)
```

Allows an update only when the change is not within the given epsilon.

# Rocs API

## Types

### componentResolvable

"componentResolvable" refers to any value which can resolve into a component. Specifically, this means either the component name as a string, or the component definition itself as a value. Either will work, but the string form is usually more ergonomic.

## `new`
`Rocs.new(name: string = "global"): rocs`

Creates a new Rocs instance. Use `name` if you are using Rocs within a library; for games the default of `"global"` is fine.

## `getEntity`
`rocs:getEntity(instance: any, scope: any): Entity`

Creates an Entity wrapper for this instance with the given scope. The scope can be any value that discriminates what is enacting this change (such as a menu or a weapon). 

Multiple Entities for the same instance can exist at once, so do not rely on receiving the same object when given the same parameters.

## `registerComponent`
`rocs:registerComponent(definition: dictionary): definition`

See "Registering a component"

## `registerComponentsIn`
`rocs:registerComponentsIn(instance: Instance): void`

Calls registerComponent on the return value from all ModuleScripts inside the given instance.

## `registerLifecycleHook`
`rocs:registerLifecycleHook(lifecycle: string, hook: callback): void`

Registers a callback which is called whenever the given life cycle method is invoked on any component. Callback is called with `(componentAggregate, stageName)`.

- `initialize`
- `onAdded`
- `onUpdated`
- `onParentUpdated`
- `onRemoved`
- `destroy`
- `global`

## `registerComponentHook`
`rocs:registerComponentHook(component: componentResolvable, lifecycle: string, hook: callback): hook`

Same as `registerLifecycleHook`, except only for a single component type.

## `unregisterComponentHook`
`rocs:registerComponentHook(component: componentResolvable, lifecycle: string, hook: callback): void`

Unregisters this component hook.

## `registerEntityComponentHook`
`rocs:registerEntityComponentHook(entity: any, component: componentResolvable, lifecycle: string, hook: callback): hook`

Registers a component hook for specific components on a specific entity. If the entity is a Roblox Instance, then this will be disconnected when the Instance is no longer a child of the DataModel.

## `getComponents`
`rocs:getComponents(component: componentResolvable): array<Aggregate>`

Returns an array of all Aggregates of the given type in the entire Rocs instance.

<aside class="warning"><strong>Do not modify this array</strong>, as it is used internally. If you need to mutate, you must copy it first.</aside>

# Entities API

```lua
local entity = rocs:getEntity(workspace)
```

## `addComponent`
`entity:addComponent(component: componentResolvable, data: any, metaComponents: dict?): Aggregate, boolean`

Adds a new component to this entity under the entity's scope.

If `data` is nil then this is equivalent to `removeComponent`.

Returns the associated Aggregate and a boolean indicating whether or not this component was new on this entity.

## `removeComponent`
`entity:removeComponent(component: componentResolvable): void`

Removes the given component from this entity.

## `addBaseComponent`
`entity:addBaseComponent(component: componentResolvable, data: any, metaComponents: dict?): Aggregate, boolean`

Similar to `addComponent`, but with the special base scope.

## `removeBaseComponent`
`entity:removeBaseComponent(component: componentResolvable): void`

Similar to `removeBaseComponent`, but with the special base scope.

## `getComponent`
`entity:getComponent(component: componentResolvable): Aggregate?`

Returns the Aggregate for the given component from this entity if it exists.

## `getAllComponents`
`entity:getAllComponents(): array<Aggregate>`

Returns all Aggregates on this entity.

## `removeAllComponents`
`entity:removeAllComponents(): void`

Removes all Aggregates on this entity.

## `getScope`
`entity:getScope(scope: any): Entity`

Returns a new Entity linked to the same instance as this entity but with a new scope.

# Built-in Middleware

- Mention how to use middleware

## Replication

- Todo

## Chaining 

## Tags

## Selectors

- Todo

# Authors

Rocs was designed and created by [evaera](https://eryn.io) and [buildthomas](https://github.com/buildthomas/).
