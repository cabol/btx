locals_without_parens = [
  # BTx.Helpers
  wrap_error: 2
]

[
  import_deps: [:ecto],
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  locals_without_parens: locals_without_parens,
  export: [locals_without_parens: locals_without_parens]
]
