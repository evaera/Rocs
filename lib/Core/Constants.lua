local Constants = {

	LIFECYCLE_ADDED = "onAdded";
	LIFECYCLE_REMOVED = "onRemoved";
	LIFECYCLE_UPDATED = "onUpdated";
	LIFECYCLE_PARENT_UPDATED = "onParentUpdated";

	ALL_COMPONENTS = {};
	None = {};
	Internal = {};

	SCOPE_BASE = "_base";
	SCOPE_REMOTE = "_remote";

	COMPARATOR_NEAR_DEFAULT = 0.001;

}

Constants.RESERVED_SCOPES = {
	[Constants.SCOPE_BASE] = true;
	[Constants.SCOPE_REMOTE] = true;
}

return Constants
