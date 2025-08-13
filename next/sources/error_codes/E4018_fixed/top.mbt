struct S { v : Int }

let s : S = { v: 3 }
let t = Show::to_string(s)

impl Show for S with output(self, logger) {
  logger.write_object(self.v)
}