///|
pub fn catch_all() -> Double {
  // Error: catch! will rethrow unhandled error, and can only be used inside ...
  fail("Failed") catch! {

  }
}
