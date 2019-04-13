# ROCS
Roblox Component System

Still in development

## Todo
- Write more tests
- Make it so on Heartbeat etc. cannot yield
- Ensure timing of life cycles is ideal
- ShouldUpdate function?
- Number type reducer
- Refactor and clean up
- Depend on components with field X and value Y 
- Rocs.None for nil values for :set
- Serialize and restore in layer format
- Rename "hook" to "behavior"
- Function to grab all components of type
- PriorityValue reducer
- Rocs unique id on instantiation

### Systems
- Replication of components with mask (A system that operates on metadata)
  - Remote base is culmination of current data
- Duration

## Future ideas

- A way to make a component that handles one property generically in a way that many unrelated sources can all influence the property without agreeing on a component name

- Connect data sources via :set for base component, or adding components/layers

- Type of reducer field that accepts a priority list, where matching priority values are reduced together
  - Use case: A string field which you want to concatenate at matching priority, but replace at higher priority
- Maybe these "reducer fields" should exist as a formalized concept?
- function to generate defaults values for layers where nesting is required