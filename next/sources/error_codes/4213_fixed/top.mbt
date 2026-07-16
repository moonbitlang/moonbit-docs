///|
pub(open) trait Renderable {
  fn render(Self) -> String
}

///|
pub fn[X : Renderable] as_renderable(value : X) -> &Renderable {
  value as &Renderable
}
