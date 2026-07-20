import glance.{Span} as g
import glance_typed/call_graph
import glance_typed/graph
import gleam/order

import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string

pub const prelude = "gleam"

pub const nil_type = NamedType(prelude, "Nil", [])

pub const bool_type = NamedType(prelude, "Bool", [])

pub const int_type = NamedType(prelude, "Int", [])

pub const codepoint_type = NamedType(prelude, "UtfCodepoint", [])

pub const float_type = NamedType(prelude, "Float", [])

pub const string_type = NamedType(prelude, "String", [])

pub const bit_array_type = NamedType(prelude, "BitArray", [])

pub type TypeVarId {
  TypeVarId(id: Int)
}

pub type TypeVar {
  Bound(Type)
  Unbound
}

pub type Definition(definition) {
  Definition(attributes: List(Attribute), definition: definition)
}

pub type Attribute {
  Attribute(name: String, arguments: List(AttributeArgument))
}

pub type AttributeArgument {
  NameAttributeArgument(name: String)
  StringAttributeArgument(value: String)
}

pub type Module {
  Module(
    name: String,
    imports: List(Definition(Import)),
    custom_types: List(Definition(CustomType)),
    type_aliases: List(Definition(TypeAlias)),
    constants: List(Definition(ConstantDefinition)),
    functions: List(Definition(FunctionDefinition)),
  )
}

/// The interface to a module without its implementation
pub type ModuleInterface {
  ModuleInterface(
    name: String,
    imports: List(String),
    custom_types: List(CustomType),
    type_aliases: List(TypeAlias),
    constants: List(ConstantDeclaration),
    functions: List(FunctionDeclaration),
  )
}

pub type FunctionDefinition {
  FunctionDefinition(
    typ: Poly,
    location: Span,
    name: String,
    publicity: Publicity,
    parameters: List(FunctionParameter),
    return: Option(Annotation),
    body: List(Statement),
  )
}

/// Declaration of a function for the ModuleInterface
pub type FunctionDeclaration {
  FunctionDeclaration(
    typ: Poly,
    name: String,
    parameters: List(FunctionParameter),
    return: Option(Annotation),
  )
}

pub type Span =
  g.Span

pub type Location {
  Location(module: String, definition: String, span: Span)
}

pub type Statement {
  Use(
    typ: Type,
    location: Span,
    patterns: List(UsePattern),
    function: Expression,
  )
  Assignment(
    typ: Type,
    location: Span,
    kind: AssignmentKind,
    pattern: Pattern,
    annotation: Option(Annotation),
    value: Expression,
  )
  Assert(
    typ: Type,
    location: Span,
    expression: Expression,
    message: Option(Expression),
  )
  Expression(typ: Type, location: Span, expression: Expression)
}

pub type AssignmentKind {
  Let
  LetAssert(message: Option(Expression))
}

pub type UsePattern {
  UsePattern(pattern: Pattern, annotation: Option(Annotation))
}

pub type Pattern {
  PatternInt(typ: Type, location: Span, value: String)
  PatternFloat(typ: Type, location: Span, value: String)
  PatternString(typ: Type, location: Span, value: String)
  PatternDiscard(typ: Type, location: Span, name: String)
  PatternVariable(typ: Type, location: Span, name: String)
  PatternTuple(typ: Type, location: Span, elements: List(Pattern))
  PatternList(
    typ: Type,
    location: Span,
    elements: List(Pattern),
    tail: Option(Pattern),
  )
  PatternAssignment(typ: Type, location: Span, pattern: Pattern, name: String)
  PatternConcatenate(
    typ: Type,
    location: Span,
    prefix: String,
    prefix_name: Option(AssignmentName),
    rest_name: AssignmentName,
  )
  PatternBitString(
    typ: Type,
    location: Span,
    segments: List(#(Pattern, List(BitStringSegmentOption(Pattern)))),
  )
  PatternVariant(
    typ: Type,
    location: Span,
    module: Option(String),
    constructor: String,
    arguments: List(Field(Pattern)),
    with_spread: Bool,
    resolved_module: String,
    positional_arguments: List(PatternVariantPositionalArgument),
  )
}

pub type RecordUpdateField(t) {
  RecordUpdateField(label: String, item: Option(t))
}

pub type RecordUpdatePositionalField {
  UpdatedField(expression: Expression)
  UnchangedField(typ: Type)
}

pub type PatternVariantPositionalArgument {
  MatchedArgument(pattern: Pattern)
  UnmatchedArgument(typ: Type)
}

pub type Expression {
  Int(typ: Type, location: Span, value: String)
  Float(typ: Type, location: Span, value: String)
  String(typ: Type, location: Span, value: String)
  LocalVariable(typ: Type, location: Span, name: String)
  Function(
    typ: Type,
    location: Span,
    module: String,
    name: String,
    labels: List(Option(String)),
  )
  Constant(typ: Type, location: Span, module: String, name: String)
  NegateInt(typ: Type, location: Span, value: Expression)
  NegateBool(typ: Type, location: Span, value: Expression)
  Block(typ: Type, location: Span, statements: List(Statement))
  Panic(typ: Type, location: Span, message: Option(Expression))
  Todo(typ: Type, location: Span, message: Option(Expression))
  Echo(
    typ: Type,
    location: Span,
    expression: Option(Expression),
    message: Option(Expression),
  )
  Tuple(typ: Type, location: Span, elements: List(Expression))
  List(
    typ: Type,
    location: Span,
    elements: List(Expression),
    rest: Option(Expression),
  )
  Fn(
    typ: Type,
    location: Span,
    parameters: List(FnParameter),
    return_annotation: Option(Annotation),
    body: List(Statement),
  )
  RecordUpdate(
    typ: Type,
    location: Span,
    module: Option(String),
    constructor: String,
    record: Expression,
    fields: List(RecordUpdateField(Expression)),
    resolved_module: String,
    positional_fields: List(RecordUpdatePositionalField),
  )
  FieldAccess(
    typ: Type,
    location: Span,
    container: Expression,
    label: String,
    module: String,
    constructor: String,
    index: Int,
  )
  Call(
    typ: Type,
    location: Span,
    function: Expression,
    arguments: List(Field(Expression)),
    positional_arguments: List(Expression),
  )
  TupleIndex(typ: Type, location: Span, tuple: Expression, index: Int)
  FnCapture(
    typ: Type,
    location: Span,
    label: Option(String),
    function: Expression,
    arguments_before: List(Field(Expression)),
    arguments_after: List(Field(Expression)),
  )
  BitString(
    typ: Type,
    location: Span,
    segments: List(#(Expression, List(BitStringSegmentOption(Expression)))),
  )
  Case(
    typ: Type,
    location: Span,
    subjects: List(Expression),
    clauses: List(Clause),
  )
  BinaryOperator(
    typ: Type,
    location: Span,
    name: BinaryOperator,
    left: Expression,
    right: Expression,
  )
  Pipe(typ: Type, location: Span, left: Expression, right: PipeInto)
}

pub type BinaryOperator {
  // Boolean logic
  And
  Or

  // Equality
  Eq
  NotEq

  // Order comparison
  LtInt
  LtEqInt
  LtFloat
  LtEqFloat
  GtEqInt
  GtInt
  GtEqFloat
  GtFloat

  // Maths
  AddInt
  AddFloat
  SubInt
  SubFloat
  MultInt
  MultFloat
  DivInt
  DivFloat
  RemainderInt

  // Strings
  Concatenate
}

pub type PipeInto {
  PipeIntoEcho(message: Option(Expression))
  PipeIntoFnCapture(
    label: Option(String),
    function: Expression,
    arguments_before: List(Field(Expression)),
    arguments_after: List(Field(Expression)),
  )
}

pub type Clause {
  Clause(
    patterns: List(List(Pattern)),
    guard: Option(Expression),
    body: Expression,
  )
}

pub type BitStringSegmentOption(t) {
  BytesOption
  IntOption
  FloatOption
  BitsOption
  Utf8Option
  Utf16Option
  Utf32Option
  Utf8CodepointOption
  Utf16CodepointOption
  Utf32CodepointOption
  SignedOption
  UnsignedOption
  BigOption
  LittleOption
  NativeOption
  SizeValueOption(t)
  SizeOption(Int)
  UnitOption(Int)
}

pub type FunctionParameter {
  FunctionParameter(
    typ: Type,
    label: Option(String),
    name: AssignmentName,
    annotation: Option(Annotation),
  )
}

pub type FnParameter {
  FnParameter(typ: Type, name: AssignmentName, annotation: Option(Annotation))
}

pub type AssignmentName {
  Named(value: String)
  Discarded(value: String)
}

pub type Import {
  Import(
    location: Span,
    module: String,
    alias: Option(AssignmentName),
    unqualified_types: List(UnqualifiedImport),
    unqualified_values: List(UnqualifiedImport),
  )
}

pub type ConstantDefinition {
  ConstantDefinition(
    typ: Poly,
    location: Span,
    name: String,
    publicity: Publicity,
    annotation: Option(Annotation),
    value: Expression,
  )
}

/// Declaration of a constant for the ModuleInterface
pub type ConstantDeclaration {
  ConstantDeclaration(typ: Poly, name: String, annotation: Option(Annotation))
}

pub type UnqualifiedImport {
  UnqualifiedImport(name: String, alias: Option(String))
}

pub type Publicity {
  Public
  Private
}

pub type TypeAlias {
  TypeAlias(
    typ: Poly,
    location: Span,
    name: String,
    publicity: Publicity,
    parameters: List(String),
    aliased: Annotation,
  )
}

pub type CustomType {
  CustomType(
    typ: Poly,
    location: Span,
    name: String,
    publicity: Publicity,
    opaque_: Bool,
    parameters: List(String),
    variants: List(Variant),
  )
}

pub type Variant {
  Variant(
    typ: Poly,
    name: String,
    fields: List(VariantField(Annotation)),
    attributes: List(Attribute),
  )
}

pub type Field(t) {
  LabelledField(item: t, label: String, label_location: Span)
  ShorthandField(item: t, label: String, location: Span)
  UnlabelledField(item: t)
}

pub type VariantField(t) {
  LabelledVariantField(item: t, label: String)
  UnlabelledVariantField(item: t)
}

pub type Type {
  NamedType(module: String, name: String, parameters: List(Type))
  TupleType(elements: List(Type))
  FunctionType(parameters: List(Type), return: Type)
  VariableType(ref: TypeVarId)
}

pub type Poly {
  Poly(vars: List(TypeVarId), typ: Type)
}

pub type Annotation {
  NamedAnno(
    typ: Type,
    location: Span,
    module: Option(String),
    name: String,
    parameters: List(Annotation),
  )
  TupleAnno(typ: Type, location: Span, elements: List(Annotation))
  FunctionAnno(
    typ: Type,
    location: Span,
    parameters: List(Annotation),
    return: Annotation,
  )
  VariableAnno(typ: Type, location: Span, name: String)
  HoleAnno(typ: Type, location: Span, name: String)
}

pub type Error {
  UnresolvedModule(location: Location, name: String)
  UnresolvedGlobal(location: Location, name: String)
  UnresolvedType(location: Location, name: String)
  UnresolvedFunction(location: Location, name: String)
  EmptyBlock(location: Location)
  InvalidTupleAccess(location: Location)
  InvalidFieldAccess(location: Location)
  FieldNotFound(location: Location, name: String)
  UnresolvedTypeVariable(location: Location, name: String)
  NotAFunction(location: Location, name: String)
  WrongArity(location: Location, expected_arg_count: Int, actual_arg_count: Int)
  LabelNotFound(location: Location, name: String)
  TupleIndexOutOfBounds(location: Location, tuple_size: Int, index: Int)
  IncompatibleTypes(location: Location, type_a: Type, type_b: Type)
  RecursiveTypeError(location: Location)
  BitPatternSegmentTypeOverSpecified(location: Location)
  InvalidAttributeArgument(location: Location)
}

type QName {
  QName(module: String, name: String)
}

type Context {
  Context(
    current_definition: String,
    current_span: Span,
    type_vars: Dict(TypeVarId, TypeVar),
    module: Module,
    type_uid: Int,
    temp_uid: Int,
    module_aliases: Dict(String, String),
    type_env: Dict(QName, #(Poly, List(Variant))),
    value_env: Dict(QName, ResolvedGlobal),
  )
}

type LocalEnv =
  Dict(String, Type)

type TypeEnv =
  Dict(String, Type)

/// Run type inference on a `glance.Module`.
/// Interfaces of all modules this module imports must be provided.
pub fn infer_module(
  modules: Dict(String, ModuleInterface),
  module: g.Module,
  module_name: String,
) -> Result(Module, Error) {
  let c =
    list.fold(
      dict.values(modules),
      new_context(module_name),
      add_module_interface,
    )

  // handle module imports
  use c <- result.try(
    list.try_fold(module.imports, c, fn(c, imp) {
      let imp = imp.definition
      let module_id = imp.module

      let module_aliases = case imp.alias {
        Some(alias) ->
          case alias {
            g.Named(alias) -> dict.insert(c.module_aliases, alias, module_id)
            g.Discarded(_) -> c.module_aliases
          }
        None -> {
          // assert: imported name is a non-empty string
          let assert Ok(alias) = list.last(string.split(module_id, "/"))
          dict.insert(c.module_aliases, alias, module_id)
        }
      }

      use type_env <- result.try(
        list.try_fold(imp.unqualified_types, c.type_env, fn(acc, imp) {
          use #(_, poly, variants) <- result.map(resolve_global_type_name(
            c,
            module_id,
            imp.name,
          ))
          let alias = case imp.alias {
            Some(alias) -> alias
            None -> imp.name
          }
          dict.insert(acc, QName(c.module.name, alias), #(poly, variants))
        }),
      )

      use value_env <- result.map(
        list.try_fold(imp.unqualified_values, c.value_env, fn(acc, imp) {
          use value <- result.map(resolve_global_name(c, module_id, imp.name))
          let alias = case imp.alias {
            Some(alias) -> alias
            None -> imp.name
          }
          dict.insert(acc, QName(c.module.name, alias), value)
        }),
      )

      Context(..c, module_aliases:, type_env:, value_env:)
    }),
  )

  // add types to env so they can reference eachother (but not yet constructors)
  let c =
    list.fold(module.custom_types, c, fn(c, def) {
      let custom = def.definition
      let c = Context(..c, current_definition: custom.name)
      let c = Context(..c, current_span: def.definition.location)

      let #(c, parameters) =
        list.fold(custom.parameters, #(c, []), fn(acc, p) {
          let #(c, l) = acc
          let #(c, typ) = new_type_var_ref(c)
          #(c, [#(p, typ), ..l])
        })
      let parameters = list.reverse(parameters)
      let param_types = list.map(parameters, fn(x) { x.1 })
      let typ = NamedType(c.module.name, custom.name, param_types)
      let typ = generalise(c, typ)

      register_type(c, def.definition.name, typ, [])
    })

  // add types aliases to env so they can reference eachother
  let c =
    list.fold(module.type_aliases, c, fn(c, def) {
      let #(c, typ) = new_type_var_ref(c)
      register_type(c, def.definition.name, Poly([], typ), [])
    })

  // infer type aliases fr fr
  use #(c, aliases) <- result.try(
    list.try_fold(module.type_aliases, #(c, []), fn(acc, def) {
      let #(c, aliases) = acc
      let c = Context(..c, current_definition: def.definition.name)
      let c = Context(..c, current_span: def.definition.location)

      // infer the alias type
      use #(c, alias) <- result.try(infer_alias_type(c, def.definition))

      // update the placeholder type
      use #(_, placeholder, _) <- result.try(resolve_global_type_name(
        c,
        c.module.name,
        alias.name,
      ))
      use c <- result.map(unify(c, alias.aliased.typ, placeholder.typ))

      #(c, [#(def, alias), ..aliases])
    }),
  )

  // create alias entries
  // we have to do this in two stages to make sure we genralize correctly
  use c <- result.try(
    list.try_fold(aliases, c, fn(c, alias) {
      let #(def, alias) = alias
      let c = Context(..c, current_definition: alias.name)
      let c = Context(..c, current_span: def.definition.location)

      // create alias entry
      let poly = generalise(c, alias.aliased.typ)
      let c = register_type(c, alias.name, poly, [])
      use attrs <- result.map(infer_attributes(c, def.attributes))
      let def = Definition(attrs, alias)
      update_module(c, fn(mod) {
        Module(..mod, type_aliases: [def, ..mod.type_aliases])
      })
    }),
  )

  // now infer custom types fr fr
  use c <- result.try(
    list.try_fold(module.custom_types, c, fn(c, def) {
      let custom = def.definition
      let c = Context(..c, current_definition: custom.name)
      let c = Context(..c, current_span: def.definition.location)

      // reconstruct the type parameters
      use #(_, poly, _) <- result.try(resolve_global_type_name(
        c,
        c.module.name,
        custom.name,
      ))
      let param_types = list.map(poly.vars, fn(x) { VariableType(x) })
      let parameters = list.zip(custom.parameters, param_types)

      // infer the custom type including variants
      use #(c, custom) <- result.try(infer_custom_type(
        c,
        def.definition,
        parameters,
      ))
      let c = register_type(c, custom.name, custom.typ, custom.variants)
      use attrs <- result.map(infer_attributes(c, def.attributes))
      let def = Definition(attrs, custom)
      update_module(c, fn(mod) {
        Module(..mod, custom_types: [def, ..mod.custom_types])
      })
    }),
  )

  let constants =
    call_graph.constant_graph(module)
    |> graph.strongly_connected_components()
    |> list.flatten()
    |> list.filter_map(fn(name) {
      module.constants
      |> list.find(fn(c) { c.definition.name == name })
    })

  // add functions to global env so they are available for recursion
  use c <- result.try(
    list.try_fold(module.functions, c, fn(c, def) {
      let fun = def.definition
      let c = Context(..c, current_definition: fun.name)
      let c = Context(..c, current_span: def.definition.location)

      // create placeholder function type based on function signature
      use #(c, parameters, return) <- result.map(infer_function_parameters(
        c,
        fun.parameters,
        fun.return,
      ))

      let #(c, return_type) = annotation_type_or_new(c, return)

      let param_types = list.map(parameters, fn(param) { param.typ })
      let param_labels = list.map(parameters, fn(f) { f.label })
      let typ = FunctionType(param_types, return_type)

      register_function(c, def.definition.name, Poly([], typ), param_labels)
    }),
  )

  // infer constant expressions
  use c <- result.try(
    list.try_fold(constants, c, fn(c, def) {
      use #(c, constant) <- result.try(infer_constant(c, def.definition))
      let c = Context(..c, current_definition: constant.name)
      let c = Context(..c, current_span: def.definition.location)

      let poly = generalise(c, constant.value.typ)
      let c = register_constant(c, constant.name, poly)
      use attrs <- result.map(infer_attributes(c, def.attributes))
      let def = Definition(attrs, constant)
      update_module(c, fn(mod) {
        Module(..mod, constants: [def, ..mod.constants])
      })
    }),
  )

  // create a function call graph to group mutually recursive functions
  // these will be type checked/inferred together as a group
  let rec_groups =
    call_graph.function_graph(module)
    |> graph.strongly_connected_components()

  use c <- result.map(
    list.try_fold(rec_groups, c, fn(c, group) {
      // find the function definitions by name
      use group <- result.try(
        list.try_map(group, fn(fun_name) {
          list.find(module.functions, fn(f) { f.definition.name == fun_name })
          |> result.replace_error(UnresolvedFunction(
            context_location(c),
            fun_name,
          ))
        }),
      )

      // infer types for the group
      use #(c, group) <- result.try(
        list.try_fold(group, #(c, []), fn(acc, def) {
          let #(c, group) = acc
          let c = Context(..c, current_definition: def.definition.name)
          let c = Context(..c, current_span: def.definition.location)

          // infer function
          use #(c, fun) <- result.try(infer_function(c, def.definition))
          use attrs <- result.map(infer_attributes(c, def.attributes))
          let def = Definition(attrs, fun)

          #(c, [def, ..group])
        }),
      )

      // generalise
      list.try_fold(group, c, fn(c, def) {
        let fun = def.definition

        // unify placeholder type
        use placeholder <- result.try(resolve_global_name(
          c,
          c.module.name,
          fun.name,
        ))
        use c <- result.map(unify(c, placeholder.typ.typ, fun.typ.typ))

        // generalise
        let typ = generalise(c, fun.typ.typ)
        let fun = FunctionDefinition(..fun, typ:)
        let def = Definition(..def, definition: fun)

        // update context
        let labels = list.map(fun.parameters, fn(f) { f.label })
        let c = register_function(c, fun.name, fun.typ, labels)
        update_module(c, fn(mod) {
          Module(..mod, functions: [def, ..mod.functions])
        })
      })
    }),
  )

  // Fully resolve all type references
  let mod = c.module
  let type_aliases =
    list.map(mod.type_aliases, map_definition(_, substitute_type_alias(c, _)))
  let custom_types =
    list.map(mod.custom_types, map_definition(_, substitute_custom_type(c, _)))
  let constants =
    list.map(mod.constants, map_definition(_, substitute_constant(c, _)))
  let functions =
    list.map(mod.functions, map_definition(_, substitute_function(c, _)))
  Module(..mod, type_aliases:, custom_types:, constants:, functions:)
}

