# Used by "mix format"
[
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  plugins: [Styler],
  locals_without_parens: [rust: 1, rust: 2],
  export: [
    locals_without_parens: [rust: 1, rust: 2]
  ],
  line_length: 98
]
