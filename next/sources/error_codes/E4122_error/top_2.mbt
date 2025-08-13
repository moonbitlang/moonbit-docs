pub fn catch_all() -> Double {
  try {
    fail!("Failed") // Error: catch! will rethrow unhandled error, and can only be used inside ...
  } catch! {
  }
}