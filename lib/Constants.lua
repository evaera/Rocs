local Constants = {

	LIFECYCLE_ADDED = "onAdded";
	LIFECYCLE_REMOVED = "onRemoved";
	LIFECYCLE_UPDATED = "onUpdated";

	ALL_COMPONENTS = {};
	None = {};

	LAYER_IDENTIFIER = "_layer";
	SCOPE_BASE = "_base";
	SCOPE_REMOTE = "_remote";

	COMPARATOR_NEAR_DEFAULT = 0.001;

}

Constants.RESERVED_SCOPES = {
	[Constants.SCOPE_BASE] = true;
	[Constants.SCOPE_REMOTE] = true;
}

return Constants
