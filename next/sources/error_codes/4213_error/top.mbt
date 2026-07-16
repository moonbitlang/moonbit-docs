///|
pub(open) trait Renderable {
  fn render(Self) -> String
}

///|
pub fn[X : Renderable] &Renderable::Renderable(value : X) -> &Renderable {
  value as &Renderable
}
