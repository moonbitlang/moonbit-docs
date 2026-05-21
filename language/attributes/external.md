# External Attribute

The `#external` attribute is used to mark an abstract type as external type.

- For Wasm and Wasm GC backends, it would be interpreted as `externref`.
- For JavaScript backend, it would be interpreted as `any`.
- For native backends, it would be interpreted as `void*`.

```moonbit
#external
type AttrPtr
```
