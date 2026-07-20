import birdie
import glance
import glance_typed as typed
import glance_typed_yaml
import gleam/dict
import gleam/list
import gleeunit

pub fn main() {
  gleeunit.main()
}

fn infer_with(
  dependencies: dict.Dict(String, typed.ModuleInterface),
  source: String,
  module_name: String,
) -> typed.Module {
  let assert Ok(parsed) = glance.module(source)
  let assert Ok(checked) = typed.infer_module(dependencies, parsed, module_name)
  checked
}

fn infer(source: String) -> typed.Module {
  infer_with(dict.new(), source, "test")
}

fn infer_interface(
  dependencies: dict.Dict(String, typed.ModuleInterface),
  source: String,
  module_name: String,
) -> typed.ModuleInterface {
  typed.interface(infer_with(dependencies, source, module_name))
}

fn infer_yaml(source: String) -> String {
  glance_typed_yaml.module_to_string(infer(source))
}

fn prelude_deps() -> dict.Dict(String, typed.ModuleInterface) {
  dict.from_list([#("gleam", typed.interface(typed.prelude_module()))])
}

fn infer_with_prelude(source: String) -> typed.Module {
  infer_with(prelude_deps(), source, "test")
}

fn infer_yaml_with_prelude(source: String) -> String {
  glance_typed_yaml.module_to_string(infer_with_prelude(source))
}

fn infer_error(source: String) -> typed.Error {
  let assert Ok(parsed) = glance.module(source)
  let assert Error(err) = typed.infer_module(dict.new(), parsed, "test")
  err
}

fn infer_error_with_prelude(source: String) -> typed.Error {
  let assert Ok(parsed) = glance.module(source)
  let assert Error(err) = typed.infer_module(prelude_deps(), parsed, "test")
  err
}

fn option_dependencies() -> dict.Dict(String, typed.ModuleInterface) {
  let prelude = typed.interface(typed.prelude_module())
  let option_interface =
    infer_interface(
      dict.new(),
      "
      pub type Option(e) {
        Some(e)
        None
      }

      pub fn map(option: Option(a), f: fn(a) -> b) -> Option(b) { panic }
      ",
      "gleam/option",
    )
  dict.from_list([#("gleam", prelude), #("gleam/option", option_interface)])
}

pub fn recursive_function_test() {
  infer_yaml(
    "
    pub fn countdown(n) {
      case n {
        0 -> 0
        _ -> countdown(n - 1)
      }
    }
    ",
  )
  |> birdie.snap(title: "recursive function test")
}

pub fn higher_order_function_test() {
  infer_yaml(
    "
    pub fn apply(f, x) {
      f(x)
    }
    ",
  )
  |> birdie.snap(title: "higher order function test")
}

pub fn positional_pattern_with_spread_test() {
  infer_yaml(
    "
    pub type Triple(a) {
      Triple(a: a, b: a, c: a)
    }

    pub fn first(t: Triple(a)) {
      case t {
        Triple(x, ..) -> x
      }
    }
    ",
  )
  |> birdie.snap(title: "positional pattern with spread test")
}

pub fn list_pattern_test() {
  infer_yaml(
    "
    pub fn head(list) {
      case list {
        [] -> 0
        [x, ..] -> x
      }
    }
    ",
  )
  |> birdie.snap(title: "list pattern test")
}

pub fn recursive_custom_type_test() {
  infer_yaml(
    "
    pub type Tree(e) {
      Node(left: Tree(e), right: Tree(e))
      Leaf(data: e)
    }
    ",
  )
  |> birdie.snap(title: "recursive custom type test")
}

pub fn type_alias_test() {
  infer_yaml(
    "
    pub type Pair(a, b) = #(a, b)

    pub fn pair_of_pairs(p: Pair(a, b), q: Pair(a, b)) {
      #(p, q)
    }
    ",
  )
  |> birdie.snap(title: "type alias test")
}

pub fn field_access_test() {
  infer_yaml(
    "
    pub type Box(a) {
      Box(value: a)
    }

    pub fn get_value(b: Box(a)) {
      b.value
    }
    ",
  )
  |> birdie.snap(title: "field access test")
}

pub fn nested_field_access_test() {
  infer_yaml(
    "
    type Foo(a) {
      Foo(value: a)
    }

    pub fn get() {
      let a = Foo(Foo(1))
      a.value.value
    }
    ",
  )
  |> birdie.snap(title: "nested field access test")
}

pub fn pipe_with_labelled_arg_test() {
  infer_yaml(
    "
    pub fn write(to file, data string) {
      panic
    }
    pub fn get() {
      123
      |> write(to: \"foo\")
    }
    ",
  )
  |> birdie.snap(title: "pipe with labelled arg test")
}

pub fn fn_arg_field_access_test() {
  infer_yaml(
    "
    pub type Foo(a) {
      Foo(value: a)
    }

    fn apply(x: a, f: fn(a) -> b) -> b {
      f(x)
    }

    pub fn main() {
      apply(Foo(1), fn(foo) { foo.value })
    }
    ",
  )
  |> birdie.snap(title: "fn arg field access test")
}

pub fn imported_type_alias_test() {
  infer_with(
    option_dependencies(),
    "
    import gleam/option.{type Option}

    pub type OptionalInt = Option(Int)
    ",
    "example",
  )
  |> glance_typed_yaml.module_to_string
  |> birdie.snap(title: "imported type alias test")
}

pub fn imported_function_call_test() {
  infer_with(
    option_dependencies(),
    "
    import gleam/option

    pub fn optional_square(maybe) {
      option.map(maybe, fn(n) { n * n })
    }
    ",
    "example",
  )
  |> glance_typed_yaml.module_to_string
  |> birdie.snap(title: "imported function call test")
}

pub fn imported_constructor_pattern_test() {
  // TODO None -> None is being labeled as "function"
  // maybe it should be "constant" or something else?
  infer_with(
    option_dependencies(),
    "
    import gleam/option.{Some, None}

    pub fn optional_double(maybe) {
      case maybe {
        Some(n) -> Some(2 * n)
        None -> None
      }
    }
    ",
    "example",
  )
  |> glance_typed_yaml.module_to_string
  |> birdie.snap(title: "imported constructor pattern test")
}

pub fn int_literal_test() {
  infer_yaml("pub fn f() { 1 }")
  |> birdie.snap(title: "int literal test")
}

pub fn float_literal_test() {
  infer_yaml("pub fn f() { 1.0 }")
  |> birdie.snap(title: "float literal test")
}

pub fn string_literal_test() {
  infer_yaml("pub fn f() { \"hello\" }")
  |> birdie.snap(title: "string literal test")
}

pub fn bool_literal_test() {
  infer_yaml_with_prelude("pub fn f() { True }")
  |> birdie.snap(title: "bool literal test")
}

pub fn tuple_literal_test() {
  infer_yaml("pub fn f() { #(1, 1.0, \"a\") }")
  |> birdie.snap(title: "tuple literal test")
}

pub fn bit_array_test() {
  infer_yaml("pub fn f() { <<1, 2, 3>> }")
  |> birdie.snap(title: "bit array test")
}

pub fn tuple_index_test() {
  infer_yaml_with_prelude(
    "
    pub fn fst(t: #(Int, String)) { t.0 }
    pub fn snd(t: #(Int, String)) { t.1 }
    ",
  )
  |> birdie.snap(title: "tuple index test")
}

pub fn tuple_index_out_of_bounds_test() {
  infer_error_with_prelude("pub fn f(t: #(Int, String)) { t.2 }")
  |> typed.inspect_error
  |> birdie.snap(title: "tuple index out of bounds test")
}

pub fn anonymous_function_test() {
  infer_yaml("pub fn f() { fn(x) { x } }")
  |> birdie.snap(title: "anonymous function test")
}

pub fn let_binding_test() {
  infer_yaml(
    "
    pub fn f() {
      let x = 1
      x
    }
    ",
  )
  |> birdie.snap(title: "let binding test")
}

pub fn let_assert_test() {
  infer_yaml(
    "
    type Wrapper(a) { Wrapper(value: a) }

    pub fn unwrap(w: Wrapper(a)) {
      let assert Wrapper(v) = w
      v
    }
    ",
  )
  |> birdie.snap(title: "let assert test")
}

pub fn constant_int_test() {
  infer_yaml("pub const x = 42")
  |> birdie.snap(title: "constant int test")
}

pub fn constant_depends_on_constant_test() {
  infer_yaml(
    "
    const a = 1
    pub const b = a
    ",
  )
  |> birdie.snap(title: "constant depends on constant test")
}

pub fn polymorphic_identity_test() {
  infer_yaml("pub fn id(x) { x }")
  |> birdie.snap(title: "polymorphic identity test")
}

pub fn polymorphic_apply_test() {
  infer_yaml("pub fn apply(f, x) { f(x) }")
  |> birdie.snap(title: "polymorphic apply test")
}

pub fn list_literal_test() {
  infer_yaml("pub fn f() { [1, 2, 3] }")
  |> birdie.snap(title: "list literal test")
}

pub fn list_spread_test() {
  infer_yaml("pub fn f(xs) { [0, ..xs] }")
  |> birdie.snap(title: "list spread test")
}

pub fn case_without_annotation_test() {
  infer_yaml(
    "
    pub fn describe(x) {
      case x {
        0 -> \"zero\"
        _ -> \"other\"
      }
    }
    ",
  )
  |> birdie.snap(title: "case without annotation test")
}

pub fn case_multi_subject_test() {
  infer_yaml(
    "
    pub fn both_zero(a, b) {
      case a, b {
        0, 0 -> 1
        _, _ -> 0
      }
    }
    ",
  )
  |> birdie.snap(title: "case multi subject test")
}

pub fn case_guard_test() {
  infer_yaml_with_prelude(
    "
    pub fn is_positive(n: Int) {
      case n {
        x if x > 0 -> True
        _ -> False
      }
    }
    ",
  )
  |> birdie.snap(title: "case guard test")
}

pub fn case_tuple_pattern_test() {
  infer_yaml_with_prelude(
    "
    pub fn swap(t: #(Int, Bool)) {
      case t {
        #(n, b) -> #(b, n)
      }
    }
    ",
  )
  |> birdie.snap(title: "case tuple pattern test")
}

pub fn case_string_pattern_test() {
  infer_yaml_with_prelude(
    "
    pub fn greet(name: String) {
      case name {
        \"world\" -> \"Hello, world!\"
        _ -> \"Hi!\"
      }
    }
    ",
  )
  |> birdie.snap(title: "case string pattern test")
}

pub fn case_variable_pattern_test() {
  infer_yaml(
    "
    pub fn double(x) {
      case x {
        n -> n + n
      }
    }
    ",
  )
  |> birdie.snap(title: "case variable pattern test")
}

pub fn custom_type_constructor_test() {
  infer_yaml(
    "
    pub type Box(a) { Box(value: a) }

    pub fn box(x) { Box(x) }
    ",
  )
  |> birdie.snap(title: "custom type constructor test")
}

pub fn custom_type_pattern_match_test() {
  infer_yaml(
    "
    pub type Box(a) { Box(value: a) }

    pub fn unbox(b: Box(a)) {
      case b {
        Box(v) -> v
      }
    }
    ",
  )
  |> birdie.snap(title: "custom type pattern match test")
}

pub fn multi_variant_type_test() {
  infer_yaml(
    "
    pub type Shape(a) {
      Circle(radius: a)
      Rectangle(width: a, height: a)
    }
    ",
  )
  |> birdie.snap(title: "multi variant type test")
}

pub fn record_update_test() {
  infer_yaml(
    "
    pub type Point(a) { Point(x: a, y: a) }

    pub fn reset_x(p: Point(a), new_x: a) { Point(..p, x: new_x) }
    ",
  )
  |> birdie.snap(title: "record update test")
}

pub fn mutually_recursive_types_test() {
  infer_yaml(
    "
    pub type Forest(a) { Forest(head: Tree(a))  EmptyForest }
    pub type Tree(a) { Tree(value: a, children: Forest(a)) }
    ",
  )
  |> birdie.snap(title: "mutually recursive types test")
}

pub fn mutual_recursion_test() {
  infer_yaml(
    "
    pub fn count_even(n) {
      case n {
        0 -> 0
        _ -> count_odd(n - 1)
      }
    }

    pub fn count_odd(n) {
      case n {
        0 -> 1
        _ -> count_even(n - 1)
      }
    }
    ",
  )
  |> birdie.snap(title: "mutual recursion test")
}

pub fn function_call_with_labels_test() {
  infer_yaml_with_prelude(
    "
    pub fn add(x x: Int, to y: Int) -> Int { x + y }

    pub fn f() { add(x: 1, to: 2) }
    ",
  )
  |> birdie.snap(title: "function call with labels test")
}

pub fn nested_function_call_test() {
  infer_yaml_with_prelude(
    "
    pub fn apply_twice(f: fn(Int) -> Int, x: Int) {
      f(f(x))
    }
    ",
  )
  |> birdie.snap(title: "nested function call test")
}

pub fn type_alias_resolved_test() {
  infer_yaml_with_prelude(
    "
    pub type Alias(a) = a

    pub fn f(x: Alias(Int)) -> Int { x }
    ",
  )
  |> birdie.snap(title: "type alias resolved test")
}

pub fn panic_test() {
  infer_yaml_with_prelude("pub fn f() -> Int { panic }")
  |> birdie.snap(title: "panic test")
}

pub fn todo_test() {
  infer_yaml_with_prelude("pub fn f() -> Int { todo }")
  |> birdie.snap(title: "todo test")
}

pub fn block_expression_test() {
  infer_yaml(
    "
    pub fn f() {
      {
        let x = 1
        x
      }
    }
    ",
  )
  |> birdie.snap(title: "block expression test")
}

pub fn imported_type_in_annotation_test() {
  infer_with(
    option_dependencies(),
    "
    import gleam/option.{type Option}

    pub fn wrap(x: Int) -> Option(Int) {
      option.Some(x)
    }
    ",
    "example",
  )
  |> glance_typed_yaml.module_to_string
  |> birdie.snap(title: "imported type in annotation test")
}

pub fn call_non_function_test() {
  infer_error("pub fn f() { let x = 1  x(2) }")
  |> typed.inspect_error
  |> birdie.snap(title: "call non function test")
}

pub fn function_call_wrong_arity_test() {
  infer_error(
    "
    pub fn id(x) { x }
    pub fn f() { id(1, 2) }
    ",
  )
  |> typed.inspect_error
  |> birdie.snap(title: "function call wrong arity test")
}

pub fn unknown_variable_test() {
  infer_error("pub fn f() { x }")
  |> typed.inspect_error
  |> birdie.snap(title: "unknown variable test")
}

pub fn unresolved_type_test() {
  infer_error("pub fn f(x: Foo) { x }")
  |> typed.inspect_error
  |> birdie.snap(title: "unresolved type test")
}

pub fn incompatible_types_test() {
  infer_error("pub fn f() { case 1 { 1 -> 1  _ -> \"str\" } }")
  |> typed.inspect_error
  |> birdie.snap(title: "incompatible types test")
}

pub fn type_annotation_mismatch_test() {
  infer_error(
    "
    type A { A }
    type B { B }
    pub fn f(x: A) -> B { x }
    ",
  )
  |> typed.inspect_error
  |> birdie.snap(title: "type annotation mismatch test")
}

pub fn label_not_found_test() {
  infer_error(
    "
    pub fn id(x) { x }
    pub fn f() { id(y: 1) }
    ",
  )
  |> typed.inspect_error
  |> birdie.snap(title: "label not found test")
}

pub fn recursive_type_error_test() {
  infer_error(
    "
    pub fn f(x) {
      f(x(1))
    }
    ",
  )
  |> typed.inspect_error
  |> birdie.snap(title: "recursive type error test")
}

pub fn negate_int_test() {
  infer_yaml_with_prelude("pub fn f(n: Int) { -n }")
  |> birdie.snap(title: "negate int test")
}

pub fn negate_bool_test() {
  infer_yaml_with_prelude("pub fn f(b: Bool) { !b }")
  |> birdie.snap(title: "negate bool test")
}

pub fn echo_test() {
  infer_yaml("pub fn f() { echo 42 }")
  |> birdie.snap(title: "echo test")
}

pub fn panic_with_message_test() {
  infer_yaml_with_prelude("pub fn f() -> Int { panic as \"oops\" }")
  |> birdie.snap(title: "panic with message test")
}

pub fn todo_with_message_test() {
  infer_yaml_with_prelude("pub fn f() -> Int { todo as \"implement me\" }")
  |> birdie.snap(title: "todo with message test")
}

pub fn fn_capture_test() {
  infer_yaml_with_prelude(
    "
    pub fn add(x: Int, y: Int) -> Int { x + y }
    pub fn f() { add(1, _) }
    ",
  )
  |> birdie.snap(title: "fn capture test")
}

pub fn fn_capture_labelled_test() {
  infer_yaml_with_prelude(
    "
    pub fn add(x x: Int, to y: Int) -> Int { x + y }
    pub fn f() { add(to: _, x: 1) }
    ",
  )
  |> birdie.snap(title: "fn capture labelled test")
}

pub fn binary_operator_add_test() {
  infer_yaml_with_prelude("pub fn f(a: Int, b: Int) -> Int { a + b }")
  |> birdie.snap(title: "binary operator add test")
}

pub fn binary_operator_compare_test() {
  infer_yaml_with_prelude("pub fn f(a: Int, b: Int) -> Bool { a > b }")
  |> birdie.snap(title: "binary operator compare test")
}

pub fn binary_operator_string_concat_test() {
  infer_yaml_with_prelude("pub fn f(a: String, b: String) -> String { a <> b }")
  |> birdie.snap(title: "binary operator string concat test")
}

pub fn pipe_test() {
  infer_yaml_with_prelude(
    "
    pub fn double(n: Int) -> Int { n * 2 }
    pub fn f() -> Int { 5 |> double }
    ",
  )
  |> birdie.snap(title: "pipe test")
}

pub fn pipe_with_args_test() {
  infer_yaml_with_prelude(
    "
    fn sub(minuend m, subtrahend s) { m - s }
    pub fn f() {
      5
      |> sub(3)
      |> sub(8, _)
      |> sub(minuend: 8)
      |> echo
    }
    ",
  )
  |> birdie.snap(title: "pipe with args test")
}

pub fn use_statement_test() {
  infer_yaml_with_prelude(
    "
    pub fn with_value(callback: fn(Int) -> a) -> a {
      callback(42)
    }

    pub fn f() {
      use x <- with_value()
      x
    }
    ",
  )
  |> birdie.snap(title: "use statement test")
}

pub fn use_patterns_test() {
  infer_yaml_with_prelude(
    "
    fn with_square(n: Int, callback: fn(#(Int, Int), String) -> a) -> a {
      callback(#(2, n * n), \"square\")
    }

    pub fn f() {
      use #(_, square), _ <- with_square(3)
      square
    }
    ",
  )
  |> birdie.snap(title: "use patterns test")
}

pub fn pattern_assignment_test() {
  infer_yaml(
    "
    pub fn f(x) {
      case x {
        n as alias -> alias
      }
    }
    ",
  )
  |> birdie.snap(title: "pattern assignment test")
}

pub fn pattern_concatenate_test() {
  infer_yaml_with_prelude(
    "
    pub fn f(s: String) {
      case s {
        \"hello\" <> rest -> rest
        _ -> s
      }
    }
    ",
  )
  |> birdie.snap(title: "pattern concatenate test")
}

pub fn pattern_float_test() {
  infer_yaml_with_prelude(
    "
    pub fn f(x: Float) {
      case x {
        1.0 -> 1
        _ -> 0
      }
    }
    ",
  )
  |> birdie.snap(title: "pattern float test")
}

pub fn pattern_discard_test() {
  infer_yaml("pub fn f(x, _) { x }")
  |> birdie.snap(title: "pattern discard test")
}

pub fn pattern_bit_string_test() {
  infer_yaml_with_prelude(
    "
    pub fn f(bits: BitArray) {
      case bits {
        <<a, b, _rest:bytes>> -> a + b
        _ -> 0
      }
    }
    ",
  )
  |> birdie.snap(title: "pattern bit string test")
}

pub fn bit_string_with_options_test() {
  infer_yaml_with_prelude(
    "pub fn f(n: Int, s: String) { <<n:size(8), s:utf8>> }",
  )
  |> birdie.snap(title: "bit string with options test")
}

pub fn anonymous_fn_with_annotation_test() {
  infer_yaml_with_prelude("pub fn f() { fn(x: Int) -> Int { x } }")
  |> birdie.snap(title: "anonymous fn with annotation test")
}

pub fn let_binding_with_annotation_test() {
  infer_yaml_with_prelude(
    "
    pub fn f() {
      let x: Int = 1
      x
    }
    ",
  )
  |> birdie.snap(title: "let binding with annotation test")
}

pub fn constant_string_test() {
  infer_yaml("pub const s = \"hello\"")
  |> birdie.snap(title: "constant string test")
}

pub fn constant_float_test() {
  infer_yaml("pub const f = 3.14")
  |> birdie.snap(title: "constant float test")
}

pub fn constant_bool_test() {
  infer_yaml_with_prelude("pub const b = True")
  |> birdie.snap(title: "constant bool test")
}

pub fn external_function_test() {
  infer_yaml_with_prelude(
    "
    @external(erlang, \"mod\", \"fun\")
    pub fn my_func(x: Int) -> String
    ",
  )
  |> birdie.snap(title: "external function test")
}

pub fn empty_block_error_test() {
  infer_error("pub fn f() { {} }")
  |> typed.inspect_error
  |> birdie.snap(title: "empty block error test")
}

pub fn invalid_tuple_access_error_test() {
  infer_error_with_prelude("pub fn f(x: Int) { x.0 }")
  |> typed.inspect_error
  |> birdie.snap(title: "invalid tuple access error test")
}

pub fn invalid_field_access_error_test() {
  infer_error(
    "
    pub fn mk_tuple() { #(1, 2) }
    pub fn f() { mk_tuple().foo }
    ",
  )
  |> typed.inspect_error
  |> birdie.snap(title: "invalid field access error test")
}

pub fn field_not_found_error_test() {
  infer_error_with_prelude(
    "
    type A { A(x: Int) }
    pub fn mk_a() { A(1) }
    pub fn f() { mk_a().y }
    ",
  )
  |> typed.inspect_error
  |> birdie.snap(title: "field not found error test")
}

pub fn unresolved_module_error_test() {
  infer_error(
    "
    pub fn f() { unknown.foo }
    ",
  )
  |> typed.inspect_error
  |> birdie.snap(title: "unresolved module error test")
}

pub fn case_alternative_patterns_test() {
  infer_yaml_with_prelude(
    "
    pub fn f(x: Int) {
      case x {
        1 | 2 | 3 -> \"low\"
        _ -> \"other\"
      }
    }
    ",
  )
  |> birdie.snap(title: "case alternative patterns test")
}

pub fn module_alias_test() {
  infer_with(
    option_dependencies(),
    "
    import gleam/option as opt

    pub fn wrap(x: Int) {
      opt.Some(x)
    }
    ",
    "example",
  )
  |> glance_typed_yaml.module_to_string
  |> birdie.snap(title: "module alias test")
}

pub fn record_update_multiple_fields_test() {
  infer_yaml_with_prelude(
    "
    pub type Point { Point(x: Int, y: Int, z: Int) }

    pub fn reset(p: Point) { Point(..p, y: 0, x: 0) }
    ",
  )
  |> birdie.snap(title: "record update multiple fields test")
}

pub fn record_update_shorthand_test() {
  infer_yaml(
    "
    pub type Point(a) { Point(x: a, y: a) }

    pub fn copy_x(p: Point(a), x: a) { Point(..p, x:) }
    ",
  )
  |> birdie.snap(title: "record update shorthand test")
}

pub fn call_args_positional_test() {
  infer_yaml_with_prelude(
    "
    pub fn add(x: Int, y: Int, z: Int) -> Int { x }
    pub fn main() { add(1, 2, 3) }
    ",
  )
  |> birdie.snap(title: "call args positional test")
}

pub fn constructor_call_positional_test() {
  infer_yaml_with_prelude(
    "
    pub type Point { Point(x: Int, y: Int, z: Int) }
    pub fn main() { Point(1, 2, 3) }
    ",
  )
  |> birdie.snap(title: "constructor call positional test")
}

pub fn pattern_variant_positional_test() {
  infer_yaml_with_prelude(
    "
    pub type Point { Point(x: Int, y: Int, z: Int) }
    pub fn get_x(p: Point) {
      let Point(x, y, z) = p
      x
    }
    ",
  )
  |> birdie.snap(title: "pattern variant positional test")
}

pub fn constructor_call_args_out_of_order_test() {
  infer_yaml_with_prelude(
    "
    pub type Point { Point(x: Int, y: Int, z: Int) }
    pub fn main() { Point(z: 3, x: 1, y: 2) }
    ",
  )
  |> birdie.snap(title: "constructor call args out of order test")
}

pub fn pattern_variant_args_out_of_order_test() {
  infer_yaml_with_prelude(
    "
    pub type Point { Point(x: Int, y: Int, z: Int) }
    pub fn get_x(p: Point) {
      let Point(z: _, y: _, x: x) = p
      x
    }
    ",
  )
  |> birdie.snap(title: "pattern variant args out of order test")
}

pub fn record_update_fields_out_of_order_test() {
  infer_yaml_with_prelude(
    "
    pub type Point { Point(x: Int, y: Int, z: Int) }
    pub fn reset(p: Point, a: Int, b: Int, c: Int) {
      Point(..p, z: c, x: a, y: b)
    }
    ",
  )
  |> birdie.snap(title: "record update fields out of order test")
}

pub fn call_args_original_order_test() {
  let module =
    infer_with_prelude(
      "
      pub fn add(x x: Int, y y: Int, z z: Int) -> Int { x }
      pub fn main() { add(z: 3, x: 1, y: 2) }
      ",
    )
  let assert Ok(main_def) =
    list.find(module.functions, fn(d) { d.definition.name == "main" })
  let assert [typed.Expression(expression: call, ..)] = main_def.definition.body
  let assert typed.Call(arguments:, ..) = call

  let labels =
    list.map(arguments, fn(arg) {
      case arg {
        typed.LabelledField(..) -> arg.label
        typed.ShorthandField(..) -> arg.label
        typed.UnlabelledField(..) -> ""
      }
    })
  let assert ["z", "x", "y"] = labels
}

pub fn pattern_variant_args_original_order_test() {
  let module =
    infer_with_prelude(
      "
      pub type Point { Point(x: Int, y: Int, z: Int) }
      pub fn get_x(p: Point) {
        let Point(z: _, y: _, x: x) = p
        x
      }
      ",
    )
  let assert Ok(get_x_def) =
    list.find(module.functions, fn(d) { d.definition.name == "get_x" })
  let assert [typed.Assignment(pattern: pattern, ..), ..] =
    get_x_def.definition.body
  let assert typed.PatternVariant(arguments:, ..) = pattern

  let labels =
    list.filter_map(arguments, fn(arg) {
      case arg {
        typed.LabelledField(..) -> Ok(arg.label)
        typed.ShorthandField(..) -> Ok(arg.label)
        typed.UnlabelledField(..) -> Error(Nil)
      }
    })
  let assert ["z", "y", "x"] = labels
}

pub fn record_update_fields_original_order_test() {
  let module =
    infer_with_prelude(
      "
      pub type Point { Point(x: Int, y: Int, z: Int) }
      pub fn reset(p: Point, a: Int, b: Int, c: Int) {
        Point(..p, z: c, x: a, y: b)
      }
      ",
    )
  let assert Ok(reset_def) =
    list.find(module.functions, fn(d) { d.definition.name == "reset" })
  let assert [typed.Expression(expression: rec_update, ..)] =
    reset_def.definition.body
  let assert typed.RecordUpdate(fields:, ..) = rec_update

  let labels =
    list.map(fields, fn(f) {
      let typed.RecordUpdateField(label:, ..) = f
      label
    })
  let assert ["z", "x", "y"] = labels
}

pub fn call_args_shorthand_preserved_test() {
  let module =
    infer_with_prelude(
      "
      pub fn add(x x: Int, y y: Int) -> Int { x }
      pub fn main(x: Int, y: Int) { add(x:, y:) }
      ",
    )
  let assert Ok(main_def) =
    list.find(module.functions, fn(d) { d.definition.name == "main" })
  let assert [typed.Expression(expression: call, ..)] = main_def.definition.body
  let assert typed.Call(arguments:, ..) = call

  let kinds =
    list.map(arguments, fn(arg) {
      case arg {
        typed.LabelledField(..) -> "labelled"
        typed.ShorthandField(..) -> "shorthand"
        typed.UnlabelledField(..) -> "unlabelled"
      }
    })
  let assert ["shorthand", "shorthand"] = kinds
}

pub fn pattern_variant_shorthand_preserved_test() {
  let module =
    infer_with_prelude(
      "
      pub type Point { Point(x: Int, y: Int) }
      pub fn get(p: Point) {
        let Point(x:, y:) = p
        x
      }
      ",
    )
  let assert Ok(get_def) =
    list.find(module.functions, fn(d) { d.definition.name == "get" })
  let assert [typed.Assignment(pattern: pattern, ..), ..] =
    get_def.definition.body
  let assert typed.PatternVariant(arguments:, ..) = pattern

  let kinds =
    list.map(arguments, fn(arg) {
      case arg {
        typed.LabelledField(..) -> "labelled"
        typed.ShorthandField(..) -> "shorthand"
        typed.UnlabelledField(..) -> "unlabelled"
      }
    })
  let assert ["shorthand", "shorthand"] = kinds
}

pub fn use_imported_constant_test() {
  let deps =
    dict.from_list([
      #("gleam", typed.interface(typed.prelude_module())),
      #("mymod", infer_interface(dict.new(), "pub const answer = 42", "mymod")),
    ])
  infer_with(
    deps,
    "
    import mymod

    pub fn f() { mymod.answer }
    ",
    "example",
  )
  |> glance_typed_yaml.module_to_string
  |> birdie.snap(title: "use imported constant test")
}
