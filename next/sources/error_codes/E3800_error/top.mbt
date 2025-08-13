enum V {
  A, // Error: Expecting a newline or `;` here, but encountered another delimiter `,`.
}

struct S {
  a : Int, // Error: Expecting a newline or `;` here, but encountered another delimiter `,`.
}

type! E {
  A, // Error: Expecting a newline or `;` here, but encountered another delimiter `,`.
}