pub fn interface(module: Module) -> ModuleInterface {
  ModuleInterface(
    name: module.name,
    imports: list.map(module.imports, fn(i) { i.definition.module }),
    custom_types: list.map(module.custom_types, fn(t) { t.definition }),
    type_aliases: list.map(module.type_aliases, fn(t) { t.definition }),
    constants: list.filter(module.constants, fn(c) {
      c.definition.publicity == Public
    })
      |> list.map(fn(c) {
        ConstantDeclaration(
          typ: c.definition.typ,
          name: c.definition.name,
          annotation: c.definition.annotation,
        )
      }),
    functions: list.filter(module.functions, fn(f) {
      f.definition.publicity == Public
    })
      |> list.map(fn(f) {
        FunctionDeclaration(
          typ: f.definition.typ,
          name: f.definition.name,
          parameters: f.definition.parameters,
          return: f.definition.return,
        )
      }),
  )
}

/// Returns the Module for the Gleam prelude (the "gleam" module).
/// This includes built-in types like Int, Float, String, Bool, Nil, List,
/// Result, BitArray, and UtfCodepoint, along with their constructors.
pub fn prelude_module() -> Module {
  let prelude_source =
    "
    pub type Int
    pub type Float
    pub type String
    pub type Bool { True False }
    pub type Nil { Nil }
    pub type List(a) { NonEmpty(head: a, tail: List(a)) Empty }
    pub type Result(value, error) { Ok(value) Error(error) }
    pub type BitArray
    pub type UtfCodepoint
    "
  let assert Ok(parsed) = g.module(prelude_source)
  let assert Ok(module) = infer_module(dict.new(), parsed, prelude)
  module
}

fn new_context(module_name: String) -> Context {
  Context(
    current_definition: "",
    current_span: Span(0, 0),
    type_vars: dict.new(),
    module: Module(
      imports: [],
      custom_types: [],
      type_aliases: [],
      constants: [],
      functions: [],
      name: module_name,
    ),
    type_uid: 0,
    temp_uid: 1,
    module_aliases: dict.new(),
    type_env: dict.new(),
    value_env: dict.new(),
  )
}

/// Returns a human-readable string description of the error.
/// Does not include the span (location) of the error.
pub fn inspect_error(error: Error) {
  // TODO I think we actually can't tell the difference between unresolved
  // module and unresolved global (and maybe others?). Should we merge the errors?
  case error {
    UnresolvedModule(name:, ..) -> "Module with name '" <> name <> "' not found"
    UnresolvedGlobal(name:, ..) -> "Global with name '" <> name <> "' not found"
    UnresolvedType(name:, ..) -> "Type with name '" <> name <> "' not found"
    UnresolvedFunction(name:, ..) ->
      "Function with name '" <> name <> "' not found"
    EmptyBlock(..) -> "Block is empty"
    InvalidTupleAccess(..) -> "Attempted tuple access on a non-tuple type"
    InvalidFieldAccess(..) -> "Attempted field access on a non-record type"
    FieldNotFound(name:, ..) ->
      "This record does not have a field named '" <> name <> "'"
    UnresolvedTypeVariable(name:, ..) ->
      "Type variable with name '" <> name <> "' not found"
    NotAFunction(name:, ..) -> "The variable '" <> name <> "' is not a function"
    WrongArity(expected_arg_count:, actual_arg_count:, ..) ->
      "Function with arity "
      <> int.to_string(expected_arg_count)
      <> " called with "
      <> int.to_string(actual_arg_count)
      <> " arguments"
    LabelNotFound(name:, ..) ->
      "The called function does not have an argument with label '"
      <> name
      <> "'"
    TupleIndexOutOfBounds(tuple_size:, index:, ..) ->
      "Tuple index "
      <> int.to_string(index)
      <> " exceeds the size of the tuple ("
      <> int.to_string(tuple_size)
      <> ")"
    IncompatibleTypes(type_a:, type_b:, ..) ->
      "Incompatible types: a = "
      <> string.inspect(type_a)
      <> ", b = "
      <> string.inspect(type_b)
    RecursiveTypeError(..) ->
      "Encountered a cyclical dependency between type variables"
    BitPatternSegmentTypeOverSpecified(..) ->
      "Bit pattern segment type set multiple times"
    InvalidAttributeArgument(..) ->
      "Unexpected expression for attribute argument (only variable or string are allowed)"
  }
}

fn generalise(c: Context, typ: Type) {
  let tvs =
    list.unique(find_tvs(c, typ))
    |> list.sort(type_var_id_compare)
  Poly(tvs, typ)
}

fn type_var_id_compare(a: TypeVarId, b: TypeVarId) -> order.Order {
  int.compare(a.id, b.id)
}

fn update_module(c: Context, fun: fn(Module) -> Module) {
  Context(..c, module: fun(c.module))
}

fn register_function(
  c: Context,
  name: String,
  typ: Poly,
  labels: List(Option(String)),
) -> Context {
  let value_env =
    dict.insert(
      c.value_env,
      QName(c.module.name, name),
      FunctionGlobal(c.module.name, name, typ, labels),
    )
  Context(..c, value_env:)
}

fn register_constant(c: Context, name: String, typ: Poly) -> Context {
  let value_env =
    dict.insert(
      c.value_env,
      QName(c.module.name, name),
      ConstantGlobal(c.module.name, name, typ),
    )
  Context(..c, value_env:)
}

fn register_type(
  c: Context,
  name: String,
  typ: Poly,
  variants: List(Variant),
) -> Context {
  let type_env =
    dict.insert(c.type_env, QName(c.module.name, name), #(typ, variants))
  Context(..c, type_env:)
}

fn infer_attributes(c: Context, attrs: List(g.Attribute)) {
  list.try_map(attrs, fn(attr) {
    use args <- result.map(
      list.try_map(attr.arguments, map_attribute_argument(c, _)),
    )
    Attribute(attr.name, args)
  })
}

fn map_attribute_argument(
  c: Context,
  expr: g.Expression,
) -> Result(AttributeArgument, Error) {
  let c = Context(..c, current_span: expr.location)
  case expr {
    g.String(value:, ..) -> Ok(StringAttributeArgument(value))
    g.Variable(name:, ..) -> Ok(NameAttributeArgument(name))
    _ -> Error(InvalidAttributeArgument(context_location(c)))
  }
}

fn infer_constant(
  c: Context,
  con: g.Constant,
) -> Result(#(Context, ConstantDefinition), Error) {
  use #(c, value) <- result.try(infer_expression(c, dict.new(), con.value))

  let publicity = case con.publicity {
    g.Public -> Public
    g.Private -> Private
  }

  use #(c, annotation) <- result.map(infer_optional_annotation(
    c,
    dict.new(),
    con.annotation,
  ))

  let poly = generalise(c, value.typ)

  let constant =
    ConstantDefinition(
      poly,
      con.location,
      con.name,
      publicity,
      annotation,
      value,
    )

  #(c, constant)
}

