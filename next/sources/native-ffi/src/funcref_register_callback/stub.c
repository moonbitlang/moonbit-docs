#include <moonbit.h>

// start moonbit closure definition
typedef void* moonbit_closure_t;
// end moonbit closure definition

// start register_callback definition
//
// `call` indicates how to consume `closure`
void register_callback(void (*call)(moonbit_closure_t), moonbit_closure_t closure) {
  // CRITICAL: increment ref count before each call
  // because closure is the first (and only) parameter to the adapter function
  moonbit_incref(closure); 
  call(closure); // call closure directly
  
  // CRITICAL: increment again before second call
  moonbit_incref(closure);
  call(closure);

  // CRITICAL: increment again before third call  
  moonbit_incref(closure);
  call(closure);
} 
// end register_callback definition