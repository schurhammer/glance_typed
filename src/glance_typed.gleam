import glance.{Span} as g
import glance_typed/call_graph
import glance_typed/graph
import glance_typed/match
import gleam/order

import gleam/dict.{type Dict}
import gleam/float
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
    warnings: List(Warning),
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
    arguments: List(Field(Expression)),
    body: List(Statement),
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
    segments: List(#(Pattern, List(BitStringSegmentOption(BitArraySize)))),
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

pub type BitArraySize {
  BitArraySizeInt(location: Span, value: String)
  BitArraySizeVariable(location: Span, name: String)
  BitArraySizeBinaryOperator(
    location: Span,
    operator: BitArraySizeOperator,
    left: BitArraySize,
    right: BitArraySize,
  )
  BitArraySizeBlock(location: Span, inner: BitArraySize)
}

pub type BitArraySizeOperator {
  BitArraySizeAdd
  BitArraySizeSubtract
  BitArraySizeMultiply
  BitArraySizeDivide
  BitArraySizeRemainder
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
  NarrowedType(typ: Type, variants: List(VariantRef))
}

pub type VariantRef {
  VariantRef(module: String, name: String)
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
  UnresolvedModuleValue(location: Location, name: String)
  UnresolvedType(location: Location, name: String)
  DuplicateFunction(location: Location, name: String)
  DuplicateConstant(location: Location, name: String)
  DuplicateType(location: Location, name: String)
  InvalidTupleAccess(location: Location)
  InvalidFieldAccess(location: Location)
  FieldNotFound(location: Location, name: String)
  InconsistentFieldAccess(location: Location, name: String)
  UnresolvedTypeVariable(location: Location, name: String)
  NotAFunction(location: Location, name: String)
  WrongArity(location: Location, expected_arg_count: Int, actual_arg_count: Int)
  InconsistentAlternativeBindings(location: Location, name: String)
  LabelNotFound(location: Location, name: String)
  DuplicateLabel(location: Location, name: String)
  RecordUpdateOnUnlabelledConstructor(location: Location)
  UnexpectedPositionalArgument(location: Location)
  TupleIndexOutOfBounds(location: Location, tuple_size: Int, index: Int)
  IncompatibleTypes(location: Location, type_a: Type, type_b: Type)
  RecursiveTypeError(location: Location)
  BitPatternSegmentTypeOverSpecified(location: Location)
  InvalidAttributeArgument(location: Location)
  NonExhaustiveCase(location: Location, missing: List(String))
  LetPatternNotExhaustive(location: Location, missing: List(String))
  UnsafeRecordUpdate(location: Location, constructor: String)
}

/// The reason an implicit `todo` expression was inserted.
pub type TodoKind {
  EmptyFunction
  EmptyBlock
  IncompleteUse
}

/// A non-fatal problem found while type checking.
pub type Warning {
  /// An implicit todo was inserted in an empty function, block, or use statement.
  ImplicitTodo(location: Location, kind: TodoKind)
  /// An unnecessarry spread operator on a pattern match.
  UnnecessarySpread(location: Location, field_count: Int)
  /// An unnecessarry record update, either nothing updated or everything updated.
  UnnecessaryRecordUpdate(location: Location, field_count: Int)
  /// A function or constant has the same name as an unqualified import.
  ShadowsImport(location: Location, name: String)
  /// A pattern that can never match because of earlier patterns.
  UnreachablePattern(location: Location)
}

type QualifiedName {
  QualifiedName(module: String, name: String)
}

pub type ModuleValue {
  ModuleFunction(
    module: String,
    name: String,
    typ: Poly,
    labels: List(Option(String)),
  )
  ModuleConstant(module: String, name: String, typ: Poly)
}

type Origin {
  Local
  Imported
}

type ResolvedVariable {
  ResolvedLocal(name: String, typ: Type)
  ResolvedModuleValue(module_value: ModuleValue)
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
    type_env: Dict(QualifiedName, #(Poly, List(Variant))),
    type_origin: Dict(QualifiedName, Origin),
    value_env: Dict(QualifiedName, ModuleValue),
    value_origin: Dict(QualifiedName, Origin),
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
    list.try_fold(module.imports, c, fn(c, def) {
      let imp = def.definition
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

      use #(type_env, type_origin) <- result.try(
        list.try_fold(
          imp.unqualified_types,
          #(c.type_env, c.type_origin),
          fn(acc, imp) {
            let #(type_env, type_origin) = acc
            let resolved = lookup_module_type(c, module_id, imp.name)
            use #(poly, variants) <- result.map(resolved)
            let alias = case imp.alias {
              Some(alias) -> alias
              None -> imp.name
            }
            let name = QualifiedName(c.module.name, alias)
            let type_env = dict.insert(type_env, name, #(poly, variants))
            let type_origin = dict.insert(type_origin, name, Imported)
            #(type_env, type_origin)
          },
        ),
      )

      use #(value_env, value_origin) <- result.try(
        list.try_fold(
          imp.unqualified_values,
          #(c.value_env, c.value_origin),
          fn(acc, imp) {
            let #(value_env, value_origin) = acc
            let resolved = lookup_module_value(c, module_id, imp.name)
            use value <- result.map(resolved)
            let alias = case imp.alias {
              Some(alias) -> alias
              None -> imp.name
            }
            let name = QualifiedName(c.module.name, alias)
            let value_env = dict.insert(value_env, name, value)
            let value_origin = dict.insert(value_origin, name, Imported)
            #(value_env, value_origin)
          },
        ),
      )

      use attributes <- result.map(infer_attributes(c, def.attributes))
      let typed_import =
        Definition(
          attributes,
          Import(
            location: imp.location,
            module: module_id,
            alias: option.map(imp.alias, convert_assignment_name),
            unqualified_types: list.map(
              imp.unqualified_types,
              convert_unqualified_import,
            ),
            unqualified_values: list.map(
              imp.unqualified_values,
              convert_unqualified_import,
            ),
          ),
        )
      let module =
        Module(..c.module, imports: [typed_import, ..c.module.imports])
      Context(
        ..c,
        module_aliases:,
        type_env:,
        type_origin:,
        value_env:,
        value_origin:,
        module:,
      )
    }),
  )

  // add types to env so they can reference eachother (but not yet constructors)
  use c <- result.try(
    list.try_fold(module.custom_types, c, fn(c, def) {
      let custom = def.definition
      let c = Context(..c, current_definition: custom.name)
      let c = Context(..c, current_span: def.definition.location)

      use c <- result.map(claim_type_name(c, custom.name, context_location(c)))

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
    }),
  )

  // add types aliases to env so they can reference eachother
  use c <- result.try(
    list.try_fold(module.type_aliases, c, fn(c, def) {
      let alias = def.definition
      let location = span_location(c, alias.location)
      use c <- result.map(claim_type_name(c, alias.name, location))
      let #(c, typ) = new_type_var_ref(c)
      register_type(c, alias.name, Poly([], typ), [])
    }),
  )

  // infer type aliases fr fr
  use #(c, aliases) <- result.try(
    list.try_fold(module.type_aliases, #(c, []), fn(acc, def) {
      let #(c, aliases) = acc
      let c = Context(..c, current_definition: def.definition.name)
      let c = Context(..c, current_span: def.definition.location)

      // infer the alias type
      use #(c, alias) <- result.try(infer_alias_type(c, def.definition))

      // update the placeholder type
      let resolved = lookup_module_type(c, c.module.name, alias.name)
      use #(placeholder, _) <- result.try(resolved)
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
      let alias = TypeAlias(..alias, typ: poly)
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
      let resolved = lookup_module_type(c, c.module.name, custom.name)
      use #(poly, _) <- result.try(resolved)
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

  use c <- result.try(
    list.try_fold(module.constants, c, fn(c, def) {
      let con = def.definition
      let location = span_location(c, con.location)
      claim_value_name(c, con.name, location, DuplicateConstant)
    }),
  )

  let constants =
    call_graph.constant_graph(module)
    |> graph.strongly_connected_components()
    |> list.flatten()
    |> list.map(fn(name) {
      let assert Ok(def) =
        list.find(module.constants, fn(def) { def.definition.name == name })
      def
    })

  // add functions to the module value env so they are available for recursion
  use c <- result.try(
    list.try_fold(module.functions, c, fn(c, def) {
      let fun = def.definition
      let c = Context(..c, current_definition: fun.name)
      let c = Context(..c, current_span: fun.location)

      use c <- result.try(claim_value_name(
        c,
        fun.name,
        context_location(c),
        DuplicateFunction,
      ))

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

      register_function(c, fun.name, Poly([], typ), param_labels)
    }),
  )

  // infer constant expressions
  use c <- result.try(
    list.try_fold(constants, c, fn(c, def) {
      let c = Context(..c, current_definition: def.definition.name)
      let c = Context(..c, current_span: def.definition.location)
      use #(c, constant) <- result.try(infer_constant(c, def.definition))

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
      let group =
        list.map(group, fn(fun_name) {
          let assert Ok(def) =
            list.find(module.functions, fn(f) { f.definition.name == fun_name })
          def
        })

      // infer types for the group
      use #(c, group) <- result.try(
        list.try_fold(group, #(c, []), fn(acc, def) {
          let #(c, group) = acc
          let c = Context(..c, current_definition: def.definition.name)
          let c = Context(..c, current_span: def.definition.location)

          // infer function
          use #(c, fun) <- result.try(infer_function(c, def))
          use attrs <- result.map(infer_attributes(c, def.attributes))
          let def = Definition(attrs, fun)

          #(c, [def, ..group])
        }),
      )

      // generalise
      list.try_fold(group, c, fn(c, def) {
        let fun = def.definition

        // unify placeholder type
        let resolved = lookup_module_value(c, c.module.name, fun.name)
        use placeholder <- result.try(resolved)
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
    custom_types: list.filter_map(module.custom_types, fn(t) {
      let custom_type = t.definition
      case custom_type.publicity {
        Private -> Error(Nil)
        Public if custom_type.opaque_ ->
          Ok(CustomType(..custom_type, variants: []))
        Public -> Ok(custom_type)
      }
    }),
    type_aliases: list.filter_map(module.type_aliases, fn(t) {
      case t.definition.publicity {
        Public -> Ok(t.definition)
        Private -> Error(Nil)
      }
    }),
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

pub fn known_variants(typ: Type) -> List(VariantRef) {
  case typ {
    NarrowedType(_, variants) -> variants
    _ -> []
  }
}

/// Recursively removes NarrowedType, leaving just the plain type.
pub fn concrete_type(typ: Type) -> Type {
  case typ {
    NarrowedType(typ, _) -> concrete_type(typ)
    NamedType(module, name, parameters) ->
      NamedType(module, name, list.map(parameters, concrete_type))
    TupleType(elements) -> TupleType(list.map(elements, concrete_type))
    FunctionType(parameters, return) ->
      FunctionType(list.map(parameters, concrete_type), concrete_type(return))
    VariableType(_) -> typ
  }
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
      warnings: [],
      name: module_name,
    ),
    type_uid: 0,
    temp_uid: 1,
    module_aliases: dict.new(),
    type_env: dict.new(),
    type_origin: dict.new(),
    value_env: dict.new(),
    value_origin: dict.new(),
  )
}

/// Desugar a `use` statement into a regular function call.
/// Returns `Error(Nil)` if the statement is not `Use`,
/// or if the arguments could not be matched to the function.
pub fn desugar_use(statement: Statement) -> Result(Expression, Nil) {
  case statement {
    Use(typ:, location:, patterns:, function:, arguments:, body:) -> {
      let arguments =
        list.append(arguments, [
          UnlabelledField(use_callback(location, patterns, body)),
        ])
      let labels = case function {
        Function(labels:, ..) -> labels
        _ -> list.map(arguments, fn(_) { None })
      }
      use positional <- result.map(
        match_fields(arguments, labels) |> result.replace_error(Nil),
      )
      Call(typ, location, function, arguments, positional)
    }
    _ -> Error(Nil)
  }
}

fn use_callback(
  location: Span,
  patterns: List(UsePattern),
  body: List(Statement),
) -> Expression {
  let parameters =
    list.index_map(patterns, fn(pattern, i) {
      FnParameter(pattern.pattern.typ, Named(use_parameter_name(i)), None)
    })
  // one assignment per pattern, binding it to the parameter, in source order
  let assignments =
    list.index_map(patterns, fn(pattern, i) {
      let typ = pattern.pattern.typ
      let variable = LocalVariable(typ, location, use_parameter_name(i))
      Assignment(
        typ,
        location,
        Let,
        pattern.pattern,
        pattern.annotation,
        variable,
      )
    })
  let body = list.append(assignments, body)
  // the callback's return type is recovered from the body's tail, since there
  // is nothing left to infer it from at this point
  let return = option.unwrap(body_type(body), nil_type)
  let typ = FunctionType(list.map(parameters, fn(p) { p.typ }), return)
  Fn(typ, location, parameters, None, body)
}

fn use_parameter_name(index: Int) -> String {
  "P" <> int.to_string(index)
}

/// Returns a human-readable string description of the error.
/// Does not include the span (location) of the error.
pub fn inspect_error(error: Error) {
  case error {
    UnresolvedModule(name:, ..) -> "Module with name '" <> name <> "' not found"
    UnresolvedModuleValue(name:, ..) ->
      "Module value with name '" <> name <> "' not found"
    UnresolvedType(name:, ..) -> "Type with name '" <> name <> "' not found"
    DuplicateFunction(name:, ..) | DuplicateConstant(name:, ..) ->
      "The name '"
      <> name
      <> "' is already used by another definition in this module"
    DuplicateType(name:, ..) ->
      "The name '" <> name <> "' is already used by another type in this module"
    InvalidTupleAccess(..) -> "Attempted tuple access on a non-tuple type"
    InvalidFieldAccess(..) -> "Attempted field access on a non-record type"
    FieldNotFound(name:, ..) ->
      "This record does not have a field named '" <> name <> "'"
    InconsistentFieldAccess(name:, ..) ->
      "The field '"
      <> name
      <> "' is not present at the same position with the same type in every variant of this custom type"
    UnresolvedTypeVariable(name:, ..) ->
      "Type variable with name '" <> name <> "' not found"
    NotAFunction(name:, ..) -> "The variable '" <> name <> "' is not a function"
    WrongArity(expected_arg_count:, actual_arg_count:, ..) ->
      "Expected "
      <> int.to_string(expected_arg_count)
      <> " argument(s), got "
      <> int.to_string(actual_arg_count)
    InconsistentAlternativeBindings(name:, ..) ->
      "The patterns of this case clause do not all bind '" <> name <> "'"
    LabelNotFound(name:, ..) -> "'" <> name <> "' is not a valid label"
    DuplicateLabel(name:, ..) ->
      "The label '" <> name <> "' has already been given a value"
    RecordUpdateOnUnlabelledConstructor(..) ->
      "This constructor has no labelled fields, so it cannot be used with the update syntax"
    UnexpectedPositionalArgument(..) ->
      "Positional arguments cannot follow a labelled argument"
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
    NonExhaustiveCase(missing:, ..) ->
      "This case expression does not have a pattern for all possible values. "
      <> "The missing patterns are:\n\n"
      <> list.map(missing, fn(pattern) { "    " <> pattern })
      |> string.join("\n")
    LetPatternNotExhaustive(missing:, ..) ->
      "This assignment uses a pattern that does not match all possible values. "
      <> "The missing patterns are:\n\n"
      <> list.map(missing, fn(pattern) { "    " <> pattern })
      |> string.join("\n")
    UnsafeRecordUpdate(constructor:, ..) ->
      "This value is not known to be a '"
      <> constructor
      <> "', so it cannot be updated with the record update syntax"
  }
}

/// Returns a human-readable string description of the warning.
pub fn inspect_warning(warning: Warning) {
  case warning {
    ImplicitTodo(kind:, ..) ->
      case kind {
        EmptyFunction ->
          "Function body is empty, an implicit `todo` expression is inserted"
        EmptyBlock ->
          "Block is empty, an implicit `todo` expression is inserted"
        IncompleteUse ->
          "Use expression has no statements after it, an implicit `todo` expression is inserted"
      }
    UnnecessarySpread(field_count: 0, ..) ->
      "This constructor has no fields, so `..` matches nothing"
    UnnecessarySpread(field_count:, ..) ->
      "All "
      <> int.to_string(field_count)
      <> " fields are already matched, so `..` matches nothing"
    UnnecessaryRecordUpdate(field_count: 0, ..) ->
      "This update sets no fields, so it is unchanged from the original"
    UnnecessaryRecordUpdate(field_count:, ..) ->
      "This update sets all "
      <> int.to_string(field_count)
      <> " fields, so `..` has no effect"
    ShadowsImport(name:, ..) ->
      "This definition shadows the imported '" <> name <> "'"
    UnreachablePattern(..) ->
      "This pattern cannot be reached as a previous pattern matches the same values"
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
      QualifiedName(c.module.name, name),
      ModuleFunction(c.module.name, name, typ, labels),
    )
  Context(..c, value_env:)
}

fn register_constant(c: Context, name: String, typ: Poly) -> Context {
  let value_env =
    dict.insert(
      c.value_env,
      QualifiedName(c.module.name, name),
      ModuleConstant(c.module.name, name, typ),
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
    dict.insert(c.type_env, QualifiedName(c.module.name, name), #(typ, variants))
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

  use #(c, annotation) <- result.try(infer_optional_annotation(
    c,
    dict.new(),
    con.annotation,
  ))

  // if there is an annotation, the value must unify with it
  use c <- result.map(case annotation {
    Some(anno) -> unify(c, value.typ, anno.typ)
    None -> Ok(c)
  })

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
  def: g.Definition(g.Function),
) -> Result(#(Context, FunctionDefinition), Error) {
  let is_external =
    list.any(def.attributes, fn(attr) { attr.name == "external" })
  let fun = def.definition
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

  // an empty body is an implicit `todo`, unless the function is external
  use #(c, body) <- result.try(case is_external {
    True -> infer_body(c, n, fun.body)
    False -> infer_body_or_todo(c, n, fun.body, EmptyFunction)
  })

  // compute function type
  let parameter_types = list.map(parameters, fn(x) { x.typ })
  let typ = FunctionType(parameter_types, return_type)

  // unify the return type with the last statement
  use c <- result.map(unify_body_return(c, return_type, body))

  let typ = case fun.return, body_type(body) {
    None, Some(tail) -> FunctionType(parameter_types, tail)
    _, _ -> typ
  }

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
  use c <- result.try(claim_value_name(
    c,
    variant.name,
    context_location(c),
    DuplicateFunction,
  ))

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
      use #(poly, _variants) <- result.try(resolve_type_name(c, module, name))
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
        QualifiedName(m.name, constant.name),
        ModuleConstant(m.name, constant.name, constant.typ),
      )
    })
  let value_env =
    list.fold(m.functions, value_env, fn(value_env, function) {
      dict.insert(
        value_env,
        QualifiedName(m.name, function.name),
        ModuleFunction(
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
        QualifiedName(m.name, variant.name),
        ModuleFunction(
          m.name,
          variant.name,
          variant.typ,
          list.map(variant.fields, variant_field_label),
        ),
      )
    })

  let type_env =
    list.fold(m.custom_types, c.type_env, fn(type_env, custom_type) {
      let name = QualifiedName(m.name, custom_type.name)
      dict.insert(type_env, name, #(custom_type.typ, custom_type.variants))
    })

  let type_env =
    list.fold(m.type_aliases, type_env, fn(type_env, type_alias) {
      let name = QualifiedName(m.name, type_alias.name)
      dict.insert(type_env, name, #(type_alias.typ, []))
    })

  Context(..c, value_env:, type_env:)
}

/// Resolve an unqualified name against the local scope, then module scope.
fn resolve_unqualified_name(
  c: Context,
  n: LocalEnv,
  name: String,
) -> Result(ResolvedVariable, Error) {
  dict.get(n, name)
  |> result.map(ResolvedLocal(name, _))
  |> result.try_recover(fn(_) {
    resolve_unqualified_module_value(c, name) |> result.map(ResolvedModuleValue)
  })
}

/// Resolve an unqualified name against the module scope.
fn resolve_unqualified_module_value(
  c: Context,
  name: String,
) -> Result(ModuleValue, Error) {
  // try the current module
  lookup_module_value(c, c.module.name, name)
  |> result.try_recover(fn(_) {
    // try prelude
    lookup_module_value(c, prelude, name)
  })
}

/// Resolve a module value from a possibly aliased module
fn resolve_aliased_module_value(
  c: Context,
  name: QualifiedName,
) -> Result(ModuleValue, Error) {
  lookup_module_alias(c, name.module)
  |> result.try(lookup_module_value(c, _, name.name))
}

/// Look up a value by its non-aliased module name
fn lookup_module_value(
  c: Context,
  module_name: String,
  name: String,
) -> Result(ModuleValue, Error) {
  dict.get(c.value_env, QualifiedName(module_name, name))
  |> result.replace_error(UnresolvedModuleValue(context_location(c), name))
}

/// Resolve a type name in the module scope.
fn resolve_type_name(
  c: Context,
  mod: Option(String),
  name: String,
) -> Result(#(Poly, List(Variant)), Error) {
  case mod {
    Some(mod) -> resolve_aliased_type_name(c, mod, name)
    None ->
      lookup_module_type(c, c.module.name, name)
      |> result.try_recover(fn(_) { lookup_module_type(c, prelude, name) })
  }
}

/// Resolve a type name from a possibly aliased module
fn resolve_aliased_type_name(
  c: Context,
  module: String,
  name: String,
) -> Result(#(Poly, List(Variant)), Error) {
  lookup_module_alias(c, module)
  |> result.try(lookup_module_type(c, _, name))
}

/// Look up a type by its non-aliased module name
fn lookup_module_type(
  c: Context,
  module_name: String,
  name: String,
) -> Result(#(Poly, List(Variant)), Error) {
  dict.get(c.type_env, QualifiedName(module_name, name))
  |> result.replace_error(UnresolvedType(
    context_location(c),
    module_name <> "." <> name,
  ))
}

/// Resolve a qualified or unqualified contructor name
fn resolve_constructor_name(c: Context, mod: Option(String), name: String) {
  case mod {
    Some(mod) -> resolve_aliased_module_value(c, QualifiedName(mod, name))
    None -> resolve_unqualified_module_value(c, name)
  }
}

/// Look up a module alias, returning its fully qualified name
fn lookup_module_alias(
  c: Context,
  module_name: String,
) -> Result(String, Error) {
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
  #(Context(..c, type_vars:, type_uid: c.type_uid + 1), typ)
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

fn convert_unqualified_import(imp: g.UnqualifiedImport) -> UnqualifiedImport {
  UnqualifiedImport(imp.name, imp.alias)
}

/// Check that the bit array size expression only references int values.
fn infer_bit_array_size(
  c: Context,
  n: LocalEnv,
  size: g.BitArraySize,
) -> Result(#(Context, BitArraySize), Error) {
  case size {
    g.BitArraySizeInt(location:, value:) ->
      Ok(#(c, BitArraySizeInt(location, value)))
    g.BitArraySizeVariable(location:, name:) -> {
      let c = Context(..c, current_span: location)
      use c <- result.try(case resolve_unqualified_name(c, n, name) {
        Ok(ResolvedLocal(_, typ)) -> unify(c, typ, int_type)
        Ok(ResolvedModuleValue(ModuleConstant(_, _, poly)))
        | Ok(ResolvedModuleValue(ModuleFunction(_, _, poly, _))) -> {
          let #(c, typ) = instantiate(c, poly)
          unify(c, typ, int_type)
        }
        Error(e) -> Error(e)
      })
      Ok(#(c, BitArraySizeVariable(location, name)))
    }
    g.BitArraySizeBinaryOperator(location:, operator:, left:, right:) -> {
      use #(c, left) <- result.try(infer_bit_array_size(c, n, left))
      use #(c, right) <- result.map(infer_bit_array_size(c, n, right))
      let operator = case operator {
        g.BitArraySizeAdd -> BitArraySizeAdd
        g.BitArraySizeSubtract -> BitArraySizeSubtract
        g.BitArraySizeMultiply -> BitArraySizeMultiply
        g.BitArraySizeDivide -> BitArraySizeDivide
        g.BitArraySizeRemainder -> BitArraySizeRemainder
      }
      #(c, BitArraySizeBinaryOperator(location, operator, left, right))
    }
    g.BitArraySizeBlock(location:, inner:) -> {
      use #(c, inner) <- result.map(infer_bit_array_size(c, n, inner))
      #(c, BitArraySizeBlock(location, inner))
    }
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
                g.SizeValueOption(size) -> {
                  use #(c, size) <- result.map(infer_bit_array_size(c, n, size))
                  #(c, n, SizeValueOption(size), None)
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

      use _ <- result.try(check_arg_order(c, arguments, fn(p) { p.location }))

      // infer the type of all arguments
      let arguments = list.map(arguments, convert_field(_, g.PatternVariable))
      use #(c, n, arguments) <- result.try(infer_pattern_fields(c, n, arguments))

      // handle labels
      let matched = match_pattern_args(c, arguments, labels, with_spread)
      use #(c, positional_arguments) <- result.try(matched)

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

/// Narrow a type to the given variants, intersecting with any existing narrowing.
fn narrow_type(typ: Type, variants: List(VariantRef)) -> Type {
  case variants {
    [] -> typ
    _ ->
      case typ {
        NarrowedType(base, existing) ->
          NarrowedType(base, list.filter(existing, list.contains(variants, _)))
        _ -> NarrowedType(typ, list.unique(variants))
      }
  }
}

type SubjectPath {
  SubjectVar(name: String)
  SubjectTuple(elements: List(Result(SubjectPath, Nil)))
}

fn expression_path(expression: Expression) -> Result(SubjectPath, Nil) {
  case expression {
    LocalVariable(name:, ..) -> Ok(SubjectVar(name))
    Tuple(elements:, ..) ->
      case list.map(elements, expression_path) {
        [] -> Error(Nil)
        paths -> Ok(SubjectTuple(paths))
      }
    Echo(expression: Some(inner), ..) -> expression_path(inner)
    _ -> Error(Nil)
  }
}

/// Extract variant facts and name bindings from the pattern for a specific path.
fn pattern_facts(
  pattern: Pattern,
  path: SubjectPath,
) -> #(List(Fact), List(#(String, SubjectPath))) {
  case pattern {
    PatternTuple(elements:, ..) ->
      case path {
        SubjectTuple(element_paths) -> {
          let pairs =
            list.strict_zip(elements, element_paths) |> result.unwrap([])
          list.fold(pairs, #([], []), fn(acc, pair) {
            let #(element, element_path) = pair
            let #(facts, aliases) = acc
            case element_path {
              Error(_) -> acc
              Ok(element_path) -> {
                let #(more_facts, more_aliases) =
                  pattern_facts(element, element_path)
                #(
                  list.append(facts, more_facts),
                  list.append(aliases, more_aliases),
                )
              }
            }
          })
        }
        _ -> #([], [])
      }
    PatternAssignment(pattern:, name:, ..) -> {
      let #(facts, aliases) = pattern_facts(pattern, path)
      let aliases = [#(name, path), ..aliases]
      #(facts, aliases)
    }
    // A variable pattern at the root binds the value of the subject so it
    // inherits its narrowing.
    PatternVariable(name:, ..) -> #([], [#(name, path)])
    PatternList(elements:, tail:, ..) ->
      case elements, tail {
        [], Some(tail) -> pattern_facts(tail, path)
        [], None -> #([#(path, VariantRef(prelude, "Empty"))], [])
        _, _ -> #([#(path, VariantRef(prelude, "NonEmpty"))], [])
      }
    PatternVariant(resolved_module:, constructor:, ..) -> #(
      [#(path, VariantRef(resolved_module, constructor))],
      [],
    )
    _ -> #([], [])
  }
}

type Fact =
  #(SubjectPath, VariantRef)

type FactGroup =
  #(SubjectPath, List(VariantRef))

/// Copies each fact to aliases introduced by as-patterns.
fn expand_alias_facts(
  facts: List(Fact),
  aliases: List(#(String, SubjectPath)),
) -> List(Fact) {
  list.append(
    facts,
    list.flat_map(aliases, fn(alias) {
      let #(name, path) = alias
      list.filter_map(facts, fn(entry) {
        case entry.0 == path {
          True -> Ok(#(SubjectVar(name), entry.1))
          False -> Error(Nil)
        }
      })
    }),
  )
}

fn group_facts(facts: List(Fact)) -> List(FactGroup) {
  list.fold(facts, [], fn(grouped: List(FactGroup), fact) {
    let #(path, variant) = fact
    let existing =
      list.find(grouped, fn(entry: FactGroup) { entry.0 == path })
      |> result.map(fn(entry) { entry.1 })
      |> result.unwrap([])
    let rest = list.filter(grouped, fn(entry: FactGroup) { entry.0 != path })
    [#(path, [variant, ..existing]), ..rest]
  })
}

/// Keep paths narrowed by every alternative, combining their possible variants.
fn merge_alternative_facts(alternatives: List(List(Fact))) -> List(FactGroup) {
  case alternatives {
    [] -> []
    [first, ..rest] ->
      list.fold(rest, group_facts(first), fn(merged, facts) {
        let grouped = group_facts(facts)
        list.filter_map(merged, fn(entry) {
          case list.find(grouped, fn(other) { other.0 == entry.0 }) {
            Ok(#(_, variants)) ->
              Ok(#(entry.0, list.unique(list.append(entry.1, variants))))
            Error(_) -> Error(Nil)
          }
        })
      })
  }
}

/// Remove facts about subject variables whose names are rebound by the pattern.
/// Those names refer to different values inside the clause.
fn drop_rebound(
  narrowings: List(FactGroup),
  bound: List(String),
) -> List(FactGroup) {
  list.filter(narrowings, fn(entry: FactGroup) {
    case entry.0 {
      SubjectVar(name) -> !list.contains(bound, name)
      SubjectTuple(..) -> True
    }
  })
}

fn apply_narrowings(
  n: LocalEnv,
  narrowings: List(#(SubjectPath, List(VariantRef))),
) -> LocalEnv {
  list.fold(narrowings, n, fn(n, narrowing) {
    let #(path, variants) = narrowing
    narrow_at_path(n, path, variants)
  })
}

fn narrow_at_path(
  n: LocalEnv,
  path: SubjectPath,
  variants: List(VariantRef),
) -> LocalEnv {
  case path {
    SubjectVar(name) ->
      case dict.get(n, name) {
        Ok(typ) -> dict.insert(n, name, narrow_type(typ, variants))
        Error(_) -> n
      }
    SubjectTuple(elements) ->
      list.fold(elements, n, fn(n, element) {
        case element {
          Ok(element) -> narrow_at_path(n, element, variants)
          Error(_) -> n
        }
      })
  }
}

/// Alternatives sharing a body must bind exactly the same names.
fn check_alternative_bindings(
  c: Context,
  alternatives: List(TypedAlternative),
) -> Result(Context, Error) {
  case alternatives {
    [] | [_] -> Ok(c)
    [first, ..rest] -> {
      let bound = list.map(first.bindings, fn(binding) { binding.0 })
      list.try_fold(rest, c, fn(c, alternative) {
        let names = list.map(alternative.bindings, fn(binding) { binding.0 })
        // Prefer reporting a name missing from the later alternative.
        let witness =
          result.or(
            list.find(bound, fn(name) { !list.contains(names, name) }),
            list.find(names, fn(name) { !list.contains(bound, name) }),
          )
        case witness {
          Ok(name) ->
            Error(InconsistentAlternativeBindings(context_location(c), name))
          Error(_) -> Ok(c)
        }
      })
    }
  }
}

fn unify_alternative_binding_types(
  c: Context,
  alternatives: List(TypedAlternative),
) -> Result(Context, Error) {
  case alternatives {
    [] -> Ok(c)
    [first, ..rest] ->
      list.try_fold(first.bindings, c, fn(c, binding) {
        let #(name, typ) = binding
        list.try_fold(rest, c, fn(c, alternative) {
          case list.key_find(alternative.bindings, name) {
            Ok(other) -> unify(c, typ, other)
            Error(_) -> Ok(c)
          }
        })
      })
  }
}

/// Return names bound to parts of the matched value.
/// Root variable and root as-pattern bindings are excluded.
fn pattern_bound_names(pattern: Pattern) -> List(String) {
  case pattern {
    PatternVariable(..) -> []
    PatternAssignment(pattern:, ..) -> pattern_bound_names(pattern)
    _ ->
      pattern_bindings(pattern)
      |> list.map(fn(binding) { binding.0 })
  }
}

fn pattern_bindings(pattern: Pattern) -> List(#(String, Type)) {
  case pattern {
    PatternVariable(name:, typ:, ..) -> [#(name, typ)]
    PatternAssignment(pattern:, name:, typ:, ..) -> [
      #(name, typ),
      ..pattern_bindings(pattern)
    ]
    PatternTuple(elements:, ..) -> list.flat_map(elements, pattern_bindings)
    PatternList(elements:, tail:, ..) -> {
      let bound = list.flat_map(elements, pattern_bindings)
      case tail {
        Some(tail) -> list.append(bound, pattern_bindings(tail))
        None -> bound
      }
    }
    PatternConcatenate(prefix_name:, rest_name:, ..) -> {
      let bound = case prefix_name {
        Some(Named(name)) -> [#(name, string_type)]
        _ -> []
      }
      case rest_name {
        Named(name) -> [#(name, string_type), ..bound]
        Discarded(_) -> bound
      }
    }
    PatternBitString(segments:, ..) ->
      list.flat_map(segments, fn(segment) { pattern_bindings(segment.0) })
    PatternVariant(positional_arguments:, ..) ->
      list.flat_map(positional_arguments, fn(argument) {
        case argument {
          MatchedArgument(pattern) -> pattern_bindings(pattern)
          UnmatchedArgument(_) -> []
        }
      })
    _ -> []
  }
}

fn root_pattern_bindings(
  pattern: Pattern,
  subject_type: Type,
) -> List(#(String, Type)) {
  case pattern {
    PatternVariable(name:, ..) -> [#(name, subject_type)]
    PatternAssignment(pattern:, name:, ..) -> [
      #(name, subject_type),
      ..root_pattern_bindings(pattern, subject_type)
    ]
    PatternList(elements: [], tail: Some(tail), ..) ->
      root_pattern_bindings(tail, subject_type)
    _ -> pattern_bindings(pattern)
  }
}

/// Restrict each subject domain to the variants already known to be possible.
fn narrowed_domains(
  n: LocalEnv,
  paths: List(Result(SubjectPath, Nil)),
  domains: List(match.Domain),
) -> List(match.Domain) {
  list.map2(paths, domains, fn(path, domain) {
    let known = case path {
      Ok(SubjectVar(name)) ->
        dict.get(n, name)
        |> result.map(known_variants)
        |> result.unwrap([])
      _ -> []
    }
    case known, domain {
      [], _ -> domain
      _, match.OpenDomain -> domain
      _, match.ClosedDomain(ctors) ->
        match.ClosedDomain(
          list.filter(ctors, fn(constructor) {
            list.contains(
              known,
              VariantRef(constructor.id.module, constructor.id.name),
            )
          }),
        )
    }
  })
}

fn variant_of_constructor(
  c: Context,
  module: String,
  name: String,
  ret: Type,
) -> Option(VariantRef) {
  let #(_, ret) = resolve_type(c, ret)
  case ret {
    NamedType(type_module, type_name, _) ->
      case lookup_module_type(c, type_module, type_name) {
        Ok(#(_, variants)) ->
          case list.find(variants, fn(v) { v.name == name }) {
            Ok(_) -> Some(VariantRef(module, name))
            Error(_) -> None
          }
        Error(_) -> None
      }
    _ -> None
  }
}

fn narrow_constructor_result(
  c: Context,
  module: String,
  name: String,
  typ: Type,
) -> Type {
  let result = case typ {
    FunctionType(_, return) -> return
    _ -> typ
  }
  case variant_of_constructor(c, module, name, result) {
    Some(variant) ->
      case typ {
        FunctionType(parameters, return) ->
          FunctionType(parameters, narrow_type(return, [variant]))
        _ -> narrow_type(typ, [variant])
      }
    None -> typ
  }
}

fn check_record_update_safety(
  c: Context,
  base: Expression,
  constructor_module: String,
  constructor: String,
  constructor_ret: Type,
) -> Result(Context, Error) {
  let #(_, ret) = resolve_type(c, constructor_ret)
  case ret {
    NamedType(module, name, _) ->
      case lookup_module_type(c, module, name) {
        Ok(#(_, [_])) -> Ok(c)
        Ok(#(_, variants)) -> {
          let known = expression_known_variants(base)
          let this = VariantRef(constructor_module, constructor)
          let declared =
            list.contains(
              list.map(variants, fn(v) { VariantRef(module, v.name) }),
              this,
            )
          case list.contains(known, this) || !declared {
            True -> Ok(c)
            False -> Error(UnsafeRecordUpdate(context_location(c), constructor))
          }
        }
        Error(_) -> Ok(c)
      }
    _ -> Ok(c)
  }
}

fn expression_known_variants(expression: Expression) -> List(VariantRef) {
  case expression {
    Echo(expression: Some(inner), ..) -> expression_known_variants(inner)
    _ -> known_variants(expression.typ)
  }
}

fn check_let_irrefutable(
  c: Context,
  location: Span,
  pattern: Pattern,
) -> Result(Nil, Error) {
  let domain = subject_domain(c, pattern.typ)
  let missing =
    match.witnesses([domain], [[coverage_pattern(pattern)]], [match.Wild], 1)
  case missing {
    [] -> Ok(Nil)
    _ ->
      Error(LetPatternNotExhaustive(
        span_location(c, location),
        render_missing(c, [domain], missing),
      ))
  }
}

fn narrow_after_pattern(n: LocalEnv, pattern: Pattern, value: Expression) {
  case expression_path(value) {
    Error(_) -> n
    Ok(path) -> {
      let #(facts, aliases) = pattern_facts(pattern, path)
      // Never overwrite entries the pattern itself binds.
      let bound = pattern_bound_names(pattern)
      let narrowings =
        group_facts(expand_alias_facts(facts, aliases))
        |> drop_rebound(bound)
      apply_narrowings(n, narrowings)
    }
  }
}

fn bind_pattern_variables(
  n: LocalEnv,
  pattern: Pattern,
  typ: Type,
) -> LocalEnv {
  bind_names(n, root_pattern_bindings(pattern, typ))
}

fn bind_names(n: LocalEnv, bindings: List(#(String, Type))) -> LocalEnv {
  list.fold(bindings, n, fn(n, binding) {
    let #(name, binding_type) = binding
    dict.insert(n, name, binding_type)
  })
}

type TypedAlternative {
  TypedAlternative(
    patterns: List(Pattern),
    facts: List(Fact),
    bindings: List(#(String, Type)),
  )
}

/// Exhaustiveness and redundancy checking for a whole case expression.
/// Must run after every pattern has been inferred so the subjects' types
/// are resolved and narrowed.
fn check_case_coverage(
  c: Context,
  location: Span,
  domains: List(match.Domain),
  clauses: List(#(Option(g.Expression), List(TypedAlternative))),
) -> Result(Context, Error) {
  let #(c, _red_matrix, ex_matrix) =
    list.fold(clauses, #(c, [], []), fn(acc, clause) {
      let #(c, red_matrix, ex_matrix) = acc
      let #(guard, alternatives) = clause

      // Within one clause every alternative shares the guard, so an earlier
      // alternative still makes a later overlapping one unreachable even
      // when the clause is guarded.
      let #(c, rows, _) =
        list.fold(alternatives, #(c, [], red_matrix), fn(acc, alternative) {
          let #(c, rows, red_matrix) = acc
          let row = list.map(alternative.patterns, coverage_pattern)
          let c = case match.witnesses(domains, red_matrix, row, 1) {
            [] -> {
              let assert [first_pattern, ..] = alternative.patterns
              warn(
                c,
                UnreachablePattern(span_location(c, first_pattern.location)),
              )
            }
            _ -> c
          }
          #(c, [row, ..rows], list.append(red_matrix, [row]))
        })
      let rows = list.reverse(rows)

      // A guarded clause may still fail to match, so its rows go into
      // neither matrix.
      let #(red_matrix, ex_matrix) = case guard {
        None -> #(list.append(red_matrix, rows), list.append(ex_matrix, rows))
        Some(_) -> #(red_matrix, ex_matrix)
      }
      #(c, red_matrix, ex_matrix)
    })

  let query = list.repeat(match.Wild, list.length(domains))
  case match.witnesses(domains, ex_matrix, query, missing_pattern_limit) {
    [] -> Ok(c)
    missing ->
      Error(NonExhaustiveCase(
        span_location(c, location),
        render_missing(c, domains, missing),
      ))
  }
}

const missing_pattern_limit = 8

fn subject_domains(
  c: Context,
  subjects: List(Expression),
) -> List(match.Domain) {
  list.map(subjects, fn(subject) { subject_domain(c, subject.typ) })
}

/// Build one level of the type's coverage domain.
///
/// Constructor arguments are expanded only when coverage checking needs them.
/// This avoids eagerly unfolding recursive types and prevents exponential blowup.
fn subject_domain(c: Context, typ: Type) -> match.Domain {
  let #(_, typ) = resolve_type(c, typ)
  case typ {
    NamedType(module, "List", [element]) if module == prelude ->
      match.ClosedDomain([
        match.Constructor(match.ConstructorId(prelude, "Empty"), [], 0, fn() {
          []
        }),
        match.Constructor(match.ConstructorId(prelude, "NonEmpty"), [], 2, fn() {
          [subject_domain(c, element), subject_domain(c, typ)]
        }),
      ])
    NamedType(module, name, parameters) ->
      case lookup_module_type(c, module, name) {
        Ok(#(_, [])) | Error(_) -> match.OpenDomain
        Ok(#(poly, variants)) -> {
          // Replace the declared type's own parameters with the concrete
          // arguments used here so that nested domains are precise.
          let mapping =
            list.strict_zip(poly.vars, parameters)
            |> result.unwrap([])
            |> dict.from_list
          match.ClosedDomain(
            list.map(variants, fn(variant) {
              let fields = variant.fields
              match.Constructor(
                match.ConstructorId(module, variant.name),
                list.map(fields, variant_field_label),
                list.length(fields),
                fn() {
                  list.map(fields, fn(field) {
                    subject_domain(
                      c,
                      substitute_params(field.item.typ, mapping),
                    )
                  })
                },
              )
            }),
          )
        }
      }
    TupleType(elements) ->
      match.ClosedDomain([
        match.Constructor(
          match.ConstructorId("", "#"),
          [],
          list.length(elements),
          fn() { list.map(elements, subject_domain(c, _)) },
        ),
      ])
    _ -> match.OpenDomain
  }
}

fn substitute_params(typ: Type, mapping: Dict(TypeVarId, Type)) -> Type {
  case typ {
    VariableType(ref) ->
      case dict.get(mapping, ref) {
        Ok(t) -> t
        Error(_) -> typ
      }
    NamedType(module:, name:, parameters:) ->
      NamedType(
        module:,
        name:,
        parameters: list.map(parameters, substitute_params(_, mapping)),
      )
    FunctionType(parameters, return) ->
      FunctionType(
        list.map(parameters, substitute_params(_, mapping)),
        substitute_params(return, mapping),
      )
    TupleType(elements) ->
      TupleType(list.map(elements, substitute_params(_, mapping)))
    NarrowedType(..) -> typ
  }
}

fn canonical_int(value: String) -> String {
  let value = string.replace(value, "_", "")
  let #(negative, digits) = case value {
    "-" <> rest -> #(True, rest)
    _ -> #(False, value)
  }
  let #(digits, base) = case digits {
    "0x" <> rest -> #(rest, 16)
    "0o" <> rest -> #(rest, 8)
    "0b" <> rest -> #(rest, 2)
    _ -> #(digits, 10)
  }
  case int.base_parse(digits, base) {
    Ok(parsed) ->
      case negative {
        True -> int.to_string(-parsed)
        False -> int.to_string(parsed)
      }
    Error(_) -> value
  }
}

fn canonical_float(value: String) -> String {
  let value = string.replace(value, "_", "")
  case float.parse(value) {
    Ok(parsed) -> float.to_string(parsed)
    Error(_) -> value
  }
}

fn coverage_pattern(pattern: Pattern) -> match.Pattern {
  case pattern {
    PatternInt(value:, ..) -> match.IntPattern(canonical_int(value))
    PatternFloat(value:, ..) -> match.FloatPattern(canonical_float(value))
    PatternString(value:, ..) -> match.StringPattern(value)
    PatternDiscard(..) | PatternVariable(..) -> match.Wild
    // String prefix and bit array patterns are not analysed for now.
    PatternConcatenate(..) | PatternBitString(..) -> match.OpaquePattern
    PatternAssignment(pattern:, ..) -> coverage_pattern(pattern)
    PatternTuple(elements:, ..) ->
      match.ConstructorPattern(
        match.ConstructorId("", "#"),
        list.map(elements, coverage_pattern),
      )
    PatternList(elements:, tail:, ..) ->
      case elements, tail {
        [], None ->
          match.ConstructorPattern(match.ConstructorId(prelude, "Empty"), [])
        // the tail pattern matches the whole remaining list
        [], Some(tail) -> coverage_pattern(tail)
        _, _ -> {
          let cons = match.ConstructorId(prelude, "NonEmpty")
          let last = case tail {
            Some(tail) -> coverage_pattern(tail)
            None ->
              match.ConstructorPattern(
                match.ConstructorId(prelude, "Empty"),
                [],
              )
          }
          list.fold_right(elements, last, fn(rest, element) {
            match.ConstructorPattern(cons, [coverage_pattern(element), rest])
          })
        }
      }
    PatternVariant(resolved_module:, constructor:, positional_arguments:, ..) ->
      match.ConstructorPattern(
        match.ConstructorId(resolved_module, constructor),
        list.map(positional_arguments, fn(argument) {
          case argument {
            MatchedArgument(pattern) -> coverage_pattern(pattern)
            UnmatchedArgument(_) -> match.Wild
          }
        }),
      )
  }
}

fn render_missing(
  c: Context,
  domains: List(match.Domain),
  witnesses: List(List(match.Pattern)),
) -> List(String) {
  witnesses
  |> list.map(fn(row) {
    list.zip(row, pad_domains(domains, list.length(row)))
    |> list.map(fn(column) { render_witness_value(c, Ok(column.1), column.0) })
    |> string.join(", ")
  })
  |> list.unique
}

fn pad_domains(domains: List(match.Domain), length: Int) -> List(match.Domain) {
  list.append(
    domains,
    list.repeat(match.OpenDomain, length - list.length(domains)),
  )
}

fn render_witness_value(
  c: Context,
  domain: Result(match.Domain, Nil),
  witness: match.Pattern,
) -> String {
  case witness {
    match.Wild -> "_"
    match.OpaquePattern -> "_"
    match.IntPattern(value) -> value
    match.FloatPattern(value) -> value
    match.StringPattern(value) -> "\"" <> value <> "\""
    match.ConstructorPattern(id, arguments) ->
      render_witness_constructor(c, domain, id, arguments)
  }
}

fn render_witness_constructor(
  c: Context,
  domain: Result(match.Domain, Nil),
  id: match.ConstructorId,
  arguments: List(match.Pattern),
) -> String {
  let constructor_info = case domain {
    Ok(match.ClosedDomain(constructors)) ->
      list.find(constructors, fn(candidate) { candidate.id == id })
    _ -> Error(Nil)
  }
  let argument_domains = case constructor_info {
    Ok(constructor) -> constructor.arguments()
    Error(_) -> list.repeat(match.OpenDomain, list.length(arguments))
  }
  let no_labels = list.repeat(None, list.length(arguments))
  case id.name {
    "#" ->
      string.concat([
        "#(",
        render_witness_arguments(c, arguments, argument_domains, no_labels),
        ")",
      ])
    "Empty" if id.module == prelude -> "[]"
    "NonEmpty" if id.module == prelude -> {
      let #(element_domain, list_domain) = case argument_domains {
        [element, list, ..] -> #(Ok(element), Ok(list))
        _ -> #(Error(Nil), Error(Nil))
      }
      string.concat([
        "[",
        render_list_spine(c, element_domain, list_domain, arguments),
        "]",
      ])
    }
    _ -> {
      let name = constructor_prefix(c, id) <> id.name
      case arguments {
        [] -> name
        _ -> {
          let labels = case constructor_info {
            Ok(constructor) -> constructor.labels
            Error(_) -> no_labels
          }
          string.concat([
            name,
            "(",
            render_witness_arguments(c, arguments, argument_domains, labels),
            ")",
          ])
        }
      }
    }
  }
}

fn render_witness_arguments(
  c: Context,
  arguments: List(match.Pattern),
  domains: List(match.Domain),
  labels: List(Option(String)),
) -> String {
  list.map2(arguments, list.zip(domains, labels), fn(argument, metadata) {
    let #(domain, label) = metadata
    case label {
      Some(label) ->
        label
        <> ":"
        <> case argument {
          match.Wild -> ""
          _ -> " " <> render_witness_value(c, Ok(domain), argument)
        }
      None -> render_witness_value(c, Ok(domain), argument)
    }
  })
  |> string.join(", ")
}

fn render_list_spine(
  c: Context,
  element_domain: Result(match.Domain, Nil),
  list_domain: Result(match.Domain, Nil),
  arguments: List(match.Pattern),
) -> String {
  case arguments {
    [head, tail] -> {
      let head_string = render_witness_value(c, element_domain, head)
      case tail {
        match.ConstructorPattern(id, inner_arguments)
          if id == match.ConstructorId(prelude, "NonEmpty")
        -> {
          head_string
          <> ", "
          <> render_list_spine(c, element_domain, list_domain, inner_arguments)
        }
        match.Wild -> head_string <> ", .."
        other ->
          head_string <> ", .." <> render_witness_value(c, list_domain, other)
      }
    }
    _ ->
      string.join(
        list.map(arguments, fn(argument) {
          render_witness_value(c, element_domain, argument)
        }),
        ", ",
      )
  }
}

fn constructor_prefix(c: Context, id: match.ConstructorId) -> String {
  let bare =
    id.module == ""
    || id.module == c.module.name
    || id.module == prelude
    || dict.get(c.value_origin, QualifiedName(c.module.name, id.name))
    == Ok(Imported)
  case bare {
    True -> ""
    False -> module_display_name(c, id.module) <> "."
  }
}

fn module_display_name(c: Context, module: String) -> String {
  case list.key_find(dict.to_list(c.module_aliases), module) {
    Ok(alias) -> alias
    Error(_) -> module
  }
}

fn resolve_constructor(
  c: Context,
  module: Option(String),
  constructor: String,
) {
  use constructor <- result.try(resolve_constructor_name(c, module, constructor))
  case constructor {
    ModuleFunction(module:, name:, typ:, labels:) ->
      Ok(#(module, name, typ, labels))
    ModuleConstant(..) ->
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

          use #(c, kind) <- result.try(case kind {
            g.Let -> {
              check_let_irrefutable(c, location, pattern)
              |> result.map(fn(_) { #(c, Let) })
            }
            g.LetAssert(None) -> Ok(#(c, LetAssert(None)))
            g.LetAssert(Some(message)) -> {
              use #(c, message) <- result.try(infer_expression(c, n, message))
              use c <- result.try(unify(c, message.typ, string_type))
              Ok(#(c, LetAssert(Some(message))))
            }
          })

          let n = bind_pattern_variables(n, pattern, value.typ)
          let n = narrow_after_pattern(n, pattern, value)

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
              // the message should be a string
              use #(c, msg) <- result.try(infer_expression(c, n, msg))
              use c <- result.try(unify(c, msg.typ, string_type))
              Ok(#(c, Some(msg)))
            }
            None -> Ok(#(c, None))
          })

          // `assert` always evaluates to Nil, regardless of the subject's type
          let statement = Assert(nil_type, location, expression, message)

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
              g.FnParameter(g.Named(use_parameter_name(i)), None)
            })
          // one assignment per pattern, binding it to the parameter, in source
          // order, followed by the remainder of the current body.
          let assignments =
            list.index_map(patterns, fn(pat, i) {
              let param = g.Variable(span, use_parameter_name(i))
              g.Assignment(span, g.Let, pat.pattern, pat.annotation, param)
            })
          let body = list.append(assignments, xs)
          // if there are no statements after the use, an implicit `todo` is appended
          let #(c, body) = case xs {
            [] -> {
              let loc = Location(c.module.name, c.current_definition, span)
              let c = warn(c, ImplicitTodo(loc, IncompleteUse))
              #(c, list.append(body, [g.Expression(g.Todo(span, None))]))
            }
            _ -> #(c, body)
          }
          let callback = g.Fn(span, params, None, body)
          let inferred = infer_call(c, n, span, fun, args, Some(callback))
          use #(c, call) <- result.map(inferred)
          // now re-sugar into a use statement: the callback is the argument we
          // appended, so it is last in caller order
          let assert Ok(#(arguments, callback)) = split_last(call.arguments)
          let assert Fn(body:, ..) = callback.item
          let #(patterns, body) = list.split(body, list.length(patterns))
          let patterns =
            list.map(patterns, fn(stmt) {
              let assert Assignment(pattern:, annotation:, ..) = stmt
              UsePattern(pattern, annotation)
            })
          // TODO is "body" the correct thing to return here?
          // It has let statements and todo added which we might not want here.
          let statement =
            Use(
              call.typ,
              call.location,
              patterns,
              call.function,
              arguments,
              body,
            )
          #(c, [statement])
        }
      }
  }
}

fn infer_body_or_todo(
  c: Context,
  n: LocalEnv,
  body: List(g.Statement),
  kind: TodoKind,
) -> Result(#(Context, List(Statement)), Error) {
  case body {
    [] -> {
      let #(c, statement) = implicit_todo(c, context_location(c), kind)
      Ok(#(c, [statement]))
    }
    _ -> infer_body(c, n, body)
  }
}

fn body_type(statements: List(Statement)) -> Option(Type) {
  case list.last(statements) {
    Ok(statement) -> Some(statement.typ)
    Error(_) -> None
  }
}

fn unify_body_return(
  c: Context,
  return_type: Type,
  body: List(Statement),
) -> Result(Context, Error) {
  case body_type(body) {
    Some(typ) -> unify(c, return_type, typ)
    None -> Ok(c)
  }
}

type MatchError {
  UnknownLabelGiven(label: String)
  LabelGivenTwice(label: String)
  ArityMismatch
}

/// Look up each arg's associated param, returning them as matching tuples.
fn resolve_labelled(
  args: List(#(String, a)),
  params: List(#(String, b)),
) -> Result(List(#(b, a)), MatchError) {
  let initial: List(#(b, a)) = []
  use resolved <- result.try(
    list.try_fold(args, initial, fn(resolved, arg) {
      let #(label, value) = arg
      case list.find(params, fn(p) { p.0 == label }) {
        Ok(#(_, associated)) ->
          case list.any(resolved, fn(r) { r.0 == associated }) {
            True -> Error(LabelGivenTwice(label))
            False -> Ok([#(associated, value), ..resolved])
          }
        Error(_) -> Error(UnknownLabelGiven(label))
      }
    }),
  )
  Ok(list.reverse(resolved))
}

/// Check that all positional arguments come before all labelled arguments.
fn check_arg_order(
  c: Context,
  args: List(g.Field(a)),
  location: fn(a) -> Span,
) -> Result(Nil, Error) {
  list.try_fold(args, False, fn(seen_labelled, arg) {
    case arg, seen_labelled {
      g.UnlabelledField(item:), True ->
        Error(UnexpectedPositionalArgument(span_location(c, location(item))))
      g.UnlabelledField(..), False -> Ok(False)
      _, _ -> Ok(True)
    }
  })
  |> result.replace(Nil)
}

/// Convert a source level field into a typed field of the given constructor.
fn convert_field(
  field: g.Field(a),
  variable: fn(Span, String) -> a,
) -> Field(a) {
  case field {
    g.LabelledField(label:, label_location:, item:) ->
      LabelledField(item, label, label_location)
    g.ShorthandField(label:, location:) ->
      ShorthandField(variable(location, label), label, location)
    g.UnlabelledField(item:) -> UnlabelledField(item)
  }
}

/// Split a list of fields into the unlabelled and labelled items.
fn split_positional_labelled(
  args: List(Field(a)),
) -> #(List(a), List(#(String, a))) {
  let #(positional, labelled) =
    list.fold(args, #([], []), fn(acc, arg) {
      let #(positional, labelled) = acc
      case field_label(arg) {
        Some(label) -> #(positional, [#(label, arg.item), ..labelled])
        None -> #([arg.item, ..positional], labelled)
      }
    })
  #(list.reverse(positional), list.reverse(labelled))
}

fn param_labels(params: List(Option(String))) -> List(#(String, String)) {
  list.filter_map(params, fn(param) {
    case param {
      Some(label) -> Ok(#(label, label))
      None -> Error(Nil)
    }
  })
}

fn match_params(
  params: List(Option(String)),
  positional: List(a),
  resolved: List(#(String, a)),
) -> #(List(Option(a)), List(a), Bool) {
  let #(#(leftover, unmatched), matched) =
    list.map_fold(params, #(positional, False), fn(state, param) {
      let #(remaining, unmatched) = state
      let by_label = case param {
        Some(label) -> list.key_find(resolved, label)
        None -> Error(Nil)
      }
      case by_label {
        Ok(value) -> #(state, Some(value))
        Error(_) ->
          case remaining {
            [value, ..rest] -> #(#(rest, unmatched), Some(value))
            [] -> #(#(remaining, True), None)
          }
      }
    })
  #(matched, leftover, unmatched)
}

fn match_error(
  c: Context,
  params: List(Option(String)),
  args: List(b),
  err: MatchError,
) -> Error {
  case err {
    UnknownLabelGiven(label) -> LabelNotFound(context_location(c), label)
    LabelGivenTwice(label) -> DuplicateLabel(context_location(c), label)
    ArityMismatch ->
      WrongArity(context_location(c), list.length(params), list.length(args))
  }
}

fn resolve_field_labels(
  positional: List(a),
  labelled: List(#(String, a)),
  params: List(Option(String)),
) -> Result(#(List(Option(a)), List(a), Bool), MatchError) {
  use resolved <- result.try(resolve_labelled(labelled, param_labels(params)))
  Ok(match_params(params, positional, resolved))
}

/// Match a list of fields against a list of parameters.
/// Returns the items in parameter order.
fn match_fields(
  args: List(Field(a)),
  params: List(Option(String)),
) -> Result(List(a), MatchError) {
  let #(positional, labelled) = split_positional_labelled(args)
  use matched <- result.try(resolve_field_labels(positional, labelled, params))
  case matched {
    #(matched, [], False) ->
      Ok(list.filter_map(matched, option.to_result(_, Nil)))
    _ -> Error(ArityMismatch)
  }
}

fn match_pattern_args(
  c: Context,
  args: List(Field(a)),
  params: List(Option(String)),
  with_spread: Bool,
) -> Result(#(Context, List(Option(a))), Error) {
  let #(positional, labelled) = split_positional_labelled(args)
  use #(matched, leftover, unmatched) <- result.try(
    resolve_field_labels(positional, labelled, params)
    |> result.map_error(match_error(c, params, args, _)),
  )

  case leftover, unmatched, with_spread {
    [_, ..], _, _ | [], True, False ->
      Error(match_error(c, params, args, ArityMismatch))
    [], False, True ->
      Ok(#(
        warn(c, UnnecessarySpread(context_location(c), list.length(params))),
        matched,
      ))
    [], _, _ -> Ok(#(c, matched))
  }
}

fn field_access_module_fallback(
  c: Context,
  container: g.Expression,
  location: Span,
  label: String,
  original_error: Error,
) -> Result(#(Context, Expression), Error) {
  case container {
    g.Variable(_, module) -> {
      case resolve_aliased_module_value(c, QualifiedName(module, label)) {
        Ok(ModuleFunction(module, name, poly, labels)) -> {
          let #(c, typ) = instantiate(c, poly)
          let typ = narrow_constructor_result(c, module, name, typ)
          Ok(#(c, Function(typ, location, module, name, labels)))
        }
        Ok(ModuleConstant(module, name, poly)) -> {
          let #(c, typ) = instantiate(c, poly)
          Ok(#(c, Constant(typ, location, module, name)))
        }
        Error(e) -> Error(e)
      }
    }
    _ -> Error(original_error)
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
        Ok(ResolvedModuleValue(module_value)) ->
          case module_value {
            ModuleFunction(module, name, typ, labels) -> {
              let #(c, typ) = instantiate(c, typ)
              // Record the exact variant produced by a constructor.
              let typ = narrow_constructor_result(c, module, name, typ)
              Ok(#(c, Function(typ, location, module, name, labels)))
            }
            ModuleConstant(module, name, typ) -> {
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
      use #(c, statements) <- result.try(infer_body_or_todo(
        c,
        n,
        statements,
        EmptyBlock,
      ))
      let assert Some(typ) = body_type(statements)
      Ok(#(c, Block(typ, location, statements)))
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

      // Updating a record is only safe when it cannot be some other variant
      use c <- result.try(check_record_update_safety(
        c,
        base_expr,
        res_module,
        constructor,
        constructor_ret,
      ))

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

      // Collect the labelled fields of the constructor
      let labelled_fields =
        list.zip(labels, constructor_args)
        |> list.filter_map(fn(pair) {
          case pair.0 {
            Some(label) -> Ok(#(label, pair.1))
            None -> Error(Nil)
          }
        })

      // The update syntax requires at least one labelled field
      use c <- result.try(case labelled_fields {
        [] -> Error(RecordUpdateOnUnlabelledConstructor(context_location(c)))
        _ -> Ok(c)
      })

      // Match each given field to a parameter
      let given =
        list.map(updated_fields, fn(field) {
          let assert Some(value) = field.item
          #(field.label, value)
        })

      // Updating no fields or all fields is unnecessary so add a warning
      let given_count = list.length(given)
      let total_count = list.length(labelled_fields)
      let c = case given_count {
        0 -> warn(c, UnnecessaryRecordUpdate(context_location(c), 0))
        _ if given_count == total_count ->
          warn(c, UnnecessaryRecordUpdate(context_location(c), given_count))
        _ -> c
      }

      use #(matched, _, _) <- result.try(
        resolve_field_labels([], given, labels)
        |> result.map_error(match_error(c, labels, given, _)),
      )

      // Check the type of each updated value against its parameter
      use c <- result.try(
        list.try_fold(given, c, fn(c, entry) {
          let #(label, value) = entry
          let assert Ok(expected) = list.key_find(labelled_fields, label)
          unify(c, value.typ, expected)
        }),
      )

      let positional_fields =
        list.map2(matched, constructor_args, fn(m, expected) {
          case m {
            Some(value) -> UpdatedField(value)
            None -> UnchangedField(expected)
          }
        })

      let #(_, base) = resolve_type(c, constructor_ret)
      let typ = NarrowedType(base, [VariantRef(res_module, constructor)])

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

      Ok(#(c, record_update))
    }
    g.FieldAccess(location:, container:, label:) -> {
      // try to infer the value, otherwise it might be a module access
      case infer_expression(c, n, container) {
        Error(e) ->
          field_access_module_fallback(c, container, location, label, e)
        Ok(#(c, value)) -> {
          let field_access = {
            // field access must be on a named type
            let #(c, value_typ_resolved) = resolve_type(c, value.typ)
            let value_typ = case value_typ_resolved {
              NamedType(module, type_name, _) -> Ok(#(type_name, module))
              _ -> Error(InvalidFieldAccess(context_location(c)))
            }
            use #(type_name, module) <- result.try(value_typ)

            // find the custom type definition
            use #(typ, all_variants) <- result.try(lookup_module_type(
              c,
              module,
              type_name,
            ))

            let narrowed = known_variants(value.typ)
            let variants = case narrowed {
              [] -> all_variants
              refs ->
                list.filter(all_variants, fn(variant) {
                  list.contains(refs, VariantRef(module, variant.name))
                })
            }

            // find the matching field and index on the first variant
            let first_variant = case variants {
              [variant, ..] -> Ok(variant)
              [] -> Error(InvalidFieldAccess(context_location(c)))
            }
            use first_variant <- result.try(first_variant)

            let field =
              first_variant.fields
              |> list.index_map(fn(x, i) { #(x, i) })
              |> list.find(fn(x) { variant_field_label(x.0) == Some(label) })
              |> result.replace_error(FieldNotFound(context_location(c), label))
            use #(field, index) <- result.try(field)

            // every other variant must have the same field at the same index
            use _ <- result.try(
              list.try_each(variants, fn(variant) {
                let matches = case list.drop(variant.fields, index) {
                  [other_field, ..] ->
                    variant_field_label(other_field) == Some(label)
                    && other_field.item.typ == field.item.typ
                  [] -> False
                }
                case matches {
                  True -> Ok(Nil)
                  False ->
                    Error(InconsistentFieldAccess(context_location(c), label))
                }
              }),
            )

            // create a getter function type
            let getter = FunctionType([typ.typ], field.item.typ)
            let getter = Poly(typ.vars, getter)
            let #(c, getter) = instantiate(c, getter)

            // unify the getter as if we're calling it on the value
            let #(c, typ) = new_type_var_ref(c)
            use c <- result.map(unify(c, getter, FunctionType([value.typ], typ)))
            #(c, FieldAccess(typ, location, value, label, index))
          }
          case field_access {
            Ok(access) -> Ok(access)
            Error(e) ->
              case
                field_access_module_fallback(c, container, location, label, e)
              {
                Ok(access) -> Ok(access)
                Error(_) -> Error(e)
              }
          }
        }
      }
    }
    g.Call(span, function, args) -> {
      use #(c, call) <- result.map(infer_call(c, n, span, function, args, None))
      let call =
        Call(
          call.typ,
          call.location,
          call.function,
          call.arguments,
          call.positional_arguments,
        )
      #(c, call)
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
      let subject_paths = list.map(subjects, expression_path)

      // all of the branches should unify with the case type
      let #(c, typ) = new_type_var_ref(c)

      use #(c, alternatives, clauses) <- result.try(
        list.try_fold(clauses, #(c, [], []), fn(acc, clause) {
          let #(c, alternatives, clauses) = acc

          // patterns is a List(List(Pattern))
          // the inner list has a pattern to match each subject
          // the outer list has alternatives that have the same body
          // each alternative starts with the outer environment
          use #(c, typed_alts) <- result.try(
            list.try_fold(clause.patterns, #(c, []), fn(acc, pattern) {
              let #(c, typed) = acc

              // each pattern has a corresponding subject
              use sub_patterns <- result.try(
                list.strict_zip(subjects, pattern)
                |> result.map_error(fn(_) {
                  WrongArity(
                    context_location(c),
                    list.length(subjects),
                    list.length(pattern),
                  )
                }),
              )

              use #(c, _alternative_n, pairs) <- result.map(
                list.try_fold(sub_patterns, #(c, n, []), fn(acc, sub_pat) {
                  let #(c, n, pairs) = acc
                  let #(sub, pat) = sub_pat
                  use #(c, n, pat) <- result.try(infer_pattern(c, n, pat))

                  use c <- result.map(unify(c, pat.typ, sub.typ))

                  let n = bind_pattern_variables(n, pat, sub.typ)
                  #(c, n, [#(pat, sub.typ), ..pairs])
                }),
              )
              let pairs = list.reverse(pairs)
              let patterns = list.map(pairs, fn(pair) { pair.0 })

              // Collect what this alternative teaches about the subjects and aliases.
              let facts =
                list.strict_zip(patterns, subject_paths)
                |> result.unwrap([])
                |> list.flat_map(fn(column) {
                  let #(typed_pattern, path) = column
                  case path {
                    Error(_) -> []
                    Ok(path) -> {
                      let #(facts, aliases) = pattern_facts(typed_pattern, path)
                      expand_alias_facts(facts, aliases)
                    }
                  }
                })

              let bindings =
                list.flat_map(pairs, fn(pair) {
                  let #(pat, subject_type) = pair
                  root_pattern_bindings(pat, subject_type)
                })

              #(c, [TypedAlternative(patterns:, facts:, bindings:), ..typed])
            }),
          )
          let typed_alts = list.reverse(typed_alts)

          use c <- result.try(check_alternative_bindings(c, typed_alts))

          use c <- result.try(unify_alternative_binding_types(c, typed_alts))
          let n =
            bind_names(n, case typed_alts {
              [first, ..] -> first.bindings
              [] -> []
            })

          let narrowings =
            merge_alternative_facts(list.map(typed_alts, fn(a) { a.facts }))
          let rebound =
            typed_alts
            |> list.flat_map(fn(a) {
              list.flat_map(a.patterns, pattern_bound_names)
            })
            |> list.unique
          let n = apply_narrowings(n, drop_rebound(narrowings, rebound))

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

          let patterns = list.map(typed_alts, fn(a) { a.patterns })
          let santa = Clause(patterns:, guard:, body:)
          let alternatives = [#(clause.guard, typed_alts), ..alternatives]
          #(c, alternatives, [santa, ..clauses])
        }),
      )
      let alternatives = list.reverse(alternatives)
      let clauses = list.reverse(clauses)

      // coverage runs after every pattern has been inferred so the subject
      // types are fully resolved
      let domains =
        narrowed_domains(n, subject_paths, subject_domains(c, subjects))
      use c <- result.try(check_case_coverage(
        c,
        location,
        domains,
        alternatives,
      ))
      Ok(#(c, Case(typ:, location:, subjects:, clauses:)))
    }
    g.BinaryOperator(span, g.Pipe, left, right) -> {
      // first desugar the pipe
      let #(idx, label, span, fun, args, is_echo) = case right {
        g.Call(span, fun, args) -> {
          let args = [g.UnlabelledField(left), ..args]
          #(0, None, span, fun, args, False)
        }
        g.FnCapture(span, label, fun, before, after) -> {
          let arg = case label {
            Some(label) -> g.LabelledField(label, span, left)
            None -> g.UnlabelledField(left)
          }
          let args = list.flatten([before, [arg], after])
          #(list.length(before), label, span, fun, args, False)
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
          #(0, None, span, echo_, [g.UnlabelledField(left)], True)
        }
        _ -> #(0, None, span, right, [g.UnlabelledField(left)], False)
      }
      // then infer and re-sugar the result
      use #(c, desugared) <- result.map(infer_call(c, n, span, fun, args, None))
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
      let right = case is_echo, function {
        True, Fn(_, _, [_], _, [Expression(expression: Echo(message:, ..), ..)])
        -> PipeIntoEcho(message)
        _, _ -> PipeIntoFnCapture(label, function, before, after)
      }
      #(c, Pipe(typ:, location:, left:, right:))
    }
    g.BinaryOperator(location:, name:, left:, right:) -> {
      let name = map_binop(name)
      let #(c, fun_typ) = case name {
        // Boolean logic
        And | Or -> {
          #(c, FunctionType([bool_type, bool_type], bool_type))
        }

        // Equality
        Eq | NotEq -> {
          let #(c, a) = new_type_var_ref(c)
          #(c, FunctionType([a, a], bool_type))
        }

        // Order comparison
        LtInt | LtEqInt | GtEqInt | GtInt -> {
          #(c, FunctionType([int_type, int_type], bool_type))
        }

        LtFloat | LtEqFloat | GtEqFloat | GtFloat -> {
          #(c, FunctionType([float_type, float_type], bool_type))
        }

        // Maths
        AddInt | SubInt | MultInt | DivInt | RemainderInt -> {
          #(c, FunctionType([int_type, int_type], int_type))
        }

        AddFloat | SubFloat | MultFloat | DivFloat -> {
          #(c, FunctionType([float_type, float_type], float_type))
        }

        // Strings
        Concatenate -> {
          #(c, FunctionType([string_type, string_type], string_type))
        }
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

/// Infer a function call with the given arguments.
/// `callback` is the implicit trailing argument of a `use` statement.
fn infer_call(
  c: Context,
  n: LocalEnv,
  span: Span,
  function: g.Expression,
  arguments: List(g.Field(g.Expression)),
  callback: Option(g.Expression),
) -> Result(#(Context, InferredCall), Error) {
  use _ <- result.try(check_arg_order(c, arguments, fn(e) { e.location }))
  let arguments = case callback {
    Some(callback) -> list.append(arguments, [g.UnlabelledField(callback)])
    None -> arguments
  }

  // infer the type of the function
  use #(c, fun) <- result.try(infer_expression(c, n, function))

  // get labels from function type
  let labels = case fun {
    Function(labels:, ..) -> labels
    _ -> list.map(arguments, fn(_) { None })
  }

  // convert glance fields to typed fields (original order)
  let args = list.map(arguments, convert_field(_, g.Variable))

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
  use positional_fields <- result.try(
    match_fields(arguments, labels)
    |> result.map_error(match_error(c, labels, arguments, _)),
  )

  let arg_types = list.map(positional_fields, fn(expr) { expr.typ })

  let #(_, resolved_fun) = resolve_type(c, fun.typ)
  let variant_refs = case resolved_fun {
    FunctionType(_, ret) -> known_variants(ret)
    _ -> []
  }

  // unify the function type with the types of args
  let #(c, typ) = new_type_var_ref(c)
  use c <- result.map(unify(c, fun.typ, FunctionType(arg_types, typ)))
  let #(c, typ) = resolve_type(c, typ)
  let typ = narrow_type(typ, variant_refs)
  #(c, InferredCall(typ, span, fun, arguments, positional_fields))
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
  use #(c, body) <- result.try(infer_body_or_todo(c, n, body, EmptyFunction))

  // unify the return type with the last statement
  use c <- result.map(unify_body_return(c, return_type, body))

  let typ = case return_annotation, body_type(body) {
    None, Some(tail) ->
      FunctionType(list.map(parameters, fn(p) { p.typ }), tail)
    _, _ -> typ
  }

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
    NarrowedType(typ, _) -> find_tvs(c, typ)
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
    NarrowedType(typ, variants) ->
      NarrowedType(do_instantiate(c, n, typ), variants)
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
    VariableType(_) -> {
      let #(c, resolved) = resolve_type(c, in)
      case resolved {
        VariableType(ref) -> #(c, id == ref)
        _ -> occurs(c, id, resolved)
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
    NarrowedType(typ, _) -> occurs(c, id, typ)
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
    NarrowedType(typ, _) -> resolve_type(c, typ)
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
    parameters: list.map(function.parameters, fn(param) {
      let typ = substitute_type(c, rename, param.typ)
      let annotation =
        option.map(param.annotation, substitute_annotation(c, rename, _))
      FunctionParameter(..param, typ:, annotation:)
    }),
    body: list.map(function.body, substitute_statement(c, rename, _)),
    return: option.map(function.return, substitute_annotation(c, rename, _)),
  )
}

fn substitute_statement(
  c: Context,
  rename: Dict(TypeVarId, TypeVarId),
  statement: Statement,
) -> Statement {
  case statement {
    Use(typ:, location:, patterns:, function:, arguments:, body:) ->
      Use(
        typ: substitute_type(c, rename, typ),
        location:,
        patterns: list.map(patterns, substitute_use_pattern(c, rename, _)),
        function: substitute_expression(c, rename, function),
        arguments: list.map(
          arguments,
          map_field(_, substitute_expression(c, rename, _)),
        ),
        body: list.map(body, substitute_statement(c, rename, _)),
      )
    Assignment(typ:, location:, kind:, pattern:, annotation:, value:) ->
      Assignment(
        typ: substitute_type(c, rename, typ),
        location:,
        kind: case kind {
          LetAssert(Some(message)) ->
            LetAssert(Some(substitute_expression(c, rename, message)))
          Let | LetAssert(None) -> kind
        },
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
        parameters: list.map(parameters, fn(param) {
          let typ = substitute_type(c, rename, param.typ)
          let annotation =
            option.map(param.annotation, substitute_annotation(c, rename, _))
          FnParameter(..param, typ:, annotation:)
        }),
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
    FieldAccess(typ:, location:, container:, label:, index:) ->
      FieldAccess(
        typ: substitute_type(c, rename, typ),
        location:,
        container: substitute_expression(c, rename, container),
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
            list.map(options, fn(option) {
              case option {
                SizeValueOption(size) ->
                  SizeValueOption(substitute_expression(c, rename, size))
                _ -> option
              }
            }),
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
          #(substitute_pattern(c, rename, pattern), options)
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
    NarrowedType(typ, variants) ->
      NarrowedType(substitute_type(c, rename, typ), variants)
    VariableType(ref) -> {
      case get_type_var(c, ref) {
        Bound(x) -> substitute_type(c, rename, x)
        Unbound ->
          case dict.get(rename, ref) {
            Ok(new_ref) -> VariableType(new_ref)
            Error(Nil) -> {
              // offset the id so it can't clash with the generalised ids
              VariableType(TypeVarId(ref.id + dict.size(rename)))
            }
          }
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

fn split_last(items: List(a)) -> Result(#(List(a), a), Nil) {
  case list.reverse(items) {
    [last, ..rest] -> Ok(#(list.reverse(rest), last))
    [] -> Error(Nil)
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
    LabelledField(label:, ..) -> Some(label)
    ShorthandField(label:, ..) -> Some(label)
    UnlabelledField(..) -> None
  }
}

fn map_definition(def: Definition(a), func: fn(a) -> b) -> Definition(b) {
  Definition(..def, definition: func(def.definition))
}

/// Claims a name in this module's own value namespace
fn claim_value_name(
  c: Context,
  name: String,
  location: Location,
  to_error: fn(Location, String) -> Error,
) -> Result(Context, Error) {
  let key = QualifiedName(c.module.name, name)
  case dict.get(c.value_origin, key) {
    Ok(Local) -> Error(to_error(location, name))
    Ok(Imported) -> {
      let c = warn(c, ShadowsImport(location, name))
      Ok(Context(..c, value_origin: dict.insert(c.value_origin, key, Local)))
    }
    Error(Nil) ->
      Ok(Context(..c, value_origin: dict.insert(c.value_origin, key, Local)))
  }
}

/// Claims a name in this module's own type namespace
fn claim_type_name(
  c: Context,
  name: String,
  location: Location,
) -> Result(Context, Error) {
  let key = QualifiedName(c.module.name, name)
  case dict.get(c.type_origin, key) {
    Ok(Local) -> Error(DuplicateType(location, name))
    Ok(Imported) -> {
      let c = warn(c, ShadowsImport(location, name))
      Ok(Context(..c, type_origin: dict.insert(c.type_origin, key, Local)))
    }
    Error(Nil) ->
      Ok(Context(..c, type_origin: dict.insert(c.type_origin, key, Local)))
  }
}

fn context_location(c: Context) {
  span_location(c, c.current_span)
}

fn span_location(c: Context, span: Span) -> Location {
  Location(c.module.name, c.current_definition, span)
}

fn warn(c: Context, warning: Warning) -> Context {
  update_module(c, fn(mod) {
    Module(..mod, warnings: [warning, ..mod.warnings])
  })
}

fn implicit_todo(
  c: Context,
  location: Location,
  kind: TodoKind,
) -> #(Context, Statement) {
  let #(c, typ) = new_type_var_ref(c)
  let todo_exp = Todo(typ, location.span, None)
  let c = warn(c, ImplicitTodo(location, kind))
  #(c, Expression(typ, location.span, todo_exp))
}