fn infer_function(
  c: Context,
  fun: g.Function,
) -> Result(#(Context, FunctionDefinition), Error) {
  use #(c, parameters, return) <- result.try(infer_function_parameters(
    c,
    fun.parameters,
    fun.return,
  ))

  let #(c, return_type) = annotation_type_or_new(c, return)

  // put params into local env
  let n =
    list.fold(parameters, dict.new(), fn(n, param) {
      case param.name {
        Named(name) -> dict.insert(n, name, param.typ)
        Discarded(_) -> n
      }
    })

  // infer body
  use #(c, body) <- result.try(infer_body(c, n, fun.body))

  // compute function type
  let parameter_types = list.map(parameters, fn(x) { x.typ })
  let typ = FunctionType(parameter_types, return_type)

  // unify the return type with the last statement
  use c <- result.map(case list.last(body) {
    Ok(statement) -> unify(c, return_type, statement.typ)
    Error(_) -> Ok(c)
  })

  let name = fun.name

  let publicity = case fun.publicity {
    g.Public -> Public
    g.Private -> Private
  }

  let location = Span(fun.location.start, fun.location.end)

  let typ = Poly([], typ)

  let fun =
    FunctionDefinition(
      typ:,
      location:,
      name:,
      publicity:,
      parameters:,
      return:,
      body:,
    )
  #(c, fun)
}

fn infer_alias_type(
  c: Context,
  alias: g.TypeAlias,
) -> Result(#(Context, TypeAlias), Error) {
  let publicity = case alias.publicity {
    g.Public -> Public
    g.Private -> Private
  }

  let parameters = alias.parameters

  // create an env for the type variables
  let #(c, type_env, args) =
    list.fold(parameters, #(c, dict.new(), []), fn(acc, name) {
      let #(c, n, args) = acc
      let #(c, typ) = new_type_var_ref(c)
      let n = dict.insert(n, name, typ)
      // assert: new_type_var_ref always returns a VariableType
      let assert VariableType(ref) = typ
      #(c, n, [ref, ..args])
    })
  let args = list.reverse(args)

  use #(c, aliased) <- result.map(do_infer_annotation(
    c,
    type_env,
    alias.aliased,
  ))

  let poly = Poly(args, aliased.typ)

  let alias =
    TypeAlias(poly, alias.location, alias.name, publicity, parameters, aliased)

  #(c, alias)
}

fn infer_custom_type(
  c: Context,
  custom: g.CustomType,
  parameters: List(#(String, Type)),
) {
  // create a type variable for each parameter
  // these will be used when a field references a type parameter
  let param_types = list.map(parameters, fn(x) { x.1 })
  let module = c.module.name
  let name = custom.name
  let typ = NamedType(module:, name:, parameters: param_types)

  let location = custom.location

  // create an env for param types
  let n =
    list.fold(parameters, dict.new(), fn(n, p) { dict.insert(n, p.0, p.1) })

  // process each variant
  use #(c, variants) <- result.map(
    list.try_fold(custom.variants, #(c, []), fn(acc, variant) {
      let #(c, l) = acc
      use #(c, v) <- result.map(infer_variant(c, n, typ, variant))
      #(c, [v, ..l])
    }),
  )
  let variants = list.reverse(variants)

  let opaque_ = custom.opaque_
  let publicity = case custom.publicity {
    g.Public -> Public
    g.Private -> Private
  }
  let parameters = custom.parameters

  let typ = generalise(c, typ)

  let custom =
    CustomType(
      typ:,
      location:,
      opaque_:,
      name:,
      publicity:,
      parameters:,
      variants:,
    )

  #(c, custom)
}

fn infer_variant(
  c,
  n,
  typ: Type,
  variant: g.Variant,
) -> Result(#(Context, Variant), Error) {
  use #(c, fields) <- result.try(
    list.try_fold(variant.fields, #(c, []), fn(acc, field) {
      let #(c, fields) = acc
      use #(c, annotation) <- result.map(do_infer_annotation(c, n, field.item))
      let field = case field {
        g.LabelledVariantField(_, label) ->
          LabelledVariantField(annotation, label)
        g.UnlabelledVariantField(_) -> UnlabelledVariantField(annotation)
      }
      #(c, [field, ..fields])
    }),
  )
  let fields = list.reverse(fields)

  let types = list.map(fields, fn(f) { f.item.typ })
  let labels = list.map(fields, variant_field_label)

  // handle 0 parameter variants are not functions
  let #(c, typ) = case types {
    [] -> #(c, typ)
    _ -> #(c, FunctionType(types, typ))
  }

  let typ = generalise(c, typ)

  let c = register_function(c, variant.name, typ, labels)

  use attributes <- result.map(infer_attributes(c, variant.attributes))
  #(c, Variant(typ, variant.name, fields, attributes))
}

fn find_vars_in_type(t: g.Type) -> List(String) {
  case t {
    g.NamedType(_, _name, _module, parameters) ->
      list.flat_map(parameters, find_vars_in_type)
    g.TupleType(_, elements) -> list.flat_map(elements, find_vars_in_type)
    g.FunctionType(_, parameters, return) ->
      list.flat_map([return, ..parameters], find_vars_in_type)
    g.VariableType(_, name) -> [name]
    g.HoleType(_, _) -> []
  }
}

fn infer_function_parameters(
  c: Context,
  parameters: List(g.FunctionParameter),
  return: Option(g.Type),
) -> Result(#(Context, List(FunctionParameter), Option(Annotation)), Error) {
  let #(c, type_env) =
    build_type_env(c, list.map(parameters, fn(p) { p.type_ }), return)

  // create type vars for parameters
  use #(c, params) <- result.try(
    list.try_fold(parameters, #(c, []), fn(acc, param) {
      let #(c, param_types) = acc

      let label = param.label

      let name = convert_assignment_name(param.name)

      use #(c, annotation) <- result.map(infer_optional_annotation(
        c,
        type_env,
        param.type_,
      ))

      let #(c, typ) = annotation_type_or_new(c, annotation)

      #(c, [FunctionParameter(typ, label, name, annotation), ..param_types])
    }),
  )
  let params = list.reverse(params)

  // handle function return type
  use #(c, return) <- result.map(infer_optional_annotation(c, type_env, return))

  #(c, params, return)
}

fn infer_optional_annotation(
  c: Context,
  n: TypeEnv,
  typ: Option(g.Type),
) -> Result(#(Context, Option(Annotation)), Error) {
  case typ {
    Some(typ) -> {
      use #(c, anno) <- result.map(do_infer_annotation(c, n, typ))
      #(c, Some(anno))
    }
    None -> Ok(#(c, None))
  }
}

fn build_type_env(
  c: Context,
  param_types: List(Option(g.Type)),
  return_type: Option(g.Type),
) -> #(Context, Dict(String, Type)) {
  let vars =
    list.flat_map(param_types, fn(t) {
      case t {
        Some(typ) -> find_vars_in_type(typ)
        None -> []
      }
    })
  let vars = case return_type {
    Some(ret) -> list.append(find_vars_in_type(ret), vars)
    None -> vars
  }
  let vars = list.unique(vars)
  list.fold(vars, #(c, dict.new()), fn(acc, name) {
    let #(c, n) = acc
    let #(c, typ) = new_type_var_ref(c)
    let n = dict.insert(n, name, typ)
    #(c, n)
  })
}

fn do_infer_annotation(
  c: Context,
  n: TypeEnv,
  typ: g.Type,
) -> Result(#(Context, Annotation), Error) {
  case typ {
    g.NamedType(location:, name:, module:, parameters:) -> {
      use #(c, params) <- result.try(
        list.try_fold(parameters, #(c, []), fn(acc, p) {
          let #(c, l) = acc
          use #(c, p) <- result.map(do_infer_annotation(c, n, p))
          #(c, [p, ..l])
        }),
      )
      let params = list.reverse(params)

      // instantiate the polymorphic type with the parameter types
      use #(_, poly, _variants) <- result.try(resolve_type_name(c, module, name))
      let param_types = list.map(params, fn(param) { param.typ })
      use mapping <- result.map(
        list.strict_zip(poly.vars, param_types)
        |> result.map_error(fn(_) {
          WrongArity(
            context_location(c),
            list.length(poly.vars),
            list.length(param_types),
          )
        })
        |> result.map(dict.from_list),
      )
      let typ = do_instantiate(c, mapping, poly.typ)
      #(c, NamedAnno(typ, location, module, name, params))
    }
    g.TupleType(location:, elements:) -> {
      use #(c, elements) <- result.map(
        list.try_fold(elements, #(c, []), fn(acc, p) {
          let #(c, l) = acc
          use #(c, p) <- result.map(do_infer_annotation(c, n, p))
          #(c, [p, ..l])
        }),
      )
      let elements = list.reverse(elements)
      let typ = TupleType(list.map(elements, fn(x) { x.typ }))
      #(c, TupleAnno(typ, location, elements))
    }
    g.FunctionType(location:, parameters:, return:) -> {
      use #(c, params) <- result.try(
        list.try_fold(parameters, #(c, []), fn(acc, p) {
          let #(c, l) = acc
          use #(c, p) <- result.map(do_infer_annotation(c, n, p))
          #(c, [p, ..l])
        }),
      )
      let params = list.reverse(params)
      use #(c, ret) <- result.map(do_infer_annotation(c, n, return))
      let typ = FunctionType(list.map(params, fn(x) { x.typ }), ret.typ)
      #(c, FunctionAnno(typ, location, params, ret))
    }
    g.VariableType(location:, name:) -> {
      use typ <- result.map(
        dict.get(n, name)
        |> result.replace_error(UnresolvedTypeVariable(
          context_location(c),
          name,
        )),
      )
      #(c, VariableAnno(typ, location, name))
    }
    g.HoleType(location:, name:) -> {
      let #(c, typ) = new_type_var_ref(c)
      Ok(#(c, HoleAnno(typ, location, name)))
    }
  }
}

fn add_module_interface(c: Context, m: ModuleInterface) -> Context {
  let value_env =
    list.fold(m.constants, c.value_env, fn(value_env, constant) {
      dict.insert(
        value_env,
        QName(m.name, constant.name),
        ConstantGlobal(m.name, constant.name, constant.typ),
      )
    })
  let value_env =
    list.fold(m.functions, value_env, fn(value_env, function) {
      dict.insert(
        value_env,
        QName(m.name, function.name),
        FunctionGlobal(
          m.name,
          function.name,
          function.typ,
          list.map(function.parameters, fn(f) { f.label }),
        ),
      )
    })
  let value_env =
    list.flat_map(m.custom_types, fn(custom_type) { custom_type.variants })
    |> list.fold(value_env, fn(value_env, variant) {
      dict.insert(
        value_env,
        QName(m.name, variant.name),
        FunctionGlobal(
          m.name,
          variant.name,
          variant.typ,
          list.map(variant.fields, variant_field_label),
        ),
      )
    })

  let type_env =
    list.fold(m.custom_types, c.type_env, fn(type_env, custom_type) {
      dict.insert(type_env, QName(m.name, custom_type.name), #(
        custom_type.typ,
        custom_type.variants,
      ))
    })

  let type_env =
    list.fold(m.type_aliases, type_env, fn(type_env, type_alias) {
      dict.insert(
        type_env,
        QName(m.name, type_alias.name),
        #(type_alias.typ, []),
      )
    })

  Context(..c, value_env:, type_env:)
}

pub type ResolvedGlobal {
  FunctionGlobal(
    module: String,
    name: String,
    typ: Poly,
    labels: List(Option(String)),
  )
  ConstantGlobal(module: String, name: String, typ: Poly)
}

type ResolvedVariable {
  ResolvedLocal(name: String, typ: Type)
  ResolvedGlobal(global: ResolvedGlobal)
}

/// Resolve an unqualified name against the local and then global environment.
fn resolve_unqualified_name(
  c: Context,
  n: LocalEnv,
  name: String,
) -> Result(ResolvedVariable, Error) {
  dict.get(n, name)
  |> result.map(ResolvedLocal(name, _))
  |> result.try_recover(fn(_) {
    resolve_unqualified_global(c, name) |> result.map(ResolvedGlobal)
  })
}

/// Resolve an unqualified name against the global environment.
fn resolve_unqualified_global(
  c: Context,
  name: String,
) -> Result(ResolvedGlobal, Error) {
  // try global env
  resolve_global_name(c, c.module.name, name)
  |> result.try_recover(fn(_) {
    // try prelude
    resolve_global_name(c, prelude, name)
  })
}

/// Resolve a global from a possibly aliased module
fn resolve_aliased_global(
  c: Context,
  name: QName,
) -> Result(ResolvedGlobal, Error) {
  resolve_module(c, name.module)
  |> result.try(resolve_global_name(c, _, name.name))
}

/// Resolve a name from the global environment
fn resolve_global_name(
  c: Context,
  module_name: String,
  name: String,
) -> Result(ResolvedGlobal, Error) {
  dict.get(c.value_env, QName(module_name, name))
  |> result.replace_error(UnresolvedGlobal(context_location(c), name))
}

/// Resolve a type name from the global environment
fn resolve_type_name(
  c: Context,
  mod: Option(String),
  name: String,
) -> Result(#(QName, Poly, List(Variant)), Error) {
  case mod {
    Some(mod) -> resolve_aliased_type_name(c, mod, name)
    None ->
      resolve_global_type_name(c, c.module.name, name)
      |> result.try_recover(fn(_) { resolve_global_type_name(c, prelude, name) })
  }
}

/// Resolve a type name from a possibly aliased module
fn resolve_aliased_type_name(
  c: Context,
  module: String,
  name: String,
) -> Result(#(QName, Poly, List(Variant)), Error) {
  resolve_module(c, module)
  |> result.try(resolve_global_type_name(c, _, name))
}

