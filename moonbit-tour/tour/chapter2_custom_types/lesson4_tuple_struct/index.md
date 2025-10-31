# Tuple Struct

Tuple structs are similar to enums with only one constructor that shares the 
same name as the type. They can be created using their constructor and accessed 
through indexed fields such as `.0` and `.1`, just like regular tuples.

Unlike regular tuples, tuple structs are distinct types even when they have 
identical field structures. This type safety prevents accidental mixing of 
conceptually different data.

Compared to regular structs, MoonBit's compiler optimizes tuple structs to avoid 
extra boxing overhead. For example, in most cases, `struct Point(Int)` is more 
efficient than `struct Point { internal: Int }`.

You can also use **pattern matching** to extract values from tuple structs.
