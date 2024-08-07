WASI Monotonic Clock is a clock API intended to let users measure elapsed
time.

It is intended to be portable at least between Unix-family platforms and
Windows.

A monotonic clock is a clock which has an unspecified initial value, and
successive reads of the clock will produce non-decreasing values.