// Resolve a type name from a fully qualified module name
fn resolve_global_type_name(
  c: Context,
  module_name: String,
  name: String,
) -> Result(#(QName, Poly, List(Variant)), Error) {
  dict.get(c.type_env, QName(module_name, name))
  |> result.replace_error(UnresolvedType(
    context_location(c),
    module_name <> "." <> name,
  ))
  |> result.map(fn(t) { #(QName(module_name, name), t.0, t.1) })
}

/// Resolve a qualified or unqualified contructor name
fn resolve_constructor_name(c: Context, mod: Option(String), name: String) {
  case mod {
    Some(mod) -> resolve_aliased_global(c, QName(mod, name))
    None -> resolve_unqualified_global(c, name)
  }
}

/// Resolve a module alias to its fully qualified name
fn resolve_module(c: Context, module_name: String) -> Result(String, Error) {
  dict.get(c.module_aliases, module_name)
  |> result.replace_error(UnresolvedModule(context_location(c), module_name))
}

fn new_temp_var(c: Context) -> #(Context, String) {
  let id = "T" <> int.to_string(c.temp_uid)
  #(Context(..c, temp_uid: c.temp_uid + 1), id)
}

fn new_type_var_ref(c: Context) {
  let ref = TypeVarId(c.type_uid)
  let type_vars = dict.insert(c.type_vars, ref, Unbound)
  let typ = VariableType(ref)
  #(Context(..c, type_vars: type_vars, type_uid: c.type_uid + 1), typ)
}

fn annotation_type_or_new(c: Context, annotation: Option(Annotation)) {
  case annotation {
    Some(a) -> #(c, a.typ)
    None -> new_type_var_ref(c)
  }
}

fn convert_assignment_name(name: g.AssignmentName) -> AssignmentName {
  case name {
    g.Named(s) -> Named(s)
    g.Discarded(s) -> Discarded(s)
  }
}

fn infer_pattern(
  c: Context,
  n: LocalEnv,
  pattern: g.Pattern,
) -> Result(#(Context, LocalEnv, Pattern), Error) {
  case pattern {
    g.PatternInt(location:, value:) ->
      Ok(#(c, n, PatternInt(int_type, location, value)))
    g.PatternFloat(location:, value:) ->
      Ok(#(c, n, PatternFloat(float_type, location, value)))
    g.PatternString(location:, value:) ->
      Ok(#(c, n, PatternString(string_type, location, value)))
    g.PatternDiscard(location:, name:) -> {
      let #(c, typ) = new_type_var_ref(c)
      Ok(#(c, n, PatternDiscard(typ, location, name)))
    }
    g.PatternVariable(location:, name:) -> {
      let #(c, typ) = new_type_var_ref(c)
      let pattern = PatternVariable(typ, location, name)
      let n = dict.insert(n, name, typ)
      Ok(#(c, n, pattern))
    }
    g.PatternTuple(location:, elements:) -> {
      // Infer types for all elements in the tuple pattern
      use #(c, n, elems) <- result.map(
        list.try_fold(elements, #(c, n, []), fn(acc, elem) {
          let #(c, n, patterns) = acc
          use #(c, n, pattern) <- result.map(infer_pattern(c, n, elem))
          #(c, n, [pattern, ..patterns])
        }),
      )
      let elems = list.reverse(elems)

      // Create the tuple type from the inferred element types
      let typ = TupleType(list.map(elems, fn(e) { e.typ }))

      #(c, n, PatternTuple(typ, location, elems))
    }
    g.PatternList(location:, elements:, tail:) -> {
      // Infer types for all elements in the list pattern
      use #(c, n, elements) <- result.try(
        list.try_fold(elements, #(c, n, []), fn(acc, elem) {
          let #(c, n, patterns) = acc
          use #(c, n, pattern) <- result.map(infer_pattern(c, n, elem))
          #(c, n, [pattern, ..patterns])
        }),
      )
      let elements = list.reverse(elements)

      // Create a type variable for the element type
      let #(c, elem_type) = new_type_var_ref(c)

      // Unify all element types with the element type variable
      use c <- result.try(
        list.try_fold(elements, c, fn(c, elem) { unify(c, elem.typ, elem_type) }),
      )

      // Create the list type
      let typ = NamedType(prelude, "List", [elem_type])

      // Handle the tail pattern if present
      use #(c, n, tail) <- result.map(case tail {
        Some(tail_pattern) -> {
          use #(c, n, tail) <- result.try(infer_pattern(c, n, tail_pattern))
          // The tail should be a list of the same type
          use c <- result.map(unify(c, tail.typ, typ))
          #(c, n, Some(tail))
        }
        None -> Ok(#(c, n, None))
      })

      #(c, n, PatternList(typ, location, elements, tail))
    }
    g.PatternAssignment(location:, pattern:, name:) -> {
      // First, infer the type of the inner pattern
      use #(c, n, pattern) <- result.map(infer_pattern(c, n, pattern))

      // Create the PatternAssignment with the same type as the inner pattern
      let pattern = PatternAssignment(pattern.typ, location, pattern, name)

      // Add the name binding to the environment
      let n = dict.insert(n, name, pattern.typ)

      #(c, n, pattern)
    }
    g.PatternConcatenate(location:, prefix:, prefix_name:, rest_name:) -> {
      // Add prefix_name to the environment if applicable
      let #(n, prefix_name) = case prefix_name {
        Some(g.Named(name)) -> {
          let n = dict.insert(n, name, string_type)
          #(n, Some(Named(name)))
        }
        Some(g.Discarded(name)) -> #(n, Some(Discarded(name)))
        None -> #(n, None)
      }

      // Add rest_name to the environment if applicable
      let #(n, rest_name_result) = case rest_name {
        g.Named(name) -> {
          let n = dict.insert(n, name, string_type)
          #(n, Named(name))
        }
        g.Discarded(name) -> #(n, Discarded(name))
      }

      let pattern =
        PatternConcatenate(
          string_type,
          location,
          prefix,
          prefix_name,
          rest_name_result,
        )

      Ok(#(c, n, pattern))
    }
    g.PatternBitString(location:, segments:) -> {
      use #(c, n, segs) <- result.map(
        list.try_fold(segments, #(c, n, []), fn(acc, seg) {
          let #(c, n, segs) = acc
          let #(pattern, options) = seg

          use #(c, n, options, typ) <- result.try(
            list.try_fold(options, #(c, n, [], None), fn(acc, option) {
              let #(c, n, options, typ) = acc
              use #(c, n, option, option_type) <- result.try(case option {
                g.BigOption -> Ok(#(c, n, BigOption, None))
                g.LittleOption -> Ok(#(c, n, LittleOption, None))
                g.NativeOption -> Ok(#(c, n, NativeOption, None))
                g.SignedOption -> Ok(#(c, n, SignedOption, None))
                g.UnsignedOption -> Ok(#(c, n, UnsignedOption, None))
                g.BytesOption -> Ok(#(c, n, BytesOption, Some(bit_array_type)))
                g.BitsOption -> Ok(#(c, n, BitsOption, Some(bit_array_type)))
                g.IntOption -> Ok(#(c, n, IntOption, Some(int_type)))
                g.FloatOption -> Ok(#(c, n, FloatOption, Some(float_type)))
                g.Utf8Option -> Ok(#(c, n, Utf8Option, Some(string_type)))
                g.Utf16Option -> Ok(#(c, n, Utf16Option, Some(string_type)))
                g.Utf32Option -> Ok(#(c, n, Utf32Option, Some(string_type)))
                g.Utf8CodepointOption ->
                  Ok(#(c, n, Utf8CodepointOption, Some(codepoint_type)))
                g.Utf16CodepointOption ->
                  Ok(#(c, n, Utf16CodepointOption, Some(codepoint_type)))
                g.Utf32CodepointOption ->
                  Ok(#(c, n, Utf32CodepointOption, Some(codepoint_type)))
                g.SizeOption(size) -> Ok(#(c, n, SizeOption(size), None))
                g.SizeValueOption(pattern) -> {
                  use #(c, n, p) <- result.try(infer_pattern(c, n, pattern))
                  use c <- result.map(unify(c, p.typ, int_type))
                  #(c, n, SizeValueOption(p), None)
                }
                g.UnitOption(unit) -> Ok(#(c, n, UnitOption(unit), None))
              })
              use typ <- result.map(case typ, option_type {
                Some(_), Some(_) ->
                  Error(BitPatternSegmentTypeOverSpecified(context_location(c)))
                Some(_), None -> Ok(typ)
                _, _ -> Ok(option_type)
              })
              #(c, n, [option, ..options], typ)
            }),
          )
          let options = list.reverse(options)

          // If no type option was specified, default to int_type
          let expected_type = case typ {
            Some(t) -> t
            None -> int_type
          }

          use #(c, n, pattern) <- result.try(infer_pattern(c, n, pattern))
          use c <- result.map(unify(c, pattern.typ, expected_type))
          #(c, n, [#(pattern, options), ..segs])
        }),
      )
      let segs = list.reverse(segs)

      // The overall pattern type should be bit_array_type
      #(c, n, PatternBitString(bit_array_type, location, segs))
    }
    g.PatternVariant(location:, module:, constructor:, arguments:, with_spread:) -> {
      // resolve the constructor function
      use #(resolved_module, constructor, poly, labels) <- result.try(
        resolve_constructor(c, module, constructor),
      )

      // infer the type of all arguments
      let arguments =
        list.map(arguments, fn(arg) {
          case arg {
            g.LabelledField(label:, label_location:, item:) ->
              LabelledField(item, label, label_location)
            g.ShorthandField(label:, location:) ->
              ShorthandField(
                g.PatternVariable(location, label),
                label,
                location,
              )
            g.UnlabelledField(item:) -> UnlabelledField(item)
          }
        })
      use #(c, n, arguments) <- result.try(infer_pattern_fields(c, n, arguments))

      // handle labels
      use #(c, positional_arguments) <- result.try(case with_spread {
        True -> {
          let #(c, args) =
            match_labels_optional(arguments, labels)
            |> list.fold(#(c, []), fn(acc, opt) {
              let #(c, opts) = acc
              let #(c, opt) = case opt {
                Some(opt) -> #(c, Some(opt.item))
                None -> #(c, None)
              }
              #(c, [opt, ..opts])
            })
          Ok(#(c, list.reverse(args)))
        }
        False -> {
          use args <- result.map(match_labels(c, arguments, labels))
          let args = list.map(args, fn(arg) { Some(arg.item) })
          #(c, args)
        }
      })

      let #(c, tagged_arguments) =
        list.map_fold(positional_arguments, c, fn(c, x) {
          case x {
            Some(p) -> #(c, #(Some(p), p.typ))
            None -> {
              let #(c, tv) = new_type_var_ref(c)
              #(c, #(None, tv))
            }
          }
        })
      let arg_types = list.map(tagged_arguments, fn(x) { x.1 })

      // handle 0 parameter variants are not functions
      use #(c, typ) <- result.map(case arg_types {
        [] -> Ok(instantiate(c, poly))
        _ -> {
          // unify the constructor function type with the types of args
          let #(c, fun_typ) = instantiate(c, poly)
          let #(c, typ) = new_type_var_ref(c)
          use c <- result.map(unify(c, fun_typ, FunctionType(arg_types, typ)))
          #(c, typ)
        }
      })

      let #(c, positional_arguments) =
        list.map_fold(tagged_arguments, c, fn(c, x) {
          case x {
            #(Some(p), _) -> #(c, MatchedArgument(p))
            #(None, tv) -> {
              let #(c, t) = resolve_type(c, tv)
              #(c, UnmatchedArgument(t))
            }
          }
        })

      let pattern =
        PatternVariant(
          typ:,
          location:,
          module:,
          constructor:,
          arguments:,
          positional_arguments:,
          resolved_module:,
          with_spread:,
        )

      #(c, n, pattern)
    }
  }
}

fn resolve_constructor(c: Context, module: Option(String), constructor: String) {
  use constructor <- result.try(resolve_constructor_name(c, module, constructor))
  case constructor {
    FunctionGlobal(module:, name:, typ:, labels:) ->
      Ok(#(module, name, typ, labels))
    ConstantGlobal(..) ->
      Error(NotAFunction(
        context_location(c),
        constructor.module <> "." <> constructor.name,
      ))
  }
}

fn infer_annotation(
  c: Context,
  typ: g.Type,
) -> Result(#(Context, Annotation), Error) {
  let vars =
    find_vars_in_type(typ)
    |> list.unique()
    |> list.sort(string.compare)

  let #(c, type_env) =
    list.fold(vars, #(c, dict.new()), fn(acc, name) {
      let #(c, n) = acc
      let #(c, typ) = new_type_var_ref(c)
      let n = dict.insert(n, name, typ)
      #(c, n)
    })

  do_infer_annotation(c, type_env, typ)
}

fn infer_body(
  c: Context,
  n: LocalEnv,
  body: List(g.Statement),
) -> Result(#(Context, List(Statement)), Error) {
  case body {
    [] -> Ok(#(c, []))
    [x, ..xs] ->
      case x {
        g.Expression(value) -> {
          use #(c, value) <- result.try(infer_expression(c, n, value))

          let statement = Expression(value.typ, value.location, value)

          // infer the rest of the body
          use #(c, rest) <- result.map(infer_body(c, n, xs))
          #(c, [statement, ..rest])
        }
        g.Assignment(location:, kind:, pattern:, annotation:, value:) -> {
          // infer value before binding the new variable
          use #(c, value) <- result.try(infer_expression(c, n, value))

          // infer pattern, annotation, and value
          use #(c, n, pattern) <- result.try(infer_pattern(c, n, pattern))

          // if there is an annotation, the pattern must unify with the annotation
          use #(c, annotation) <- result.try(case annotation {
            Some(typ) -> {
              use #(c, annotation) <- result.try(infer_annotation(c, typ))
              use c <- result.map(unify(c, pattern.typ, annotation.typ))
              #(c, Some(annotation))
            }
            None -> Ok(#(c, None))
          })

          // the pattern must unify with both the annotation
          // and the assigned value
          use c <- result.try(unify(c, pattern.typ, value.typ))

          // TODO check the right "kind" was used (needs exhaustive checking)
          use #(c, kind) <- result.try(case kind {
            g.Let -> Ok(#(c, Let))
            g.LetAssert(None) -> Ok(#(c, LetAssert(None)))
            g.LetAssert(Some(message)) -> {
              use #(c, message) <- result.try(infer_expression(c, n, message))
              use c <- result.try(unify(c, message.typ, string_type))
              Ok(#(c, LetAssert(Some(message))))
            }
          })

          let statement =
            Assignment(
              typ: value.typ,
              location:,
              value:,
              pattern:,
              annotation:,
              kind:,
            )

          // infer the rest of the body
          use #(c, rest) <- result.map(infer_body(c, n, xs))
          #(c, [statement, ..rest])
        }
        g.Assert(location:, expression:, message:) -> {
          use #(c, expression) <- result.try(infer_expression(c, n, expression))

          use #(c, message) <- result.try(case message {
            Some(msg) -> {
              use #(c, msg) <- result.map(infer_expression(c, n, msg))
              #(c, Some(msg))
            }
            None -> Ok(#(c, None))
          })

          let statement = Assert(expression.typ, location, expression, message)

          // infer the rest of the body
          use #(c, rest) <- result.map(infer_body(c, n, xs))
          #(c, [statement, ..rest])
        }
        g.Use(span, patterns, function) -> {
          // desugar for inference: generate an fn() with one argument per pattern,
          // and the remaining statements in the current body as its body, which is
          // passed as the final callback argument to the specified function call.
          let #(span, fun, args) = case function {
            g.Call(span, fun, args) -> #(span, fun, args)
            _ -> #(span, function, [])
          }
          let params =
            list.index_map(patterns, fn(_pat, i) {
              g.FnParameter(g.Named("P" <> int.to_string(i)), None)
            })
          // generate a pattern assignment for each argument of the callback, and
          // append the remainder of the current body.
          let body =
            list.index_fold(patterns, xs, fn(body, pat, i) {
              let param = g.Variable(span, "P" <> int.to_string(i))
              let assignment =
                g.Assignment(span, g.Let, pat.pattern, pat.annotation, param)
              [assignment, ..body]
            })
          let callback = g.Fn(span, params, None, body)
          // infer the function being called so we can insert the callback correctly
          use #(_, ifun) <- result.try(infer_expression(c, n, fun))
          let field = case ifun {
            Function(labels:, ..) ->
              case list.last(labels) {
                Ok(Some(label)) -> g.LabelledField(label, span, callback)
                _ -> g.UnlabelledField(callback)
              }
            _ -> g.UnlabelledField(callback)
          }
          // finally infer the expression as a whole
          use #(c, call) <- result.map(infer_call(
            c,
            n,
            span,
            fun,
            list.append(args, [field]),
          ))
          // now re-sugar into a use statement
          let assert Ok(Fn(body:, ..)) = list.last(call.positional_arguments)
          let #(patterns, body) = list.split(body, list.length(patterns))
          let patterns =
            list.map(patterns, fn(stmt) {
              let assert Assignment(pattern:, annotation:, ..) = stmt
              UsePattern(pattern, annotation)
            })
            |> list.reverse
          let statement = Use(call.typ, call.location, patterns, call.function)
          // TODO: do we really not want to keep the rest of body inline?
          #(c, [statement, ..body])
        }
      }
  }
}

fn match_labels(
  c: Context,
  args: List(Field(a)),
  params: List(Option(String)),
) -> Result(List(Field(a)), Error) {
  do_match_labels(c, args, params, #(list.length(params), list.length(args)))
}

fn do_match_labels(
  c: Context,
  args: List(Field(a)),
  params: List(Option(String)),
  lens: #(Int, Int),
) -> Result(List(Field(a)), Error) {
  // find the labels in the order specified by parameters
  // either we find the matching label or default to the first unlabelled arg
  case params {
    [] ->
      case args {
        [] -> Ok([])
        _ -> Error(WrongArity(context_location(c), lens.0, lens.1))
      }
    [p, ..p_rest] ->
      extract_matching(args, fn(a) { field_label(a) == p })
      |> result.try_recover(fn(_) {
        extract_matching(args, fn(a) { field_label(a) == None })
      })
      |> result.map_error(fn(_) {
        case p {
          Some(l) -> LabelNotFound(context_location(c), l)
          None -> WrongArity(context_location(c), lens.0, lens.1)
        }
      })
      |> result.try(fn(r) {
        let #(a, a_rest) = r
        use rest <- result.map(match_labels(c, a_rest, p_rest))
        [a, ..rest]
      })
  }
}

fn match_labels_optional(
  args: List(Field(a)),
  params: List(Option(String)),
) -> List(Option(Field(a))) {
  // find the labels in the order specified by parameters
  case params {
    [] -> []
    [p, ..p_rest] ->
      case extract_matching(args, fn(a) { field_label(a) == p }) {
        Ok(#(a, a_rest)) -> [Some(a), ..match_labels_optional(a_rest, p_rest)]
        Error(_) ->
          case extract_matching(args, fn(a) { field_label(a) == None }) {
            Ok(#(a, a_rest)) -> [
              Some(a),
              ..match_labels_optional(a_rest, p_rest)
            ]
            Error(_) -> [None, ..match_labels_optional(args, p_rest)]
          }
      }
  }
}

fn infer_expression(
  c: Context,
  n: LocalEnv,
  exp: g.Expression,
) -> Result(#(Context, Expression), Error) {
  let c = Context(..c, current_span: exp.location)
  case exp {
    g.Int(location:, value:) -> Ok(#(c, Int(int_type, location, value)))
    g.Float(location:, value:) -> Ok(#(c, Float(float_type, location, value)))
    g.String(location:, value:) ->
      Ok(#(c, String(string_type, location, value)))
    g.Variable(location:, name:) -> {
      let name = resolve_unqualified_name(c, n, name)
      case name {
        Ok(ResolvedGlobal(global)) ->
          case global {
            FunctionGlobal(module, name, typ, labels) -> {
              let #(c, typ) = instantiate(c, typ)
              Ok(#(c, Function(typ, location, module, name, labels)))
            }
            ConstantGlobal(module, name, typ) -> {
              let #(c, typ) = instantiate(c, typ)
              Ok(#(c, Constant(typ, location, module, name)))
            }
          }
        Ok(ResolvedLocal(name, typ)) -> {
          Ok(#(c, LocalVariable(typ, location, name)))
        }
        Error(s) -> Error(s)
      }
    }
    g.NegateInt(location:, value:) -> {
      use #(c, e) <- result.try(infer_expression(c, n, value))
      use c <- result.map(unify(c, e.typ, int_type))
      #(c, NegateInt(int_type, location, e))
    }
    g.NegateBool(location:, value:) -> {
      use #(c, e) <- result.try(infer_expression(c, n, value))
      use c <- result.map(unify(c, e.typ, bool_type))
      #(c, NegateBool(bool_type, location, e))
    }
    g.Block(location:, statements:) -> {
      use #(c, statements) <- result.try(infer_body(c, n, statements))
      case list.last(statements) {
        Ok(last) -> Ok(#(c, Block(last.typ, location, statements)))
        Error(_) -> Error(EmptyBlock(context_location(c)))
      }
    }
    g.Panic(location:, message: e) -> {
      case e {
        Some(e) -> {
          // the expression should be a string
          use #(c, e) <- result.try(infer_expression(c, n, e))
          use c <- result.map(unify(c, e.typ, string_type))
          let #(c, typ) = new_type_var_ref(c)
          #(c, Panic(typ, location, Some(e)))
        }
        None -> {
          let #(c, typ) = new_type_var_ref(c)
          Ok(#(c, Panic(typ, location, None)))
        }
      }
    }
    g.Todo(location:, message:) -> {
      case message {
        Some(e) -> {
          // the expression should be a string
          use #(c, e) <- result.try(infer_expression(c, n, e))
          use c <- result.map(unify(c, e.typ, string_type))
          let #(c, typ) = new_type_var_ref(c)
          #(c, Todo(typ, location, Some(e)))
        }
        None -> {
          let #(c, typ) = new_type_var_ref(c)
          Ok(#(c, Todo(typ, location, None)))
        }
      }
    }
    g.Tuple(location:, elements:) -> {
      // Infer type of all elements
      use #(c, elements) <- result.try(
        list.try_fold(elements, #(c, []), fn(acc, e) {
          let #(c, elements) = acc
          use #(c, e) <- result.try(infer_expression(c, n, e))
          Ok(#(c, [e, ..elements]))
        }),
      )
      let elements = list.reverse(elements)

      // Create tuple type
      let types = list.map(elements, fn(e) { e.typ })
      let typ = TupleType(types)
      Ok(#(c, Tuple(typ, location, elements)))
    }
    g.List(location:, elements:, rest:) -> {
      // Infer types for all elements
      use #(c, elements) <- result.try(
        list.try_fold(elements, #(c, []), fn(acc, e) {
          let #(c, elements) = acc
          use #(c, e) <- result.try(infer_expression(c, n, e))
          Ok(#(c, [e, ..elements]))
        }),
      )
      let elements = list.reverse(elements)

      // Infer type for rest (if present)
      use #(c, rest) <- result.try(case rest {
        Some(t) -> {
          use #(c, t) <- result.try(infer_expression(c, n, t))
          Ok(#(c, Some(t)))
        }
        None -> Ok(#(c, None))
      })

      // Create a type variable for the element type
      let #(c, elem_type) = new_type_var_ref(c)
      let typ = NamedType(prelude, "List", [elem_type])

      // Unify all element types
      use c <- result.try(
        list.try_fold(elements, c, fn(c, e) { unify(c, e.typ, elem_type) }),
      )

      // Unify rest type with list type (if rest is present)
      use c <- result.map(case rest {
        Some(t) -> unify(c, t.typ, typ)
        None -> Ok(c)
      })

      #(c, List(typ, location, elements, rest))
    }
    g.Fn(location:, arguments:, return_annotation:, body:) -> {
      infer_fn(c, n, location, arguments, return_annotation, body, None)
    }
    g.RecordUpdate(location:, module:, constructor:, record:, fields:) -> {
      // Infer the type of the base record expression
      use #(c, base_expr) <- result.try(infer_expression(c, n, record))

      // Resolve the constructor type
      use #(res_module, constructor, poly, labels) <- result.try(
        resolve_constructor(c, module, constructor),
      )

      // Instantiate the constructor type
      let #(c, constructor_type) = instantiate(c, poly)
      use #(constructor_args, constructor_ret) <- result.try(
        case constructor_type {
          FunctionType(parameters:, return:) -> Ok(#(parameters, return))
          _ -> Error(NotAFunction(context_location(c), constructor))
        },
      )

      // Unify the base expression type with the constructor type
      use c <- result.try(unify(c, base_expr.typ, constructor_ret))

      // Infer types for all updated fields
      use #(c, updated_fields) <- result.try(
        list.try_fold(fields, #(c, []), fn(acc, field) {
          let #(c, updated_fields) = acc
          let item = case field.item {
            Some(item) -> item
            None -> g.Variable(location, field.label)
          }
          use #(c, value) <- result.map(infer_expression(c, n, item))
          #(c, [
            RecordUpdateField(label: field.label, item: Some(value)),
            ..updated_fields
          ])
        }),
      )
      let updated_fields = list.reverse(updated_fields)

      let fields =
        list.map(updated_fields, fn(x) {
          let assert Some(expr) = x.item
          LabelledField(expr, x.label, Span(0, 0))
        })
      let positional_fields = match_labels_optional(fields, labels)
      use positional_fields <- result.try(
        list.strict_zip(positional_fields, list.zip(labels, constructor_args))
        |> result.map_error(fn(_) {
          WrongArity(
            context_location(c),
            list.length(constructor_args),
            list.length(positional_fields),
          )
        }),
      )

      use #(c, positional_fields) <- result.map(
        list.try_fold(positional_fields, #(c, []), fn(acc, x) {
          let #(c, fields) = acc
          let #(given, #(_param_label, expected)) = x
          use #(c, result) <- result.map(case given {
            Some(e) -> {
              use c <- result.map(unify(c, e.item.typ, expected))
              #(c, UpdatedField(e.item))
            }
            None -> Ok(#(c, UnchangedField(expected)))
          })
          #(c, [result, ..fields])
        }),
      )
      let positional_fields = list.reverse(positional_fields)

      // The result type is the same as the constructor type
      let typ = constructor_ret

      // Create the RecordUpdate expression
      let record_update =
        RecordUpdate(
          typ: typ,
          location: location,
          module: module,
          resolved_module: res_module,
          constructor: constructor,
          record: base_expr,
          fields: updated_fields,
          positional_fields: positional_fields,
        )

      #(c, record_update)
    }
    g.FieldAccess(location:, container:, label:) -> {
      let field_access = {
        // try to infer the value, otherwise it might be a module access
        use #(c, value) <- result.try(infer_expression(c, n, container))

        // field access must be on a named type
        let #(c, value_typ_resolved) = resolve_type(c, value.typ)
        let value_typ = case value_typ_resolved {
          NamedType(module, type_name, _) -> Ok(#(type_name, module))
          _ -> Error(InvalidFieldAccess(context_location(c)))
        }
        use #(type_name, module) <- result.try(value_typ)

        // find the custom type definition
        use #(typ, variants) <- result.try(resolve_custom_type(
          c,
          module,
          type_name,
        ))

        // access only works with one variant
        let variant = case variants {
          // TODO proper implementation checking all variants
          [variant, ..] -> Ok(variant)
          _ -> Error(InvalidFieldAccess(context_location(c)))
        }
        use variant <- result.try(variant)

        // find the matching field and index
        let field =
          variant.fields
          |> list.index_map(fn(x, i) { #(x, i) })
          |> list.find(fn(x) { variant_field_label(x.0) == Some(label) })
          |> result.replace_error(FieldNotFound(context_location(c), label))
        use #(field, index) <- result.try(field)

        // create a getter function type
        let getter = FunctionType([typ.typ], field.item.typ)
        let getter = Poly(typ.vars, getter)
        let #(c, getter) = instantiate(c, getter)

        // unify the getter as if we're calling it on the value
        let #(c, typ) = new_type_var_ref(c)
        use c <- result.map(unify(c, getter, FunctionType([value.typ], typ)))

        #(
          c,
          FieldAccess(typ, location, value, label, module, variant.name, index),
        )
      }
      case field_access {
        Ok(access) -> Ok(access)
        Error(e) -> {
          // try a module access instead
          case container {
            g.Variable(_, module) -> {
              case resolve_aliased_global(c, QName(module, label)) {
                Ok(FunctionGlobal(module, name, poly, labels)) -> {
                  let #(c, typ) = instantiate(c, poly)
                  Ok(#(c, Function(typ, location, module, name, labels)))
                }
                Ok(ConstantGlobal(module, name, poly)) -> {
                  let #(c, typ) = instantiate(c, poly)
                  Ok(#(c, Constant(typ, location, module, name)))
                }
                Error(e) -> Error(e)
              }
            }
            _ -> Error(e)
          }
        }
      }
    }
    g.Call(span, function, arguments) -> {
      use #(c, call) <- result.map(infer_call(c, n, span, function, arguments))
      #(
        c,
        Call(
          call.typ,
          call.location,
          call.function,
          call.arguments,
          call.positional_arguments,
        ),
      )
    }
    g.TupleIndex(location:, tuple:, index:) -> {
      use #(c, tuple) <- result.try(infer_expression(c, n, tuple))
      let #(c, tuple_typ_resolved) = resolve_type(c, tuple.typ)
      case tuple_typ_resolved {
        TupleType(elements) -> {
          tuple_index_type(c, elements, index)
          |> result.map(fn(typ) {
            #(c, TupleIndex(typ, location, tuple, index))
          })
        }
        _ -> Error(InvalidTupleAccess(context_location(c)))
      }
    }
    g.FnCapture(
      location:,
      label:,
      function:,
      arguments_before:,
      arguments_after:,
    ) -> {
      // TODO return non-desugared version
      let #(c, x) = new_temp_var(c)
      let arg = case label {
        Some(label) -> g.LabelledField(label, location, g.Variable(location, x))
        None -> g.UnlabelledField(g.Variable(location, x))
      }
      let args = list.flatten([arguments_before, [arg], arguments_after])
      let param = g.FnParameter(g.Named(x), None)
      let lambda =
        g.Fn(location, [param], None, [
          g.Expression(g.Call(location, function, args)),
        ])
      infer_expression(c, n, lambda)
    }
    g.BitString(location:, segments:) -> {
      use #(c, segs) <- result.try(
        list.try_fold(segments, #(c, []), fn(acc, seg) {
          let #(c, segs) = acc
          let #(expression, options) = seg
          use #(c, options, typ) <- result.try(
            list.try_fold(options, #(c, [], None), fn(acc, option) {
              let #(c, options, typ) = acc
              use #(c, option, option_type) <- result.try(case option {
                g.BigOption -> Ok(#(c, BigOption, None))
                g.BytesOption -> Ok(#(c, BytesOption, Some(bit_array_type)))
                g.BitsOption -> Ok(#(c, BitsOption, Some(bit_array_type)))
                g.FloatOption -> Ok(#(c, FloatOption, Some(float_type)))
                g.IntOption -> Ok(#(c, IntOption, Some(int_type)))
                g.LittleOption -> Ok(#(c, LittleOption, None))
                g.NativeOption -> Ok(#(c, NativeOption, None))
                g.SignedOption -> Ok(#(c, SignedOption, None))
                g.SizeOption(size) -> Ok(#(c, SizeOption(size), None))
                g.SizeValueOption(e) -> {
                  use #(c, e) <- result.try(infer_expression(c, n, e))
                  use c <- result.map(unify(c, e.typ, int_type))
                  #(c, SizeValueOption(e), None)
                }
                g.UnitOption(unit) -> Ok(#(c, UnitOption(unit), None))
                g.UnsignedOption -> Ok(#(c, UnsignedOption, None))
                g.Utf16CodepointOption ->
                  Ok(#(c, Utf16CodepointOption, Some(codepoint_type)))
                g.Utf16Option -> Ok(#(c, Utf16Option, Some(string_type)))
                g.Utf32CodepointOption ->
                  Ok(#(c, Utf32CodepointOption, Some(codepoint_type)))
                g.Utf32Option -> Ok(#(c, Utf32Option, Some(string_type)))
                g.Utf8CodepointOption ->
                  Ok(#(c, Utf8CodepointOption, Some(codepoint_type)))
                g.Utf8Option -> Ok({ #(c, Utf8Option, Some(string_type)) })
              })
              use typ <- result.map(case typ, option_type {
                Some(_), Some(_) ->
                  Error(BitPatternSegmentTypeOverSpecified(context_location(c)))
                Some(_), None -> Ok(typ)
                _, _ -> Ok(option_type)
              })
              #(c, [option, ..options], typ)
            }),
          )
          let options = list.reverse(options)
          let typ = case typ {
            Some(typ) -> typ
            None -> int_type
          }
          use #(c, expression) <- result.try(infer_expression(c, n, expression))
          use c <- result.map(unify(c, expression.typ, typ))
          #(c, [#(expression, options), ..segs])
        }),
      )
      let segs = list.reverse(segs)
      Ok(#(c, BitString(bit_array_type, location, segs)))
    }
    g.Case(location:, subjects:, clauses:) -> {
      use #(c, subjects) <- result.try(
        list.try_fold(subjects, #(c, []), fn(acc, sub) {
          let #(c, subjects) = acc
          use #(c, sub) <- result.try(infer_expression(c, n, sub))
          Ok(#(c, [sub, ..subjects]))
        }),
      )
      let subjects = list.reverse(subjects)

      // all of the branches should unify with the case type
      let #(c, typ) = new_type_var_ref(c)

      use #(c, clauses) <- result.try(
        list.try_fold(clauses, #(c, []), fn(acc, clause) {
          let #(c, clauses) = acc

          // patterns is a List(List(Pattern))
          // the inner list has a pattern to match each subject
          // the outer list has alternatives that have the same body
          use #(c, n, patterns) <- result.try(
            list.try_fold(clause.patterns, #(c, n, []), fn(acc, pat) {
              let #(c, n, pats) = acc

              // each pattern has a corresponding subject
              use sub_pats <- result.try(
                list.strict_zip(subjects, pat)
                |> result.map_error(fn(_) {
                  WrongArity(
                    context_location(c),
                    list.length(subjects),
                    list.length(pat),
                  )
                }),
              )
              use #(c, n, pat) <- result.map(
                list.try_fold(sub_pats, #(c, n, []), fn(acc, sub_pat) {
                  let #(c, n, pats) = acc
                  let #(sub, pat) = sub_pat
                  use #(c, n, pat) <- result.try(infer_pattern(c, n, pat))
                  // the pattern type should match the corresponding subject
                  use c <- result.map(unify(c, pat.typ, sub.typ))
                  #(c, n, [pat, ..pats])
                }),
              )
              let pat = list.reverse(pat)

              // all alternatives must bind the same names
              // TODO check the alternative patterns bind the same names
              // how do we check this? do we need to unify (based on name)?
              // maybe infer_pattern needs to return a list of bindings
              // instead of a new env

              #(c, n, [pat, ..pats])
            }),
          )
          let patterns = list.reverse(patterns)

          // if the guard exists ensure it has a boolean result
          use #(c, guard) <- result.try(case clause.guard {
            Some(guard) -> {
              use #(c, guard) <- result.try(infer_expression(c, n, guard))
              use c <- result.map(unify(c, guard.typ, bool_type))
              #(c, Some(guard))
            }
            None -> Ok(#(c, None))
          })

          use #(c, body) <- result.try(infer_expression(c, n, clause.body))

          // the body should unify with the case type
          use c <- result.map(unify(c, typ, body.typ))

          let santa = Clause(patterns:, guard:, body:)
          #(c, [santa, ..clauses])
        }),
      )
      let clauses = list.reverse(clauses)

      Ok(#(c, Case(typ:, location:, subjects:, clauses:)))
    }
    g.BinaryOperator(span, g.Pipe, left, right) -> {
      // first infer a desugared version of the pipe
      let #(idx, label, desugared) = case right {
        g.Call(span, fun, args) -> {
          #(
            0,
            None,
            infer_call(c, n, span, fun, [g.UnlabelledField(left), ..args]),
          )
        }
        g.FnCapture(span, label, fun, before, after) -> {
          let args = case label {
            Some(label) -> [before, [g.LabelledField(label, span, left)], after]
            None -> [before, [g.UnlabelledField(left)], after]
          }
          #(
            list.length(before),
            label,
            infer_call(c, n, span, fun, list.flatten(args)),
          )
        }
        g.Echo(location: span, expression: None, message:) -> {
          let echo_ =
            g.Fn(span, [g.FnParameter(g.Named("value"), None)], None, [
              g.Expression(g.Echo(
                span,
                Some(g.Variable(span, "value")),
                message,
              )),
            ])
          #(0, None, infer_call(c, n, span, echo_, [g.UnlabelledField(left)]))
        }
        _ -> {
          #(0, None, infer_call(c, n, span, right, [g.UnlabelledField(left)]))
        }
      }
      // then re-sugar it
      use #(c, desugared) <- result.map(desugared)
      let InferredCall(
        typ:,
        location:,
        function:,
        arguments:,
        positional_arguments: _,
      ) = desugared
      let #(before, after) = list.split(arguments, idx)
      // assert: the left-hand side of the pipe always exists
      let assert #([left], after) = list.split(after, 1)
      let left = left.item
      let right = case function {
        Fn(_, _, [_], _, [Expression(expression: Echo(message:, ..), ..)]) ->
          PipeIntoEcho(message)
        _ -> PipeIntoFnCapture(label, function, before, after)
      }
      #(c, Pipe(typ:, location:, left:, right:))
    }
    g.BinaryOperator(location:, name:, left:, right:) -> {
      let name = map_binop(name)
      let #(c, fun_typ) = case name {
        // Boolean logic
        And | Or -> #(c, FunctionType([bool_type, bool_type], bool_type))

        // Equality
        Eq | NotEq -> {
          let #(c, a) = new_type_var_ref(c)
          #(c, FunctionType([a, a], bool_type))
        }

        // Order comparison
        LtInt | LtEqInt | GtEqInt | GtInt -> #(
          c,
          FunctionType([int_type, int_type], bool_type),
        )

        LtFloat | LtEqFloat | GtEqFloat | GtFloat -> #(
          c,
          FunctionType([float_type, float_type], bool_type),
        )

        // Maths
        AddInt | SubInt | MultInt | DivInt | RemainderInt -> #(
          c,
          FunctionType([int_type, int_type], int_type),
        )

        AddFloat | SubFloat | MultFloat | DivFloat -> #(
          c,
          FunctionType([float_type, float_type], float_type),
        )

        // Strings
        Concatenate -> #(
          c,
          FunctionType([string_type, string_type], string_type),
        )
      }

      use #(c, left) <- result.try(infer_expression(c, n, left))
      use #(c, right) <- result.try(infer_expression(c, n, right))

      // unify the function type with the types of args
      let #(c, typ) = new_type_var_ref(c)
      use c <- result.map(unify(
        c,
        fun_typ,
        FunctionType([left.typ, right.typ], typ),
      ))

      #(c, BinaryOperator(typ, location, name, left, right))
    }
    g.Echo(location:, expression:, message:) -> {
      use #(c, typ, expression) <- result.try(case expression {
        Some(expression) -> {
          use #(c, expression) <- result.try(infer_expression(c, n, expression))
          Ok(#(c, expression.typ, Some(expression)))
        }
        None -> Ok(#(c, nil_type, None))
      })
      use #(c, message) <- result.try(case message {
        Some(message) -> {
          use #(c, message) <- result.try(infer_expression(c, n, message))
          use c <- result.try(unify(c, message.typ, string_type))
          Ok(#(c, Some(message)))
        }
        None -> Ok(#(c, None))
      })
      Ok(#(c, Echo(typ, location, expression, message)))
    }
  }
}

type InferredCall {
  InferredCall(
    typ: Type,
    location: Span,
    function: Expression,
    arguments: List(Field(Expression)),
    positional_arguments: List(Expression),
  )
}

fn infer_call(
  c: Context,
  n: LocalEnv,
  span: Span,
  function: g.Expression,
  arguments: List(g.Field(g.Expression)),
) -> Result(#(Context, InferredCall), Error) {
  // infer the type of the function
  use #(c, fun) <- result.try(infer_expression(c, n, function))

  // get labels from function type
  let labels = case fun {
    Function(labels:, ..) -> labels
    _ -> list.map(arguments, fn(_) { None })
  }

  // convert glance fields to typed fields (original order)
  let args =
    list.map(arguments, fn(arg) {
      case arg {
        g.LabelledField(label:, label_location:, item:) ->
          LabelledField(item, label, label_location)
        g.ShorthandField(label:, location:) ->
          ShorthandField(g.Variable(location, label), label, location)
        g.UnlabelledField(item:) -> UnlabelledField(item)
      }
    })

  // build type hints by label/position for Fn arg inference
  let #(c, fun_typ_resolved) = resolve_type(c, fun.typ)
  let hinted_args = case fun_typ_resolved {
    FunctionType(params, _) -> build_arg_hints(args, labels, params)
    _ -> list.map(args, fn(arg) { #(None, arg) })
  }

  // infer all args in original (caller) order
  use #(c, arguments) <- result.try(
    list.try_fold(hinted_args, #(c, []), fn(acc, hinted_arg) {
      let #(c, done) = acc
      let #(hint, field) = hinted_arg

      // give type hint when arg is a fn
      let result = case field.item {
        g.Fn(location:, arguments:, return_annotation:, body:) ->
          infer_fn(c, n, location, arguments, return_annotation, body, hint)
        _ -> infer_expression(c, n, field.item)
      }
      use #(c, inferred_arg) <- result.try(result)

      use c <- result.map(case hint {
        Some(h) -> unify(c, h, inferred_arg.typ)
        None -> Ok(c)
      })

      #(c, [map_field(field, fn(_) { inferred_arg }), ..done])
    }),
  )
  let arguments = list.reverse(arguments)

  // reorder to positional order via label matching
  use positional_fields <- result.try(match_labels(c, arguments, labels))

  let arg_types = list.map(positional_fields, fn(f) { f.item.typ })
  let positional_arguments = list.map(positional_fields, fn(f) { f.item })

  // unify the function type with the types of args
  let #(c, typ) = new_type_var_ref(c)
  use c <- result.map(unify(c, fun.typ, FunctionType(arg_types, typ)))
  #(c, InferredCall(typ, span, fun, arguments, positional_arguments))
}

fn map_binop(name: g.BinaryOperator) -> BinaryOperator {
  case name {
    g.And -> And
    g.Or -> Or
    g.Eq -> Eq
    g.NotEq -> NotEq
    g.LtInt -> LtInt
    g.LtEqInt -> LtEqInt
    g.LtFloat -> LtFloat
    g.LtEqFloat -> LtEqFloat
    g.GtEqInt -> GtEqInt
    g.GtInt -> GtInt
    g.GtEqFloat -> GtEqFloat
    g.GtFloat -> GtFloat
    g.Pipe -> panic as "pipe should be handeled elsewhere"
    g.AddInt -> AddInt
    g.AddFloat -> AddFloat
    g.SubInt -> SubInt
    g.SubFloat -> SubFloat
    g.MultInt -> MultInt
    g.MultFloat -> MultFloat
    g.DivInt -> DivInt
    g.DivFloat -> DivFloat
    g.RemainderInt -> RemainderInt
    g.Concatenate -> Concatenate
  }
}

fn resolve_custom_type(c: Context, module: String, type_name: String) {
  dict.get(c.type_env, QName(module, type_name))
  |> result.replace_error(UnresolvedType(context_location(c), type_name))
}

fn tuple_index_type(
  c: Context,
  elements: List(Type),
  index: Int,
) -> Result(Type, Error) {
  index_into_list(elements, index)
  |> result.map_error(fn(_) {
    TupleIndexOutOfBounds(context_location(c), list.length(elements), index)
  })
}

fn index_into_list(list: List(a), index: Int) -> Result(a, Nil) {
  case index, list {
    0, [item, ..] -> Ok(item)
    _, [_, ..rest] -> index_into_list(rest, index - 1)
    _, _ -> Error(Nil)
  }
}

fn infer_fn(
  c: Context,
  n: Dict(String, Type),
  location: Span,
  parameters: List(g.FnParameter),
  return_annotation: Option(g.Type),
  body: List(g.Statement),
  hint: Option(Type),
) -> Result(#(Context, Expression), Error) {
  use #(c, parameters, return_annotation) <- result.try(infer_fn_parameters(
    c,
    parameters,
    return_annotation,
  ))

  let #(c, return_type) = annotation_type_or_new(c, return_annotation)

  // compute function type
  let parameter_types = list.map(parameters, fn(x) { x.typ })
  let typ = FunctionType(parameter_types, return_type)

  // unify parameters with type hint
  use c <- result.try(case hint {
    Some(hint) -> unify(c, typ, hint)
    None -> Ok(c)
  })

  // put params into local env
  let n =
    list.fold(parameters, n, fn(n, param) {
      case param.name {
        Named(name) -> dict.insert(n, name, param.typ)
        Discarded(_) -> n
      }
    })

  // infer body
  use #(c, body) <- result.try(infer_body(c, n, body))

  // unify the return type with the last statement
  use c <- result.map(case list.last(body) {
    Ok(statement) -> unify(c, return_type, statement.typ)
    Error(_) -> Ok(c)
  })

  let fun = Fn(typ:, location:, parameters:, return_annotation:, body:)
  #(c, fun)
}

