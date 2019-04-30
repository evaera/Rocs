---
title: Rocs 

language_tabs:
  - lua
  - typescript

toc_footers:
  - <a href='https://github.com/lord/slate'>Documentation Powered by Slate</a>

includes:

search: true
---

# Rocs

**Rocs** is a *progressive* entity-component-system (ECS) framework developed for use in the [Roblox](http://developer.roblox.com) game engine.

Rocs also performs the role of a general game state management library. Specifically, Rocs facilitates managing resources from multiple, unrelated places in your code base in a generic way.

Some other prominent features of Rocs include:

- Mechanisms for dealing with groups of state changes as a single unit
- Automated state replication to all or specific players with masking (only replicating some properties and not all)
- Compositional system dependency declaration: Systems can depend on one component, all of a set, any of a set, and permutations thereof (`all(foo, any(bar, baz))`)
- Systems can have multiple dependencies which all have independent behaviors
- Systems are deconstructed when none of their dependencies are met
- Components can have life cycle methods and functions associated with them independent of systems

Rocs is compatible with both Lua and TypeScript via [roblox-ts](https://roblox-ts.github.io).

## Use cases

> Register the component:

```lua
rocs:registerComponent({
  name = "WalkSpeed";
  reducer = rocs.reducers.lowest;
  check = t.number;
  entityCheck = t.instance("Humanoid");
  onUpdated = function (self)
    self.instance.WalkSpeed = self:get() or 16
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

> Inside your  menu code:

```lua
local entity = rocs:getEntity(humanoid, "menu")

-- On Opened:
entity:addComponent("WalkSpeed", 0)

-- On Closed:
entity:removeComponent("WalkSpeed")
```

### Managed state resource sharing

A classic example of the necessity to share resources is changing the player's walk speed. 

Let's say you have a heavy weapon that you want to have slow down the player when he equips it. That's easy enough, you just set the walk speed when the weapon is equipped, and set it back to default when the weapon is unequipped.

But what if you want something else to change the player's walk speed as well, potentially at the same time? For example, let's say you want opening a menu to set the character's WalkSpeed to `0`.

If we follow the same flow as when we implemented the logic for the heavy weapon above, we now have a problem: The player can equip the heavy weapon and then open and close the menu. Now, the player can walk around at full speed with a heavy weapon equipped they should still be slowed!

Rocs solves this problem correctly by allowing you to apply a movement speed component from each location in the code base that needs to modify it. Each component can provide its own intensity level for which to affect the movement speed. Then, every time a component is added, modified, or removed, Rocs will group all components of the same type and determine a single value to set the WalkSpeed to, based on your defined [reducer function](#component-aggregates). 

In this case, the function will find the lowest value from all of the components, and then the player's WalkSpeed will be set to that number. ￼Now, there is only one source of truth for the player's WalkSpeed, which solves all of our problems. When there are no longer any components of this type, you can clean up by setting the player's walk speed back to default in a destructor.

### Generic Level-of-Detail with Systems

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

Because systems are automatically deconstructed when none of their dependencies are met, you can make systems which have more specific dependencies which automatically free their resources for performance when they aren't in use.

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

> Getting an entity wrapper for Workspace, with the scope `"foo"`:

```lua
local entity = rocs:getEntity(workspace, "foo")
```
```typescript
const entity = rocs.getEntity(workspace, 'foo')
```

**Entities** can be Roblox Instances or any table. "Instance" will generally be used to refer to this internal object for purposes of conciseness, but remember that it does not need to be an actual Roblox Instance.

Rocs provides an entity wrapper class for ergonomic API usage, but data is associated internally with the inner instance, and not the wrapper. Multiple entity wrappers can exist for one instance. Entity wrappers hold no internal state themselves.

Entity wrappers must be created with a **scope**, which is a string that should refer to the area in the code where a change is being made. For example, if you wanted to stop a player from moving when they open a menu, then the entity wrapper you create to enact that change should be created with the scope `"menu"`. The rationale behind this requirement is explained in the next section.

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

**Components** are, in essence, named <dfn data-t="Typically, a component is a well-structured dictionary table.">groups of related data</dfn> which can be associated with an entity. Every type of component you want to use must be explicitly registered on the Rocs instance with a unique name along with various other options.

In Rocs, components are a little different from a typical ECS framework. In order to facilitate shared <dfn data-t='"Resource" refers to anything that has state which Rocs could manage, such as a property like WalkSpeed.'>resource</dfn> management, multiple components of the same type can exist on the same entity.

As discussed in the previous section, entity wrappers must be created with a scope. Multiple components of the same type are distinguished by this scope. When you add or remove a component from an entity, you only affect components which are also branded with your scope.

### Component Aggregates

Every time you add, modify, or delete a component, all components of the same type are grouped and subsequently fed into a <dfn data-t="A function that accepts an array of all values of components of the same type, and returns a single value. The function decides how the values should be combined to reach the final value.">reducer function</dfn>. The resultant value is now referred to as a **component aggregate**.

### Component Classes

When you register a component type with Rocs, what you are actually registering is a **component class**. Component classes are used to represent a component of a specific type and are how you access the aggregate data.

Component classes may have their own constructors and destructors, <dfn data-t="Functions which fire when the component is added, updated, and removed">life cycle hooks</dfn>, and custom methods.

Only one component class will exist per entity per component type. So if you have an entity with two components of type `"MyComponent"`, there will only be one `MyComponent` component class for this entity.

### Tags and Base Scope Components

Component types may also be optionally registered with a [CollectionService] tag. Rocs will then automatically add (with [optional initial data](#)) and remove this component from the entity for the respective Instance.

For situations like this where there is a component that exists at a more fundamental level, the **base scope** is used. The base scope is just like any other component scope, except it has special significance in performing the role as the "bottom-most" component (or in other words, the component that holds data for a component type without any additional modifiers from other places in the code base).

> Changing the `name` field of the *base component*.

```lua
entity:getBaseComponent("Character"):set("name", "New name")
```

The base scope is used for CollectionService tags, but is also useful in your own code. For example, if you had a component that represents a character, situations may arise where you want to modify data destructively, such as in changing a character's name. We aren't *influencing* the existing name, but instead we are completely changing it. In this case, you should change the `"name"` field on the base component directly. (This assumes that you created the base component earlier in your code, which should be the case if you have *basic* data like this).

Base components also have special precedence when passed to reducer functions: the base component is always the first value. Values from other scopes subsequently follow in any order. This is useful for situations when you want non-base scopes to partially override fields from the base scope.

## Metadata

**Metadata** are similar to components, but cannot be added to entities themselves. Instead, metadata are parts of components -- or well-known sub-fields as part of full components. Metadata are useful for holding data *about* the component itself.

Metadata are registered like components and have their own reducer function just like components. When components are reduced, if a metadata field is encountered, the metadata reducer is used to reduce that field.

Solid examples of metadata will be mentioned in the "layers" section.

## Systems

**Systems** operate on components from the outside. Systems declare their dependencies, which are components or a set of components that the system deals with. Systems can also depend on any component with a certain metadata field.

### Hooks

Systems can have multiple dependencies. Each dependency can have its own set of **behaviors**, which are invoked differently depending on the behavior.

For example, there is an `onUpdated` behavior which is invoked whenever one of the dependent components is updated (on any entity), the `onInterval` behavior can be used to repeatedly call the behavior as long as the dependency is met, and the `onEvent` behavior can be used to run connect an event listener when the dependency is met and disconnect the listener when it is no longer met. 

### System sleeping

When *none* of a system's dependencies are met, the system is deconstructed. When one of its dependencies are met, the a new instance of the system is constructed. In this way, systems are singletons which can come in and out of existence. 

## Layers

The final core concept is layers. **Layers** are components that create other components. Layers can be used to group a set of related state changes together.

When you add, modify, or remove a layer, the changes it denotes are enacted immediately. 

Because layers are just components, layer data is reduced if multiple layers with the same ID exist. By default, layers use a random ID. The ID becomes the scope of the components that the layer adds. Layers with different IDs do not affect each other. Layer data only gets reduced if two layers share the same ID.

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

`rocs:registerComponent` is used to register a component class.

### Component class fields

Field | Type | Description | Required
----- | ---- | ----------- | --------
name | string | The name of the component. Must be unique across all registered components. | ✓
reducer | function `(values: Array) -> any` | A function that reduces component data into a component aggregate. | 
check | function `(value: any) -> boolean` | A function which is invoked to type check the component aggregate after reduction. |
entityCheck | function | A function which is invoked to ensure this component is allowed to be on this entity. |
tag | string | A CollectionService tag. When added to an Instance, Rocs will automatically create this component on the Instance. |
initialize | method | Called when the component class is instantiated
destroy | method | Called when the component class is destroyed
onAdded | method | Called when the component is added for the first time
onUpdated | method | Called when the component aggregate data is updated
onRemoved | method | Called when the component is removed

## Component class injected fields

The following fields are injected into the component class, and must not be present in the given class.

### get
`get(...fields) -> any`

```lua
local component = entity:getComponent("MyComponent")

local allData = component:get()

local field = component:get("field")
```

Retrieves a field from the current aggregate data, or the entire thing if no parameters are given.

```lua
local nestedField = component:get("one", "two", "three")
```

You can also get nested values from sub-tables in the component.

### set
`set(...fields, value) -> void`

```lua
component:set("field", 1)

component:set("one", "two", "three", Rocs.None)
```

Sets a field on the `base` component.

<aside class="warning">Refactor coming soon</aside>

### data
`data: any`

The current component aggregate data.

### lastData
`lastData: any`

The previous component aggregate data.

# Built-in Reducers

Rocs provides a number of composable reducer and reducer utilities, so you only have to spend time writing a function for when you need something very specific.

## Reducers

Reducer | Description
- | -
`last` | Returns the *last* value of the set. `base` scope components are always first, so `last` will be any non-base scope (unless the base component is the only value)
`first` | Returns the *first* value of the set. Opposite of `last`.
`truthy` | Returns the first truthy value in the set (or nil if there is none)
`falsy` | Returns the first falsy value in the set (or nil if none)
`add` | Adds the values from the set together (for numbers)
`multiply` | Multiplies the values from the set together (for numbers)

## Utilities

### structure

```lua
reducer = rocs.reducers.structure({
  field = rocs.reducers.add;
});
```

Reduces a dictionary with a separate reducer for each field.

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

Reduces a dictionary, using the same reducer for each field individually.

### thisOr

```lua
reducer = rocs.reducers.thisOr(
  rocs.reducers.truthy,
  1
)
```

Runs the given reducer, and provide a default value in case that reducer returns nil.

### truthyOr

```lua
reducer = rocs.reducers.truthyOr(1)
```

Same as `thisOr`, except the `truthy` reducer is always used.

### falsyOr

Same as `truthyOr`, except for falsy values.

# Entities API

```lua
local entity = rocs:getEntity(workspace)
```

The rocs insta

# Systems API

## Dependencies

## Hooks

# Layers API

# Rocs API

# Built-in Systems

## Replication

## Duration

# Authors

Rocs was designed and created by [evaera](https://eryn.io).