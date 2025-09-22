///|
fn process_config(config : Map[String, String]) -> String {
  match config {
    // Pattern 1: Must have "name" key, optional "theme" key
    { "name": username, "theme"? : Some(theme), .. } =>
      "Welcome \{username}! Using \{theme} theme."

    // Pattern 2: Must have "name" key, theme is missing
    { "name": username, "theme"? : None, .. } =>
      "Welcome \{username}! Using default theme."

    // Pattern 3: Missing required "name" key
    { "theme": theme, .. } => "Guest user with \{theme} theme."

    // Pattern 4: Empty or other configurations
    _ => "Guest user with default settings."
  }
}

///|
fn main {
  // Test different configurations
  let config1 = { "name": "Alice", "theme": "dark", "language": "en" }
  let config2 = { "name": "Bob", "language": "zh" }
  let config3 = { "theme": "light", "timeout": "30" }
  let config4 = {}
  println(process_config(config1))
  println(process_config(config2))
  println(process_config(config3))
  println(process_config(config4))
}
