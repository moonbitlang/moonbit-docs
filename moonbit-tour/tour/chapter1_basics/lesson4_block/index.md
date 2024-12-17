# Block and Statements

A block is an expression contains sequence of statements and an optional 
expression.

```
{
  statement1
  statement2
  expression
}
```

For example, the code above will execute `statement1`, `statement2`
and evaluate `expression` in order. The evaluation result of the block is the 
evaluation result of the expression. If the last one expression is omitted, 
the block will result in `()`, which type is `Unit`.


A statement can be a variable declaration, variable assignment, or any 
expression which type is `Unit`.  


A block is also associated with a namespace scope. In the `main` clause, the variable `a` declared in the inner block will shadow the outer `a`. It is only visible within the inner block.