fn infer_fn_parameters(
  c: Context,
  parameters: List(g.FnParameter),
  return: Option(g.Type),
) -> Result(#(Context, List(FnParameter), Option(Annotation)), Error) {
  let #(c, type_env) =
    build_type_env(c, list.map(parameters, fn(p) { p.type_ }), return)

  // create type vars for parameters
  use #(c, params) <- result.try(
    list.try_fold(parameters, #(c, []), fn(acc, param) {
      let #(c, param_types) = acc

      let name = convert_assignment_name(param.name)

      use #(c, annotation) <- result.map(infer_optional_annotation(
        c,
        type_env,
        param.type_,
      ))

      let #(c, typ) = annotation_type_or_new(c, annotation)

      #(c, [FnParameter(typ, name, annotation), ..param_types])
    }),
  )
  let params = list.reverse(params)

  // handle function return type
  use #(c, return) <- result.map(infer_optional_annotation(c, type_env, return))

  #(c, params, return)
}

type PolyEnv =
  Dict(TypeVarId, Type)

fn get_type_var(c: Context, var: TypeVarId) {
  // assert: this function is only called for previously created type variables
  let assert Ok(x) = dict.get(c.type_vars, var) as string.inspect(var)
  x
}

fn set_type_var(c: Context, var: TypeVarId, bind: TypeVar) {
  Context(..c, type_vars: dict.insert(c.type_vars, var, bind))
}

