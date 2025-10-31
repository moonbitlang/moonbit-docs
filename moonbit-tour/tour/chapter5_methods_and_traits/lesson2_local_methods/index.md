# Local Methods

In previous lessons you learned how to define methods for types. Those methods 
must be defined in the same package as the type itself, the restriction applies 
only to public methods (method marked with `pub`).

Sometimes you may want to extend a type from another package with additional behavior. 
MoonBit allows you to add local (non-`pub`) methods for any type. These methods 
are visible only within the defining package, so different packages can safely 
add their own internal helpers to the same type without conflicts.

