#include <moonbit.h>

typedef void* moonbit_closure;

// `call` indicates how to consume `closure`
void register_callback(void (*call)(moonbit_closure), moonbit_closure closure) {
  call(closure); // call closure directly
  moonbit_decref(closure); // if doesn't store this closure, then need use `moonbit_decref` to release resources
} 

int register_callback_with_point(
  int (*call)(moonbit_closure,int,int), 
  moonbit_closure closure
) {
  int res = call(closure,3,4);
  // argument provided by c side
  // result consume in c side, here directly return to moonbit side
  moonbit_decref(closure);
  return res;
}