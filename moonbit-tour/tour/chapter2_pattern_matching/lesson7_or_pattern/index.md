# Or Pattern 

It's a little verbose if any two cases have common datas and same way to handle them. For example, here is a enum `RGB` and a function `get_green` to get the green value from it. 

The `RGB` and `RGBA` cases can be combined as well. In an *or pattern*, the sub-patterns can introduce new variables, but they must be of the same type and have the same name in all sub-patterns. This restriction allows us to handle them uniformly.

