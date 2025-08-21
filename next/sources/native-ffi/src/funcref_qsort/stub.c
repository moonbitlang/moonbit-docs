#include <moonbit.h>
#define __USE_GNU // to order to use qsort_r
#include <stdlib.h>

// start type definitions
typedef void *moonbit_ref_t;
typedef moonbit_ref_t moonbit_point_t;
typedef moonbit_point_t *moonbit_fixedarray_point_t;

struct comp_context {
  int (*call)(moonbit_point_t lhs, moonbit_point_t rhs);
};
// end type definitions

// Currently need fresh renaming for all symbols 
// https://github.com/moonbitlang/moon/issues/969

// start cross platform comparison function
#if defined(_WIN32) || defined(_WIN64) || defined(__APPLE__)
#include <stdlib.h>
int fq_comp(struct comp_context *context, moonbit_point_t *lhs,
         moonbit_point_t *rhs)
#else
#define __USE_GNU // to order to use qsort_r
#include <stdlib.h>
int fq_comp(moonbit_point_t *lhs, moonbit_point_t *rhs,
         struct comp_context *context)
#endif
{
  moonbit_incref(*lhs);
  moonbit_incref(*rhs);
  int res = context->call(*lhs, *rhs);
  return res;
}
// end cross platform comparison function

// start main qsort function
// https://en.cppreference.com/w/c/algorithm/qsort
// both glibc and Windows CRT doesn't support ISO C qsort_s
void fq_ffi_qsort(moonbit_fixedarray_point_t xs,
               int (*call)(moonbit_point_t lhs, moonbit_point_t rhs)) {
  size_t count = Moonbit_array_length(xs);
  size_t elem_size = sizeof(moonbit_point_t);

  struct comp_context context;
  context.call = call;
#if defined(_WIN32) || defined(_WIN64)
  // https://learn.microsoft.com/en-us/cpp/c-runtime-library/reference/qsort-s?view=msvc-170
  qsort_s(xs, count, elem_size, (void *)fq_comp, &context);
#elif defined(__APPLE__)
  // https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man3/qsort_r.3.html
  qsort_r(xs, count, elem_size, &context, (void *)fq_comp);
#else
  // https://www.man7.org/linux/man-pages/man3/qsort.3.html
  qsort_r(xs, count, elem_size, (void *)fq_comp, &context);
#endif
}
// end main qsort function