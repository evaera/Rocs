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
- Systems can have multiple dependencies which all have independent hooks
- Systems are deconstructed when none of their dependencies are met
- Component can have life cycle methods and functions associated with them independent of systems

Rocs is compatible with both Lua and [roblox-ts](https://roblox-ts.github.io).

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

## Systems

## Layers
