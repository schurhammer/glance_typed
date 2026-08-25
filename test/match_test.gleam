import glance_typed/match
import gleam/list
import gleam/option.{Some}
import gleam/string

fn bool_domain() {
  match.ClosedDomain([
    match.Constructor(match.ConstructorId("gleam", "True"), [], 0, fn() { [] }),
    match.Constructor(match.ConstructorId("gleam", "False"), [], 0, fn() { [] }),
  ])
}

fn option_domain(element) {
  match.ClosedDomain([
    match.Constructor(
      match.ConstructorId("gleam/option", "Some"),
      [Some("value")],
      1,
      fn() { [element] },
    ),
    match.Constructor(match.ConstructorId("gleam/option", "None"), [], 0, fn() {
      []
    }),
  ])
}

fn result_domain(a, e) {
  match.ClosedDomain([
    match.Constructor(
      match.ConstructorId("gleam", "Ok"),
      [Some("value")],
      1,
      fn() { [a] },
    ),
    match.Constructor(
      match.ConstructorId("gleam", "Error"),
      [Some("error")],
      1,
      fn() { [e] },
    ),
  ])
}

fn list_domain(element) {
  match.ClosedDomain([
    match.Constructor(match.ConstructorId("gleam", "Empty"), [], 0, fn() { [] }),
    match.Constructor(match.ConstructorId("gleam", "NonEmpty"), [], 2, fn() {
      [element, list_domain(element)]
    }),
  ])
}

fn tuple_domain(domains) {
  match.ClosedDomain([
    match.Constructor(
      match.ConstructorId("", "#"),
      [],
      list.length(domains),
      fn() { domains },
    ),
  ])
}

fn render(witness: List(match.Pattern)) -> String {
  string.join(list.map(witness, pattern), ", ")
}

fn pattern(p: match.Pattern) -> String {
  case p {
    match.Wild | match.OpaquePattern -> "_"
    match.IntPattern(v) -> v
    match.FloatPattern(v) -> v
    match.StringPattern(v) -> v
    match.ConstructorPattern(match.ConstructorId(_, "#"), args) ->
      "#(" <> string.join(list.map(args, pattern), ", ") <> ")"
    match.ConstructorPattern(match.ConstructorId("gleam", "Empty"), _) -> "[]"
    match.ConstructorPattern(match.ConstructorId("gleam", "NonEmpty"), [h, t]) ->
      "[" <> list_spine(h, t) <> "]"
    match.ConstructorPattern(match.ConstructorId(_, name), []) -> name
    match.ConstructorPattern(match.ConstructorId(_, name), args) ->
      name <> "(" <> string.join(list.map(args, pattern), ", ") <> ")"
  }
}

fn list_spine(head: match.Pattern, tail: match.Pattern) -> String {
  let elements = [pattern(head)]
  case tail {
    match.ConstructorPattern(match.ConstructorId("gleam", "NonEmpty"), [h, t]) ->
      string_join(list.append(elements, [list_spine(h, t)]))
    match.Wild -> string_join(elements) <> ", .."
    other -> string_join(elements) <> ", .." <> pattern(other)
  }
}

fn string_join(items: List(String)) -> String {
  case items {
    [] -> ""
    [x] -> x
    [x, ..rest] -> x <> ", " <> string_join(rest)
  }
}

fn missing(domains, matrix, query) {
  match.witnesses(domains, matrix, query, 8)
  |> list.map(render)
}

pub fn exhaustive_bool_test() {
  let matrix = [
    [constructor("gleam", "True", [])],
    [constructor("gleam", "False", [])],
  ]
  missing([bool_domain()], matrix, [match.Wild])
  |> should_equal([])
}

pub fn inexhaustive_bool_test() {
  let matrix = [[constructor("gleam", "True", [])]]
  missing([bool_domain()], matrix, [match.Wild])
  |> should_equal(["False"])
}

pub fn empty_bool_match_test() {
  missing([bool_domain()], [], [match.Wild])
  |> should_equal(["True", "False"])
}

pub fn result_with_literal_pattern_test() {
  let matrix = [[constructor("gleam", "Ok", [match.IntPattern("0")])]]
  missing([result_domain(match.OpenDomain, match.OpenDomain)], matrix, [
    match.Wild,
  ])
  |> should_equal(["Ok(_)", "Error(_)"])
}

pub fn list_single_element_test() {
  let matrix = [
    [
      constructor("gleam", "NonEmpty", [
        match.Wild,
        constructor("gleam", "Empty", []),
      ]),
    ],
  ]
  missing([list_domain(match.OpenDomain)], matrix, [match.Wild])
  |> should_equal(["[]", "[_, _, ..]"])
}

pub fn multi_subject_literal_test() {
  let matrix = [
    [constructor("gleam", "False", []), match.IntPattern("1")],
    [constructor("gleam", "True", []), match.IntPattern("2")],
  ]
  missing([bool_domain(), match.OpenDomain], matrix, [match.Wild, match.Wild])
  |> should_equal(["True, _", "False, _"])
}

