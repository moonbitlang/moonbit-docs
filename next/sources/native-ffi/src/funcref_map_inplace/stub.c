#include <moonbit.h>

// start map inplace types
typedef void *moonbit_closure_t;
typedef void *moonbit_point_t;
// end map inplace types

// start map inplace implementation
void ffi_map_inplace(moonbit_point_t *xs,
                     moonbit_point_t (*call)(moonbit_closure_t,
                                             moonbit_point_t),
                     moonbit_closure_t closure) {
  int len = Moonbit_array_length(xs);

  for (int i = 0; i < len; ++i) {
    // CRITICAL: increment reference count before each call
    // because closure is the first parameter and will be consumed
    moonbit_incref(closure);
    xs[i] = call(closure, xs[i]);
    
    // CRITICAL: again, increment before second call
    moonbit_incref(closure);
    xs[i] = call(closure, xs[i]);
  }
}
// end map inplace implementation