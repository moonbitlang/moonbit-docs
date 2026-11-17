///|
pub(open) trait Render {
  fn render(Self) -> String
}

///|
pub(all) struct Badge(String)

///|
pub impl Render for Badge with render(self) {
  self.0
}

///|
pub extend Badge with Render::{render}

///|
pub fn show_badge(badge : Badge) -> String {
  badge.render()
}