pub fn redundant_clause_test() {
  let matrix = [[constructor("gleam", "True", [])]]
  missing([bool_domain()], matrix, [constructor("gleam", "True", [])])
  |> should_equal([])
}

pub fn reachable_clause_test() {
  let matrix = [[constructor("gleam", "True", [])]]
  missing([bool_domain()], matrix, [constructor("gleam", "False", [])])
  |> should_equal(["False"])
}

pub fn literal_redundancy_test() {
  let matrix = [[match.IntPattern("1")]]
  missing([match.OpenDomain], matrix, [match.IntPattern("1")])
  |> should_equal([])
}

pub fn guard_free_exhaustive_wildcard_test() {
  let matrix = [[match.Wild]]
  missing([bool_domain()], matrix, [match.Wild])
  |> should_equal([])
}

pub fn nested_option_int_test() {
  let inner = option_domain(match.OpenDomain)
  let outer = option_domain(inner)
  let some_some =
    constructor("gleam/option", "Some", [
      constructor("gleam/option", "Some", [match.IntPattern("0")]),
    ])
  let some_none =
    constructor("gleam/option", "Some", [
      constructor("gleam/option", "None", []),
    ])
  let matrix = [[some_some], [some_none]]
  missing([outer], matrix, [match.Wild])
  |> should_equal(["Some(Some(_))", "None"])
}

pub fn tuple_subjects_test() {
  let matrix = [
    [
      constructor("", "#", [
        constructor("gleam", "True", []),
        match.StringPattern("x"),
      ]),
    ],
  ]
  let domains = [tuple_domain([bool_domain(), match.OpenDomain])]
  missing(domains, matrix, [match.Wild])
  |> should_equal(["#(True, _)", "#(False, _)"])
}

pub fn open_type_needs_wildcard_test() {
  let matrix = [[match.IntPattern("1")]]
  missing([match.OpenDomain], matrix, [match.Wild])
  |> should_equal(["_"])
}

pub fn opaque_pattern_does_not_cover_test() {
  missing([match.OpenDomain], [[match.OpaquePattern]], [match.Wild])
  |> should_equal(["_"])
}

pub fn opaque_pattern_does_not_make_later_clause_redundant_test() {
  let matrix = [
    [match.StringPattern("a")],
    [match.OpaquePattern],
  ]
  missing([match.OpenDomain], matrix, [match.StringPattern("b")])
  |> should_equal(["b"])
}

pub fn opaque_pattern_shadowed_by_wildcard_test() {
  missing([match.OpenDomain], [[match.Wild], [match.OpaquePattern]], [
    match.OpaquePattern,
  ])
  |> should_equal([])
}

pub fn open_column_constructor_query_keeps_later_columns_test() {
  let matrix = [
    [
      constructor("a", "Pair", [match.Wild, match.IntPattern("0")]),
      constructor("gleam", "False", []),
    ],
  ]
  missing([match.OpenDomain, bool_domain()], matrix, [
    constructor("a", "Pair", [match.Wild, match.IntPattern("0")]),
    constructor("gleam", "True", []),
  ])
  |> should_equal(["Pair(_, 0), True"])
}

pub fn witness_matches_concrete_query_on_empty_matrix_test() {
  missing([option_domain(match.OpenDomain)], [], [
    constructor("gleam/option", "Some", [match.IntPattern("0")]),
  ])
  |> should_equal(["Some(0)"])
}

pub fn nested_witness_matches_concrete_query_on_empty_matrix_test() {
  let some_some_0 =
    constructor("gleam/option", "Some", [
      constructor("gleam/option", "Some", [match.IntPattern("0")]),
    ])
  missing([option_domain(option_domain(match.OpenDomain))], [], [some_some_0])
  |> should_equal(["Some(Some(0))"])
}

pub fn empty_matrix_concrete_query_keeps_later_columns_test() {
  let matrix = [
    [constructor("", "#", [match.Wild, match.Wild, match.IntPattern("0")])],
  ]
  missing(
    [
      tuple_domain([
        match.OpenDomain,
        match.OpenDomain,
        match.OpenDomain,
      ]),
    ],
    matrix,
    [
      constructor("", "#", [
        match.IntPattern("1"),
        match.Wild,
        match.IntPattern("2"),
      ]),
    ],
  )
  |> should_equal(["#(1, _, 2)"])
}

fn constructor(m, name, args) {
  match.ConstructorPattern(match.ConstructorId(m, name), args)
}

fn should_equal(actual, expected) {
  case actual == expected {
    True -> Nil
    False ->
      panic as { string_inspect(actual) <> " != " <> string_inspect(expected) }
  }
}

fn string_inspect(items: List(String)) -> String {
  "[" <> string_join(items) <> "]"
}