fn instantiate(c: Context, poly: Poly) -> #(Context, Type) {
  let #(c, n) =
    list.fold(poly.vars, #(c, dict.new()), fn(acc, var) {
      let #(c, n) = acc
      let #(c, new_var) = new_type_var_ref(c)
      let n = dict.insert(n, var, new_var)
      #(c, n)
    })
  let typ = do_instantiate(c, n, poly.typ)
  #(c, typ)
}

fn find_tvs(c: Context, t: Type) -> List(TypeVarId) {
  case t {
    VariableType(ref) ->
      case get_type_var(c, ref) {
        Bound(x) -> find_tvs(c, x)
        Unbound -> [ref]
      }
    NamedType(_, _, args) -> list.flat_map(args, find_tvs(c, _))
    FunctionType(args, ret) -> list.flat_map([ret, ..args], find_tvs(c, _))
    TupleType(elements) -> list.flat_map(elements, find_tvs(c, _))
  }
}

fn do_instantiate(c: Context, n: PolyEnv, typ: Type) -> Type {
  case typ {
    VariableType(ref) ->
      case dict.get(n, ref) {
        Ok(r) -> r
        Error(_) ->
          case get_type_var(c, ref) {
            Bound(x) -> do_instantiate(c, n, x)
            Unbound -> typ
          }
      }
    NamedType(module:, name:, parameters:) ->
      NamedType(
        module:,
        name:,
        parameters: list.map(parameters, do_instantiate(c, n, _)),
      )
    FunctionType(args, ret) ->
      FunctionType(
        list.map(args, do_instantiate(c, n, _)),
        do_instantiate(c, n, ret),
      )
    TupleType(elements) ->
      TupleType(list.map(elements, do_instantiate(c, n, _)))
  }
}

