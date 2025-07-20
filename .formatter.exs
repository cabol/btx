locals_without_parens = [
  # BTx.Helpers
  wrap_error: 2,

  # BTx.TestUtils
  with_telemetry_handler: 2,
  with_telemetry_handler: 3
]

[
  import_deps: [:ecto],
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  line_length: 100,
  locals_without_parens: locals_without_parens,
  export: [locals_without_parens: locals_without_parens]
]
