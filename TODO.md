## Todo
- Write more tests (for registry functions, etc..)
- Serialize and restore in layer format
- Make onInterval use consistent timing


### Queries
- Optimize on both hasEntity and hasComponent
- Change registration to only occur when onAdded is called, etc
- Implement any, has optimization where if all have entity filter then they are combined, but if one doesn't then it drops it
- Depend on components with field X and value Y
  - Rocs.Exists for a property simply being non-nil
  - Use Rocs.None to ensure property is nil
  - Similar to pattern matching
- Make calling behaviors auto register in rocs
  - How to determine self variable in this case?
  - Rename "dependencies" to "queries"?
  - A way to trigger a one-time behavior similar to onUpdated from a query, so you can use queries generically
    - `findOne`, `findAll`
    - Shouldn't be "registered" like other behaviors.

### Systems
- Replication of components with mask (A system that operates on metadata)
  - Remote base is culmination of current data
- Duration

## Future ideas

- A way to make a component that handles one property generically in a way that many unrelated sources can all influence the property without agreeing on a component name

- Connect data sources via :set for base component, or adding components/layers
  - Adapters for different types of data sources, incl. other components

- Type of reducer field that accepts a priority list, where matching priority values are reduced together
  - Use case: A string field which you want to concatenate at matching priority, but replace at higher priority
- Maybe these "reducer fields" should exist as a formalized concept?
- function to generate defaults values for layers where nesting is required

## To make examples

- Number type reducer (add/mult)

workspace.GarageDoor [model] components: {GarageDoor, Open/Closed}
- Button [part]
- SlidingDoor [part]