fn unify(c: Context, a: Type, b: Type) -> Result(Context, Error) {
  let #(c, a) = resolve_type(c, a)
  let #(c, b) = resolve_type(c, b)
  case a, b {
    VariableType(ref), b ->
      case a == b {
        True -> Ok(c)
        False -> {
          let #(c, occurs) = occurs(c, ref, b)
          case occurs {
            True -> Error(RecursiveTypeError(context_location(c)))
            False -> Ok(set_type_var(c, ref, Bound(b)))
          }
        }
      }
    a, VariableType(_) -> unify(c, b, a)
    NamedType(amodule, aname, _), NamedType(bmodule, bname, _)
      if aname != bname || amodule != bmodule
    -> Error(IncompatibleTypes(context_location(c), a, b))
    NamedType(_, _, aargs), NamedType(_, _, bargs) ->
      unify_arguments(c, aargs, bargs)
    FunctionType(aargs, aret), FunctionType(bargs, bret) -> {
      use c <- result.try(unify(c, aret, bret))
      unify_arguments(c, aargs, bargs)
    }
    TupleType(aelements), TupleType(belements) -> {
      unify_arguments(c, aelements, belements)
    }
    _, _ -> Error(IncompatibleTypes(context_location(c), a, b))
  }
}

fn unify_arguments(
  c: Context,
  aargs: List(Type),
  bargs: List(Type),
) -> Result(Context, Error) {
  use args <- result.try(
    list.strict_zip(aargs, bargs)
    |> result.map_error(fn(_) {
      WrongArity(context_location(c), list.length(aargs), list.length(bargs))
    }),
  )
  list.try_fold(args, c, fn(c, x) { unify(c, x.0, x.1) })
}

fn occurs(c: Context, id: TypeVarId, in: Type) -> #(Context, Bool) {
  case in {
    VariableType(ref) ->
      case get_type_var(c, ref) {
        Bound(t) -> occurs(c, id, t)
        Unbound -> {
          // TODO not sure if this "set" is needed
          let c = set_type_var(c, ref, Unbound)
          #(c, id == ref)
        }
      }
    NamedType(_, _, args) ->
      list.fold(args, #(c, False), fn(acc, arg) {
        let #(c, b) = acc
        let #(c, b1) = occurs(c, id, arg)
        #(c, b || b1)
      })
    FunctionType(args, ret) ->
      list.fold([ret, ..args], #(c, False), fn(acc, arg) {
        let #(c, b) = acc
        let #(c, b1) = occurs(c, id, arg)
        #(c, b || b1)
      })
    TupleType(elements) ->
      list.fold(elements, #(c, False), fn(acc, arg) {
        let #(c, b) = acc
        let #(c, b1) = occurs(c, id, arg)
        #(c, b || b1)
      })
  }
}

/// follow any references to get the real type, with path compression
fn resolve_type(c: Context, typ: Type) -> #(Context, Type) {
  case typ {
    VariableType(x) -> {
      case get_type_var(c, x) {
        Bound(inner) -> {
          // if the inner type is a variable, update the outer to point to it
          case inner {
            VariableType(_) -> {
              let #(c, resolved) = resolve_type(c, inner)
              let c = set_type_var(c, x, Bound(resolved))
              #(c, resolved)
            }
            _ -> #(c, inner)
          }
        }
        Unbound -> #(c, typ)
      }
    }
    NamedType(..) -> #(c, typ)
    FunctionType(..) -> #(c, typ)
    TupleType(..) -> #(c, typ)
  }
}

