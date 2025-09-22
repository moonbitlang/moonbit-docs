# Map Pattern

MoonBit provides convenient pattern matching for map-like data structures. In a map pattern `{ key1: pattern1, key2?: pattern2, .. }`:

* The `key1: pattern1` part matches if the key exists in the map and the value associated with the key matches the specified pattern.

* The `key2?: pattern2` part matches regardless of whether the key exists; in this case, `pattern2` will match against an option value. If the `key2` exists in the map, this value will be `Some(value)`, otherwise it will be `None`.

* The `..` part indicates that the pattern can match maps with additional keys not specified in the pattern. This marker is always required in map patterns.

The example shows how to process user configuration settings using map pattern matching. The `process_config` function handles various configurations and provides appropriate defaults when certain keys are missing.
