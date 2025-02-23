enum Resource {
  TextFile(String)
  Image(String)
  Folder(Map[String, Resource])
} derive(Show)

let assets : Resource = Folder(
  {
    "readme.md": TextFile("hello world"),
    "image.jpg": Image("https://someurl1"),
    "folder1": Folder(
      {
        "src1.mbt": TextFile("some code1"),
        "src2.mbt": TextFile("some MoonBit code 2"),
      },
    ),
    "folder2": Folder(
      {
        "src3.mbt": TextFile("some code3"),
        "image2.jpg": Image("https://someurl2"),
      },
    ),
  },
)

fn main {
  let Folder(top_level) = assets
  println("we have items in the root folder:\n \{top_level.keys()}")
  println("resource count: \{count(assets)}")
}

fn count(res : Resource) -> Int {
  match res {
    Folder(map) => {
      let mut sum = 0
      for name, res in map {
        sum += count(res)
      }
      sum
    }
    TextFile(_) => 1
    Image(_) => 1
  }
}