fn build_rename(vars: List(TypeVarId)) -> Dict(TypeVarId, TypeVarId) {
  list.index_map(vars, fn(var, i) { #(var, TypeVarId(i)) })
  |> dict.from_list
}

fn substitute_type_alias(c: Context, type_alias: TypeAlias) -> TypeAlias {
  let rename = build_rename(type_alias.typ.vars)
  TypeAlias(
    ..type_alias,
    typ: substitute_poly(c, rename, type_alias.typ),
    aliased: substitute_annotation(c, rename, type_alias.aliased),
  )
}

fn substitute_constant(
  c: Context,
  constant: ConstantDefinition,
) -> ConstantDefinition {
  let rename = build_rename(constant.typ.vars)
  ConstantDefinition(
    ..constant,
    typ: substitute_poly(c, rename, constant.typ),
    annotation: option.map(constant.annotation, substitute_annotation(
      c,
      rename,
      _,
    )),
    value: substitute_expression(c, rename, constant.value),
  )
}

fn substitute_custom_type(c: Context, custom_type: CustomType) {
  let rename = build_rename(custom_type.typ.vars)
  CustomType(
    ..custom_type,
    typ: substitute_poly(c, rename, custom_type.typ),
    variants: list.map(custom_type.variants, fn(variant) {
      Variant(
        ..variant,
        typ: substitute_poly(c, rename, variant.typ),
        fields: list.map(variant.fields, fn(f) {
          case f {
            LabelledVariantField(item, label) ->
              LabelledVariantField(
                substitute_annotation(c, rename, item),
                label,
              )
            UnlabelledVariantField(item) ->
              UnlabelledVariantField(substitute_annotation(c, rename, item))
          }
        }),
      )
    }),
  )
}

fn substitute_function(c: Context, function: FunctionDefinition) {
  let rename = build_rename(function.typ.vars)
  FunctionDefinition(
    ..function,
    typ: substitute_poly(c, rename, function.typ),
    parameters: list.map(function.parameters, substitute_function_parameter(
      c,
      rename,
      _,
    )),
    body: list.map(function.body, substitute_statement(c, rename, _)),
    return: option.map(function.return, substitute_annotation(c, rename, _)),
  )
}

fn substitute_function_parameter(
  c: Context,
  rename: Dict(TypeVarId, TypeVarId),
  param: FunctionParameter,
) -> FunctionParameter {
  FunctionParameter(
    ..param,
    typ: substitute_type(c, rename, param.typ),
    annotation: option.map(param.annotation, substitute_annotation(c, rename, _)),
  )
}

fn substitute_fn_parameter(
  c: Context,
  rename: Dict(TypeVarId, TypeVarId),
  param: FnParameter,
) -> FnParameter {
  FnParameter(
    ..param,
    typ: substitute_type(c, rename, param.typ),
    annotation: option.map(param.annotation, substitute_annotation(c, rename, _)),
  )
}

fn substitute_statement(
  c: Context,
  rename: Dict(TypeVarId, TypeVarId),
  statement: Statement,
) -> Statement {
  case statement {
    Use(typ:, location:, patterns:, function:) ->
      Use(
        typ: substitute_type(c, rename, typ),
        location:,
        patterns: list.map(patterns, substitute_use_pattern(c, rename, _)),
        function: substitute_expression(c, rename, function),
      )
    Assignment(typ:, location:, kind:, pattern:, annotation:, value:) ->
      Assignment(
        typ: substitute_type(c, rename, typ),
        location:,
        kind:,
        pattern: substitute_pattern(c, rename, pattern),
        annotation: option.map(annotation, substitute_annotation(c, rename, _)),
        value: substitute_expression(c, rename, value),
      )
    Assert(typ:, location:, expression:, message:) ->
      Assert(
        typ: substitute_type(c, rename, typ),
        location:,
        expression: substitute_expression(c, rename, expression),
        message: option.map(message, substitute_expression(c, rename, _)),
      )
    Expression(typ:, location:, expression:) ->
      Expression(
        typ: substitute_type(c, rename, typ),
        location:,
        expression: substitute_expression(c, rename, expression),
      )
  }
}

fn substitute_use_pattern(
  c: Context,
  rename: Dict(TypeVarId, TypeVarId),
  use_pattern: UsePattern,
) -> UsePattern {
  let pattern = substitute_pattern(c, rename, use_pattern.pattern)
  let annotation =
    option.map(use_pattern.annotation, substitute_annotation(c, rename, _))
  UsePattern(pattern:, annotation:)
}

fn substitute_expression(
  c: Context,
  rename: Dict(TypeVarId, TypeVarId),
  expr: Expression,
) -> Expression {
  case expr {
    Int(..) -> expr
    Float(..) -> expr
    String(..) -> expr
    LocalVariable(typ:, location:, name:) ->
      LocalVariable(typ: substitute_type(c, rename, typ), location:, name:)
    Function(typ:, location:, module:, name:, labels:) ->
      Function(
        typ: substitute_type(c, rename, typ),
        location:,
        module:,
        name:,
        labels:,
      )
    Constant(typ:, location:, module:, name:) ->
      Constant(typ: substitute_type(c, rename, typ), location:, module:, name:)
    NegateInt(typ:, location:, value:) ->
      NegateInt(
        typ: substitute_type(c, rename, typ),
        location:,
        value: substitute_expression(c, rename, value),
      )
    NegateBool(typ:, location:, value:) ->
      NegateBool(
        typ: substitute_type(c, rename, typ),
        location:,
        value: substitute_expression(c, rename, value),
      )
    Block(typ:, location:, statements:) ->
      Block(
        typ: substitute_type(c, rename, typ),
        location:,
        statements: list.map(statements, substitute_statement(c, rename, _)),
      )
    Panic(typ:, location:, message:) ->
      Panic(
        typ: substitute_type(c, rename, typ),
        location:,
        message: option.map(message, substitute_expression(c, rename, _)),
      )
    Todo(typ:, location:, message:) ->
      Todo(
        typ: substitute_type(c, rename, typ),
        location:,
        message: option.map(message, substitute_expression(c, rename, _)),
      )
    Echo(typ:, location:, expression:, message:) ->
      Echo(
        typ: substitute_type(c, rename, typ),
        location:,
        expression: option.map(expression, substitute_expression(c, rename, _)),
        message: option.map(message, substitute_expression(c, rename, _)),
      )
    Tuple(typ:, location:, elements:) ->
      Tuple(
        typ: substitute_type(c, rename, typ),
        location:,
        elements: list.map(elements, substitute_expression(c, rename, _)),
      )
    List(typ:, location:, elements:, rest:) ->
      List(
        typ: substitute_type(c, rename, typ),
        location:,
        elements: list.map(elements, substitute_expression(c, rename, _)),
        rest: option.map(rest, substitute_expression(c, rename, _)),
      )
    Fn(typ:, location:, parameters:, return_annotation:, body:) ->
      Fn(
        typ: substitute_type(c, rename, typ),
        location:,
        parameters: list.map(parameters, substitute_fn_parameter(c, rename, _)),
        return_annotation: option.map(return_annotation, substitute_annotation(
          c,
          rename,
          _,
        )),
        body: list.map(body, substitute_statement(c, rename, _)),
      )
    RecordUpdate(
      typ:,
      location:,
      module:,
      resolved_module:,
      constructor:,
      record:,
      fields:,
      positional_fields:,
    ) ->
      RecordUpdate(
        typ: substitute_type(c, rename, typ),
        location:,
        module:,
        resolved_module:,
        constructor:,
        record: substitute_expression(c, rename, record),
        fields: list.map(fields, fn(field) {
          let assert Some(expr) = field.item
          RecordUpdateField(
            ..field,
            item: Some(substitute_expression(c, rename, expr)),
          )
        }),
        positional_fields: list.map(positional_fields, fn(field) {
          case field {
            UpdatedField(expr) ->
              UpdatedField(substitute_expression(c, rename, expr))
            UnchangedField(typ) ->
              UnchangedField(substitute_type(c, rename, typ))
          }
        }),
      )
    FieldAccess(
      typ:,
      location:,
      container:,
      module:,
      constructor:,
      label:,
      index:,
    ) ->
      FieldAccess(
        typ: substitute_type(c, rename, typ),
        location:,
        container: substitute_expression(c, rename, container),
        module:,
        constructor:,
        label:,
        index:,
      )
    Call(typ:, location:, function:, arguments:, positional_arguments:) ->
      Call(
        typ: substitute_type(c, rename, typ),
        location:,
        function: substitute_expression(c, rename, function),
        arguments: list.map(
          arguments,
          map_field(_, substitute_expression(c, rename, _)),
        ),
        positional_arguments: list.map(
          positional_arguments,
          substitute_expression(c, rename, _),
        ),
      )
    TupleIndex(typ:, location:, tuple:, index:) ->
      TupleIndex(
        typ: substitute_type(c, rename, typ),
        location:,
        tuple: substitute_expression(c, rename, tuple),
        index:,
      )
    FnCapture(
      typ:,
      location:,
      label:,
      function:,
      arguments_before:,
      arguments_after:,
    ) ->
      FnCapture(
        typ: substitute_type(c, rename, typ),
        location:,
        label:,
        function: substitute_expression(c, rename, function),
        arguments_before: list.map(
          arguments_before,
          map_field(_, substitute_expression(c, rename, _)),
        ),
        arguments_after: list.map(
          arguments_after,
          map_field(_, substitute_expression(c, rename, _)),
        ),
      )
    BitString(typ:, location:, segments:) ->
      BitString(
        typ: substitute_type(c, rename, typ),
        location:,
        segments: list.map(segments, fn(segment) {
          let #(expr, options) = segment
          #(
            substitute_expression(c, rename, expr),
            list.map(
              options,
              map_bit_string_segment_option(_, substitute_expression(
                c,
                rename,
                _,
              )),
            ),
          )
        }),
      )
    Case(typ:, location:, subjects:, clauses:) ->
      Case(
        typ: substitute_type(c, rename, typ),
        location:,
        subjects: list.map(subjects, substitute_expression(c, rename, _)),
        clauses: list.map(clauses, substitute_clause(c, rename, _)),
      )
    BinaryOperator(typ:, location:, name:, left:, right:) ->
      BinaryOperator(
        typ: substitute_type(c, rename, typ),
        location:,
        name:,
        left: substitute_expression(c, rename, left),
        right: substitute_expression(c, rename, right),
      )
    Pipe(typ:, location:, left:, right:) ->
      Pipe(
        typ: substitute_type(c, rename, typ),
        location:,
        left: substitute_expression(c, rename, left),
        right: substitute_pipe_into(c, rename, right),
      )
  }
}

fn substitute_pipe_into(
  c: Context,
  rename: Dict(TypeVarId, TypeVarId),
  right: PipeInto,
) -> PipeInto {
  case right {
    PipeIntoEcho(message:) ->
      PipeIntoEcho(
        message: option.map(message, substitute_expression(c, rename, _)),
      )
    PipeIntoFnCapture(label:, function:, arguments_before:, arguments_after:) ->
      PipeIntoFnCapture(
        label:,
        function: substitute_expression(c, rename, function),
        arguments_before: list.map(
          arguments_before,
          map_field(_, substitute_expression(c, rename, _)),
        ),
        arguments_after: list.map(
          arguments_after,
          map_field(_, substitute_expression(c, rename, _)),
        ),
      )
  }
}

fn substitute_clause(
  c: Context,
  rename: Dict(TypeVarId, TypeVarId),
  clause: Clause,
) -> Clause {
  Clause(
    patterns: list.map(clause.patterns, fn(alternative) {
      list.map(alternative, substitute_pattern(c, rename, _))
    }),
    guard: option.map(clause.guard, substitute_expression(c, rename, _)),
    body: substitute_expression(c, rename, clause.body),
  )
}

fn substitute_pattern(
  c: Context,
  rename: Dict(TypeVarId, TypeVarId),
  pattern: Pattern,
) -> Pattern {
  case pattern {
    PatternInt(..) -> pattern
    PatternFloat(..) -> pattern
    PatternString(..) -> pattern
    PatternDiscard(typ:, location:, name:) ->
      PatternDiscard(typ: substitute_type(c, rename, typ), location:, name:)
    PatternVariable(typ:, location:, name:) ->
      PatternVariable(typ: substitute_type(c, rename, typ), location:, name:)
    PatternTuple(typ:, location:, elements:) ->
      PatternTuple(
        typ: substitute_type(c, rename, typ),
        location:,
        elements: list.map(elements, substitute_pattern(c, rename, _)),
      )
    PatternList(typ:, location:, elements:, tail:) ->
      PatternList(
        typ: substitute_type(c, rename, typ),
        location:,
        elements: list.map(elements, substitute_pattern(c, rename, _)),
        tail: option.map(tail, substitute_pattern(c, rename, _)),
      )
    PatternAssignment(typ:, location:, pattern:, name:) ->
      PatternAssignment(
        typ: substitute_type(c, rename, typ),
        location:,
        pattern: substitute_pattern(c, rename, pattern),
        name:,
      )
    PatternConcatenate(typ:, location:, prefix:, prefix_name:, rest_name:) ->
      PatternConcatenate(
        typ: substitute_type(c, rename, typ),
        location:,
        prefix:,
        prefix_name:,
        rest_name:,
      )
    PatternBitString(typ:, location:, segments:) ->
      PatternBitString(
        typ: substitute_type(c, rename, typ),
        location:,
        segments: list.map(segments, fn(segment) {
          let #(pattern, options) = segment
          #(
            substitute_pattern(c, rename, pattern),
            list.map(
              options,
              map_bit_string_segment_option(_, substitute_pattern(c, rename, _)),
            ),
          )
        }),
      )
    PatternVariant(
      typ:,
      location:,
      module:,
      constructor:,
      arguments:,
      with_spread:,
      resolved_module:,
      positional_arguments:,
    ) ->
      PatternVariant(
        typ: substitute_type(c, rename, typ),
        location:,
        module:,
        constructor:,
        arguments: list.map(
          arguments,
          map_field(_, substitute_pattern(c, rename, _)),
        ),
        with_spread:,
        resolved_module:,
        positional_arguments: list.map(positional_arguments, fn(arg) {
          case arg {
            MatchedArgument(p) ->
              MatchedArgument(substitute_pattern(c, rename, p))
            UnmatchedArgument(typ) ->
              UnmatchedArgument(substitute_type(c, rename, typ))
          }
        }),
      )
  }
}

fn substitute_poly(c: Context, rename: Dict(TypeVarId, TypeVarId), poly: Poly) {
  let vars =
    list.map(poly.vars, fn(v) { dict.get(rename, v) |> result.unwrap(v) })
  Poly(vars, substitute_type(c, rename, poly.typ))
}

fn substitute_type(c: Context, rename: Dict(TypeVarId, TypeVarId), typ: Type) {
  case typ {
    NamedType(module:, name:, parameters:) -> {
      let parameters = list.map(parameters, substitute_type(c, rename, _))
      NamedType(module:, name:, parameters:)
    }
    FunctionType(parameters, return) -> {
      let parameters = list.map(parameters, substitute_type(c, rename, _))
      let return = substitute_type(c, rename, return)
      FunctionType(parameters:, return:)
    }
    TupleType(elements) -> {
      let elements = list.map(elements, substitute_type(c, rename, _))
      TupleType(elements:)
    }
    VariableType(ref) -> {
      case get_type_var(c, ref) {
        Bound(x) -> substitute_type(c, rename, x)
        Unbound -> VariableType(dict.get(rename, ref) |> result.unwrap(ref))
      }
    }
  }
}

fn substitute_annotation(
  c: Context,
  rename: Dict(TypeVarId, TypeVarId),
  annotation: Annotation,
) -> Annotation {
  case annotation {
    NamedAnno(typ:, location:, module:, name:, parameters:) ->
      NamedAnno(
        typ: substitute_type(c, rename, typ),
        location:,
        module:,
        name:,
        parameters: list.map(parameters, substitute_annotation(c, rename, _)),
      )
    TupleAnno(typ:, location:, elements:) ->
      TupleAnno(
        typ: substitute_type(c, rename, typ),
        location:,
        elements: list.map(elements, substitute_annotation(c, rename, _)),
      )
    FunctionAnno(typ:, location:, parameters:, return:) ->
      FunctionAnno(
        typ: substitute_type(c, rename, typ),
        location:,
        parameters: list.map(parameters, substitute_annotation(c, rename, _)),
        return: substitute_annotation(c, rename, return),
      )
    VariableAnno(typ:, location:, name:) ->
      VariableAnno(typ: substitute_type(c, rename, typ), location:, name:)
    HoleAnno(typ:, location:, name:) ->
      HoleAnno(substitute_type(c, rename, typ), location:, name:)
  }
}

fn map_field(field: Field(a), func: fn(a) -> b) -> Field(b) {
  case field {
    LabelledField(item:, label:, label_location:) ->
      LabelledField(func(item), label, label_location)
    ShorthandField(item:, label:, location:) ->
      ShorthandField(func(item), label, location)
    UnlabelledField(item) -> UnlabelledField(func(item))
  }
}

fn infer_pattern_fields(
  c: Context,
  n: LocalEnv,
  fields: List(Field(g.Pattern)),
) -> Result(#(Context, LocalEnv, List(Field(Pattern))), Error) {
  use #(c, n, fields) <- result.map(
    list.try_fold(fields, #(c, n, []), fn(acc, field) {
      let #(c, n, done) = acc
      use #(c, n, inferred) <- result.map(infer_pattern(c, n, field.item))
      #(c, n, [map_field(field, fn(_) { inferred }), ..done])
    }),
  )
  #(c, n, list.reverse(fields))
}

fn build_arg_hints(
  args: List(Field(a)),
  labels: List(Option(String)),
  param_types: List(Type),
) -> List(#(Option(Type), Field(a))) {
  let labelled_hints =
    list.zip(labels, param_types)
    |> list.filter_map(fn(pair) {
      case pair.0 {
        Some(label) -> Ok(#(label, pair.1))
        None -> Error(Nil)
      }
    })
    |> dict.from_list
  // Collect the labels used by labelled call-args so we can skip those slots
  let claimed_labels =
    list.filter_map(args, fn(a) {
      case field_label(a) {
        Some(l) -> Ok(l)
        None -> Error(Nil)
      }
    })
  // Unlabelled call-args are matched positionally against params whose slot is
  // not already claimed by a labelled call-arg
  let unlabelled_hints =
    list.zip(labels, param_types)
    |> list.filter_map(fn(pair) {
      case pair.0 {
        Some(label) ->
          case list.contains(claimed_labels, label) {
            True -> Error(Nil)
            False -> Ok(pair.1)
          }
        None -> Ok(pair.1)
      }
    })
  let #(_, hinted_reversed) =
    list.fold(args, #(unlabelled_hints, []), fn(state, arg) {
      let #(remaining_unlabelled, done) = state
      case field_label(arg) {
        Some(label) -> #(remaining_unlabelled, [
          #(
            dict.get(labelled_hints, label)
              |> result.map(Some)
              |> result.unwrap(None),
            arg,
          ),
          ..done
        ])
        None ->
          case remaining_unlabelled {
            [hint, ..rest] -> #(rest, [#(Some(hint), arg), ..done])
            [] -> #([], [#(None, arg), ..done])
          }
      }
    })
  list.reverse(hinted_reversed)
}

fn variant_field_label(field: VariantField(t)) -> Option(String) {
  case field {
    LabelledVariantField(_, label) -> Some(label)
    UnlabelledVariantField(_) -> None
  }
}

fn field_label(field: Field(a)) -> Option(String) {
  case field {
    LabelledField(..) -> Some(field.label)
    ShorthandField(..) -> Some(field.label)
    UnlabelledField(..) -> None
  }
}

fn map_definition(def: Definition(a), func: fn(a) -> b) -> Definition(b) {
  Definition(..def, definition: func(def.definition))
}

fn context_location(c: Context) {
  Location(c.module.name, c.current_definition, c.current_span)
}

fn map_bit_string_segment_option(
  option: BitStringSegmentOption(a),
  func: fn(a) -> a,
) -> BitStringSegmentOption(a) {
  case option {
    SizeValueOption(expr) -> SizeValueOption(func(expr))
    _ -> option
  }
}

fn extract_matching(
  in list: List(a),
  one_that is_desired: fn(a) -> Bool,
) -> Result(#(a, List(a)), Nil) {
  extract_matching_loop(list, is_desired, [])
}

fn extract_matching_loop(haystack, predicate, checked) {
  case haystack {
    [] -> Error(Nil)
    [first, ..rest] ->
      case predicate(first) {
        True -> Ok(#(first, list.append(list.reverse(checked), rest)))
        False -> extract_matching_loop(rest, predicate, [first, ..checked])
      }
  }
}
