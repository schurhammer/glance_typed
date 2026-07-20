import cymbal
import glance_typed as typed

import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/string

pub fn module_to_string(module: typed.Module) -> String {
  module_to_yaml(module)
  |> cymbal.encode
}

fn module_to_yaml(module: typed.Module) -> cymbal.Yaml {
  yaml_block([
    #("name", cymbal.string(module.name)),
    #("imports", yaml_list(module.imports, import_to_yaml)),
    #("type_aliases", yaml_list(module.type_aliases, type_alias_to_yaml)),
    #("types", yaml_list(module.custom_types, custom_type_to_yaml)),
    #("constants", yaml_list(module.constants, constant_to_yaml)),
    #("functions", yaml_list(module.functions, function_to_yaml)),
  ])
}

fn yaml_list(items: List(a), convert: fn(a) -> cymbal.Yaml) -> cymbal.Yaml {
  cymbal.array(list.map(items, convert))
}

fn yaml_is_empty(value: cymbal.Yaml) -> Bool {
  value == cymbal.array([])
  || value == cymbal.block([])
  || value == cymbal.string("")
}

fn yaml_block(entries: List(#(String, cymbal.Yaml))) -> cymbal.Yaml {
  entries
  |> list.filter(fn(entry) { !yaml_is_empty(entry.1) })
  |> cymbal.block()
}

fn import_to_yaml(definition: typed.Definition(typed.Import)) -> cymbal.Yaml {
  let import_ = definition.definition
  yaml_block(
    [
      Some(#("module", cymbal.string(import_.module))),
      option.map(import_.alias, fn(alias) {
        #("alias", assignment_name_to_yaml(alias))
      }),
      Some(#("attributes", yaml_list(definition.attributes, attribute_to_yaml))),
      Some(#(
        "unqualified_types",
        yaml_list(import_.unqualified_types, unqualified_import_to_yaml),
      )),
      Some(#(
        "unqualified_values",
        yaml_list(import_.unqualified_values, unqualified_import_to_yaml),
      )),
    ]
    |> option.values,
  )
}

fn type_alias_to_yaml(
  definition: typed.Definition(typed.TypeAlias),
) -> cymbal.Yaml {
  let alias = definition.definition
  yaml_block([
    #("name", cymbal.string(alias.name)),
    #("type", polytype_to_yaml(alias.typ)),
    #("publicity", publicity_to_yaml(alias.publicity)),
    #("attributes", yaml_list(definition.attributes, attribute_to_yaml)),
    #("parameters", yaml_list(alias.parameters, cymbal.string)),
    #("aliased", annotation_to_yaml(alias.aliased)),
  ])
}

fn custom_type_to_yaml(
  definition: typed.Definition(typed.CustomType),
) -> cymbal.Yaml {
  let custom_type = definition.definition
  yaml_block([
    #("name", cymbal.string(custom_type.name)),
    #("type", polytype_to_yaml(custom_type.typ)),
    #("publicity", publicity_to_yaml(custom_type.publicity)),
    #("opaque", cymbal.bool(custom_type.opaque_)),
    #("attributes", yaml_list(definition.attributes, attribute_to_yaml)),
    #("parameters", yaml_list(custom_type.parameters, cymbal.string)),
    #("variants", yaml_list(custom_type.variants, variant_to_yaml)),
  ])
}

fn variant_to_yaml(variant: typed.Variant) -> cymbal.Yaml {
  yaml_block([
    #("name", cymbal.string(variant.name)),
    #("type", polytype_to_yaml(variant.typ)),
    #(
      "fields",
      yaml_list(variant.fields, fn(field) {
        let #(label, item) = case field {
          typed.LabelledVariantField(item, label) -> #(Some(label), item)
          typed.UnlabelledVariantField(item) -> #(None, item)
        }
        yaml_block(
          [
            option.map(label, fn(l) { #("label", cymbal.string(l)) }),
            Some(#("annotation", annotation_to_yaml(item))),
          ]
          |> option.values,
        )
      }),
    ),
  ])
}

fn constant_to_yaml(
  definition: typed.Definition(typed.ConstantDefinition),
) -> cymbal.Yaml {
  let constant = definition.definition
  yaml_block(
    [
      Some(#("name", cymbal.string(constant.name))),
      Some(#("type", polytype_to_yaml(constant.typ))),
      option.map(constant.annotation, fn(annotation) {
        #("annotation", annotation_to_yaml(annotation))
      }),
      Some(#("publicity", publicity_to_yaml(constant.publicity))),
      Some(#("attributes", yaml_list(definition.attributes, attribute_to_yaml))),
      Some(#("value", expression_to_yaml(constant.value))),
    ]
    |> option.values,
  )
}

fn function_to_yaml(
  definition: typed.Definition(typed.FunctionDefinition),
) -> cymbal.Yaml {
  let function = definition.definition
  yaml_block(
    [
      Some(#("name", cymbal.string(function.name))),
      Some(#("type", polytype_to_yaml(function.typ))),
      Some(#("publicity", publicity_to_yaml(function.publicity))),
      Some(#("attributes", yaml_list(definition.attributes, attribute_to_yaml))),
      Some(#(
        "parameters",
        yaml_list(function.parameters, function_parameter_to_yaml),
      )),
      option.map(function.return, fn(return) {
        #("return", annotation_to_yaml(return))
      }),
      Some(#("body", yaml_list(function.body, statement_to_yaml))),
    ]
    |> option.values,
  )
}

fn typed_node(
  kind: String,
  typ: typed.Type,
  properties: List(#(String, cymbal.Yaml)),
) -> cymbal.Yaml {
  yaml_block([
    #("kind", cymbal.string(kind)),
    #("type", type_to_yaml(typ)),
    ..properties
  ])
}

fn statement_to_yaml(statement: typed.Statement) -> cymbal.Yaml {
  case statement {
    typed.Use(typ:, patterns:, function:, ..) ->
      typed_node("use", typ, [
        #("patterns", yaml_list(patterns, use_pattern_to_yaml)),
        #("function", expression_to_yaml(function)),
      ])
    typed.Assignment(typ:, kind:, pattern:, annotation:, value:, ..) ->
      typed_node(
        "assignment",
        typ,
        [
          Some(
            #("assignment_kind", case kind {
              typed.Let -> cymbal.string("let")
              typed.LetAssert(None) -> cymbal.string("let_assert")
              typed.LetAssert(Some(message)) ->
                typed_node("let_assert", message.typ, [
                  #("message", expression_to_yaml(message)),
                ])
            }),
          ),
          Some(#("pattern", pattern_to_yaml(pattern))),
          option.map(annotation, fn(annotation) {
            #("annotation", annotation_to_yaml(annotation))
          }),
          Some(#("value", expression_to_yaml(value))),
        ]
          |> option.values,
      )
    typed.Assert(typ:, expression:, message:, ..) ->
      typed_node(
        "assert",
        typ,
        [
          Some(#("expression", expression_to_yaml(expression))),
          option.map(message, fn(message) {
            #("message", expression_to_yaml(message))
          }),
        ]
          |> option.values,
      )
    typed.Expression(expression:, ..) -> expression_to_yaml(expression)
  }
}

fn use_pattern_to_yaml(use_pattern: typed.UsePattern) -> cymbal.Yaml {
  yaml_block(
    [
      Some(#("pattern", pattern_to_yaml(use_pattern.pattern))),
      option.map(use_pattern.annotation, fn(annotation) {
        #("annotation", annotation_to_yaml(annotation))
      }),
    ]
    |> option.values,
  )
}

fn expression_to_yaml(expression: typed.Expression) -> cymbal.Yaml {
  case expression {
    typed.Int(typ:, value:, ..) ->
      typed_node("int_literal", typ, [#("value", cymbal.string(value))])
    typed.Float(typ:, value:, ..) ->
      typed_node("float_literal", typ, [#("value", cymbal.string(value))])
    typed.String(typ:, value:, ..) ->
      typed_node("string_literal", typ, [#("value", cymbal.string(value))])
    typed.LocalVariable(typ:, name:, ..) ->
      typed_node("local_variable", typ, [#("name", cymbal.string(name))])
    typed.Function(typ:, module:, name:, ..) ->
      typed_node("function", typ, [
        #("module", cymbal.string(module)),
        #("name", cymbal.string(name)),
      ])
    typed.Constant(typ:, module:, name:, ..) ->
      typed_node("constant", typ, [
        #("module", cymbal.string(module)),
        #("name", cymbal.string(name)),
      ])
    typed.NegateInt(typ:, value:, ..) ->
      typed_node("negate_int", typ, [#("value", expression_to_yaml(value))])
    typed.NegateBool(typ:, value:, ..) ->
      typed_node("negate_bool", typ, [#("value", expression_to_yaml(value))])
    typed.Block(typ:, statements:, ..) ->
      typed_node("block", typ, [
        #("statements", yaml_list(statements, statement_to_yaml)),
      ])
    typed.Panic(typ:, message:, ..) ->
      typed_node("panic", typ, case message {
        Some(value) -> [#("value", expression_to_yaml(value))]
        None -> []
      })
    typed.Todo(typ:, message:, ..) ->
      typed_node("todo", typ, case message {
        Some(value) -> [#("value", expression_to_yaml(value))]
        None -> []
      })
    typed.Echo(typ:, expression:, message:, ..) ->
      typed_node(
        "echo",
        typ,
        [
          case expression {
            Some(e) -> Some(#("expression", expression_to_yaml(e)))
            None -> None
          },
          case message {
            Some(m) -> Some(#("message", expression_to_yaml(m)))
            None -> None
          },
        ]
          |> option.values,
      )
    typed.Tuple(typ:, elements:, ..) ->
      typed_node("tuple", typ, [
        #("elements", yaml_list(elements, expression_to_yaml)),
      ])
    typed.List(typ:, elements:, rest:, ..) ->
      typed_node("list", typ, [
        #("elements", yaml_list(elements, expression_to_yaml)),
        ..case rest {
          Some(rest) -> [#("rest", expression_to_yaml(rest))]
          None -> []
        }
      ])
    typed.Fn(typ:, parameters:, return_annotation:, body:, ..) ->
      typed_node(
        "fn",
        typ,
        [
          Some(#("parameters", yaml_list(parameters, fn_parameter_to_yaml))),
          option.map(return_annotation, fn(return) {
            #("return", annotation_to_yaml(return))
          }),
          Some(#("body", yaml_list(body, statement_to_yaml))),
        ]
          |> option.values,
      )
    typed.RecordUpdate(
      typ:,
      resolved_module:,
      constructor:,
      record:,
      positional_fields:,
      ..,
    ) ->
      typed_node("record_update", typ, [
        #("module", cymbal.string(resolved_module)),
        #("constructor", cymbal.string(constructor)),
        #("record", expression_to_yaml(record)),
        #(
          "positional_arguments",
          yaml_list(positional_fields, fn(field) {
            case field {
              typed.UpdatedField(expr) -> expression_to_yaml(expr)
              typed.UnchangedField(typ) ->
                cymbal.block([#("unchanged", type_to_yaml(typ))])
            }
          }),
        ),
      ])
    typed.FieldAccess(
      typ:,
      container:,
      module:,
      constructor:,
      label:,
      index:,
      ..,
    ) ->
      typed_node("field_access", typ, [
        #("container", expression_to_yaml(container)),
        #("module", cymbal.string(module)),
        #("variant", cymbal.string(constructor)),
        #("label", cymbal.string(label)),
        #("index", cymbal.int(index)),
      ])
    typed.Call(typ:, function:, positional_arguments:, ..) ->
      typed_node("call", typ, [
        #("function", expression_to_yaml(function)),
        #(
          "positional_arguments",
          yaml_list(positional_arguments, expression_to_yaml),
        ),
      ])
    typed.TupleIndex(typ:, tuple:, index:, ..) ->
      typed_node("tuple_index", typ, [
        #("tuple", expression_to_yaml(tuple)),
        #("index", cymbal.int(index)),
      ])
    typed.FnCapture(
      typ:,
      label:,
      function:,
      arguments_before:,
      arguments_after:,
      ..,
    ) ->
      typed_node(
        "fn_capture",
        typ,
        [
          option.map(label, fn(label) { #("label", cymbal.string(label)) }),
          Some(#("function", expression_to_yaml(function))),
          Some(#(
            "arguments_before",
            yaml_list(arguments_before, field_to_yaml(
              _,
              "value",
              expression_to_yaml,
            )),
          )),
          Some(#(
            "arguments_after",
            yaml_list(arguments_after, field_to_yaml(
              _,
              "value",
              expression_to_yaml,
            )),
          )),
        ]
          |> option.values,
      )
    typed.BitString(typ:, segments:, ..) ->
      typed_node("bit_string", typ, [
        #(
          "segments",
          yaml_list(segments, fn(segment) {
            yaml_block([
              #("expression", expression_to_yaml(segment.0)),
              #(
                "options",
                yaml_list(segment.1, bit_string_segment_option_to_yaml(
                  _,
                  expression_to_yaml,
                )),
              ),
            ])
          }),
        ),
      ])
    typed.Case(typ:, subjects:, clauses:, ..) ->
      typed_node("case", typ, [
        #("subjects", yaml_list(subjects, expression_to_yaml)),
        #("clauses", yaml_list(clauses, clause_to_yaml)),
      ])
    typed.BinaryOperator(typ:, name:, left:, right:, ..) ->
      typed_node("binary_operator", typ, [
        #("name", cymbal.string(binary_operator_to_string(name))),
        #("left", expression_to_yaml(left)),
        #("right", expression_to_yaml(right)),
      ])
    typed.Pipe(typ:, left:, right:, ..) -> {
      typed_node("pipe", typ, [
        #("left", expression_to_yaml(left)),
        #("right", pipe_target_to_yaml(right)),
      ])
    }
  }
}

fn pipe_target_to_yaml(into: typed.PipeInto) -> cymbal.Yaml {
  case into {
    typed.PipeIntoEcho(message:) ->
      yaml_block(
        [
          Some(#("kind", cymbal.string("echo"))),
          option.map(message, fn(message) {
            #("message", expression_to_yaml(message))
          }),
        ]
        |> option.values,
      )
    typed.PipeIntoFnCapture(
      label:,
      function:,
      arguments_before:,
      arguments_after:,
    ) ->
      yaml_block(
        [
          Some(#("kind", cymbal.string("fn_capture"))),
          option.map(label, fn(label) { #("label", cymbal.string(label)) }),
          Some(#("function", expression_to_yaml(function))),
          Some(#(
            "arguments_before",
            yaml_list(arguments_before, field_to_yaml(
              _,
              "value",
              expression_to_yaml,
            )),
          )),
          Some(#(
            "arguments_after",
            yaml_list(arguments_after, field_to_yaml(
              _,
              "value",
              expression_to_yaml,
            )),
          )),
        ]
        |> option.values,
      )
  }
}

fn field_to_yaml(
  field: typed.Field(a),
  item_name: String,
  convert: fn(a) -> cymbal.Yaml,
) -> cymbal.Yaml {
  let label = case field {
    typed.LabelledField(..) -> Some(field.label)
    typed.ShorthandField(..) -> Some(field.label)
    typed.UnlabelledField(..) -> None
  }
  let item = field.item
  yaml_block(
    [
      option.map(label, fn(l) { #("label", cymbal.string(l)) }),
      Some(#(item_name, convert(item))),
    ]
    |> option.values,
  )
}

fn binary_operator_to_string(operator: typed.BinaryOperator) -> String {
  case operator {
    typed.And -> "&&"
    typed.Or -> "||"
    typed.Eq -> "=="
    typed.NotEq -> "!="
    typed.LtInt -> "<"
    typed.LtEqInt -> "<="
    typed.LtFloat -> "<."
    typed.LtEqFloat -> "<=."
    typed.GtEqInt -> ">="
    typed.GtInt -> ">"
    typed.GtEqFloat -> ">=."
    typed.GtFloat -> ">."
    typed.AddInt -> "+"
    typed.AddFloat -> "+."
    typed.SubInt -> "-"
    typed.SubFloat -> "-."
    typed.MultInt -> "*"
    typed.MultFloat -> "*."
    typed.DivInt -> "/"
    typed.DivFloat -> "/."
    typed.RemainderInt -> "%"
    typed.Concatenate -> "<>"
  }
}

fn clause_to_yaml(clause: typed.Clause) -> cymbal.Yaml {
  yaml_block(
    [
      Some(#(
        "patterns",
        yaml_list(clause.patterns, yaml_list(_, pattern_to_yaml)),
      )),
      option.map(clause.guard, fn(guard) {
        #("guard", expression_to_yaml(guard))
      }),
      Some(#("body", expression_to_yaml(clause.body))),
    ]
    |> option.values,
  )
}

fn pattern_to_yaml(pattern: typed.Pattern) -> cymbal.Yaml {
  case pattern {
    typed.PatternInt(typ:, value:, ..) ->
      typed_node("int_pattern", typ, [#("value", cymbal.string(value))])
    typed.PatternFloat(typ:, value:, ..) ->
      typed_node("float_pattern", typ, [#("value", cymbal.string(value))])
    typed.PatternString(typ:, value:, ..) ->
      typed_node("string_pattern", typ, [#("value", cymbal.string(value))])
    typed.PatternDiscard(typ:, name:, ..) ->
      typed_node("discard_pattern", typ, [#("name", cymbal.string(name))])
    typed.PatternVariable(typ:, name:, ..) ->
      typed_node("variable_pattern", typ, [#("name", cymbal.string(name))])
    typed.PatternTuple(typ:, elements:, ..) ->
      typed_node("tuple_pattern", typ, [
        #("elements", yaml_list(elements, pattern_to_yaml)),
      ])
    typed.PatternList(typ:, elements:, tail:, ..) ->
      typed_node(
        "list_pattern",
        typ,
        [
          Some(#("elements", yaml_list(elements, pattern_to_yaml))),
          option.map(tail, fn(tail) { #("tail", pattern_to_yaml(tail)) }),
        ]
          |> option.values,
      )
    typed.PatternAssignment(typ:, pattern:, name:, ..) ->
      typed_node("assignment_pattern", typ, [
        #("name", cymbal.string(name)),
        #("pattern", pattern_to_yaml(pattern)),
      ])
    typed.PatternConcatenate(typ:, prefix:, prefix_name:, rest_name:, ..) ->
      typed_node(
        "concatenate_pattern",
        typ,
        [
          Some(#("prefix", cymbal.string(prefix))),
          option.map(prefix_name, fn(name) {
            #("prefix_name", assignment_name_to_yaml(name))
          }),
          Some(#("suffix_name", assignment_name_to_yaml(rest_name))),
        ]
          |> option.values,
      )
    typed.PatternBitString(typ:, segments:, ..) ->
      typed_node("bit_string_pattern", typ, [
        #(
          "segments",
          yaml_list(segments, fn(segment) {
            yaml_block([
              #("pattern", pattern_to_yaml(segment.0)),
              #(
                "options",
                yaml_list(segment.1, bit_string_segment_option_to_yaml(
                  _,
                  pattern_to_yaml,
                )),
              ),
            ])
          }),
        ),
      ])
    typed.PatternVariant(
      typ:,
      module:,
      constructor:,
      with_spread:,
      resolved_module:,
      positional_arguments:,
      ..,
    ) ->
      typed_node("constructor_pattern", typ, [
        #("module", case module {
          Some(m) -> cymbal.string(m)
          None -> cymbal.string("")
        }),
        #("constructor", cymbal.string(constructor)),
        #("with_spread", cymbal.bool(with_spread)),
        #(
          "positional_arguments",
          yaml_list(positional_arguments, fn(f) {
            case f {
              typed.MatchedArgument(pattern) -> pattern_to_yaml(pattern)
              typed.UnmatchedArgument(typ) ->
                cymbal.block([#("unmatched", type_to_yaml(typ))])
            }
          }),
        ),
        #("resolved_module", cymbal.string(resolved_module)),
      ])
  }
}

fn function_parameter_to_yaml(
  function_parameter: typed.FunctionParameter,
) -> cymbal.Yaml {
  let typed.FunctionParameter(typ:, label:, name:, annotation:) =
    function_parameter
  yaml_block(
    [
      Some(#("type", type_to_yaml(typ))),
      option.map(label, fn(label) { #("label", cymbal.string(label)) }),
      Some(#("name", assignment_name_to_yaml(name))),
      option.map(annotation, fn(annotation) {
        #("annotation", annotation_to_yaml(annotation))
      }),
    ]
    |> option.values,
  )
}

fn fn_parameter_to_yaml(fn_parameter: typed.FnParameter) -> cymbal.Yaml {
  let typed.FnParameter(typ:, name:, annotation:) = fn_parameter
  yaml_block(
    [
      Some(#("type", type_to_yaml(typ))),
      Some(#("name", assignment_name_to_yaml(name))),
      option.map(annotation, fn(annotation) {
        #("annotation", annotation_to_yaml(annotation))
      }),
    ]
    |> option.values,
  )
}

fn assignment_name_to_yaml(name: typed.AssignmentName) -> cymbal.Yaml {
  case name {
    typed.Named(value:) -> value
    typed.Discarded(value:) -> "_" <> value
  }
  |> cymbal.string
}

fn polytype_to_yaml(polytype: typed.Poly) -> cymbal.Yaml {
  cymbal.string(
    "("
    <> string.join(
      list.map(polytype.vars, fn(type_var_id) { int.to_string(type_var_id.id) }),
      ", ",
    )
    <> ") "
    <> type_to_string(polytype.typ),
  )
}

fn type_to_string(typ: typed.Type) -> String {
  let of_list = fn(types) { string.join(list.map(types, type_to_string), ", ") }
  case typ {
    typed.NamedType(module:, name:, parameters:) ->
      module
      <> "."
      <> name
      <> case parameters {
        [] -> ""
        _ -> "(" <> of_list(parameters) <> ")"
      }
    typed.TupleType(elements:) -> "#(" <> of_list(elements) <> ")"
    typed.FunctionType(parameters:, return:) ->
      "fn(" <> of_list(parameters) <> ") -> " <> type_to_string(return)
    typed.VariableType(ref:) -> int.to_string(ref.id)
  }
}

fn type_to_yaml(typ: typed.Type) -> cymbal.Yaml {
  cymbal.string(type_to_string(typ))
}

fn publicity_to_yaml(publicity: typed.Publicity) -> cymbal.Yaml {
  case publicity {
    typed.Public -> "public"
    typed.Private -> "private"
  }
  |> cymbal.string
}

fn annotation_to_yaml(annotation: typed.Annotation) -> cymbal.Yaml {
  yaml_block([
    #("annotation", cymbal.string(annotation_to_string(annotation))),
    #("type", type_to_yaml(annotation.typ)),
  ])
}

fn annotation_to_string(annotation: typed.Annotation) -> String {
  let of_list = fn(annotations) {
    string.join(list.map(annotations, annotation_to_string), ", ")
  }
  case annotation {
    typed.NamedAnno(module:, name:, parameters:, ..) ->
      case module {
        Some(module) -> module <> "."
        None -> ""
      }
      <> name
      <> case parameters {
        [] -> ""
        _ -> "(" <> of_list(parameters) <> ")"
      }
    typed.TupleAnno(elements:, ..) -> "#(" <> of_list(elements) <> ")"
    typed.FunctionAnno(parameters:, return:, ..) ->
      "fn(" <> of_list(parameters) <> ") -> " <> annotation_to_string(return)
    typed.VariableAnno(name:, ..) -> name
    typed.HoleAnno(name:, ..) -> "_" <> name
  }
}

fn attribute_to_yaml(attribute: typed.Attribute) -> cymbal.Yaml {
  yaml_block([
    #("name", cymbal.string(attribute.name)),
    #("arguments", yaml_list(attribute.arguments, attribute_argument_to_yaml)),
  ])
}

fn attribute_argument_to_yaml(argument: typed.AttributeArgument) -> cymbal.Yaml {
  case argument {
    typed.NameAttributeArgument(name:) ->
      yaml_block([#("name", cymbal.string(name))])
    typed.StringAttributeArgument(value:) ->
      yaml_block([#("value", cymbal.string(value))])
  }
}

fn unqualified_import_to_yaml(
  unqualified_import: typed.UnqualifiedImport,
) -> cymbal.Yaml {
  yaml_block(
    [
      Some(#("name", cymbal.string(unqualified_import.name))),
      option.map(unqualified_import.alias, fn(alias) {
        #("alias", cymbal.string(alias))
      }),
    ]
    |> option.values,
  )
}

fn bit_string_segment_option_to_yaml(
  option: typed.BitStringSegmentOption(a),
  convert: fn(a) -> cymbal.Yaml,
) -> cymbal.Yaml {
  case option {
    typed.BytesOption -> cymbal.string("bytes")
    typed.IntOption -> cymbal.string("int")
    typed.FloatOption -> cymbal.string("float")
    typed.BitsOption -> cymbal.string("bits")
    typed.Utf8Option -> cymbal.string("utf8")
    typed.Utf16Option -> cymbal.string("utf16")
    typed.Utf32Option -> cymbal.string("utf32")
    typed.Utf8CodepointOption -> cymbal.string("utf8_codepoint")
    typed.Utf16CodepointOption -> cymbal.string("utf16_codepoint")
    typed.Utf32CodepointOption -> cymbal.string("utf32_codepoint")
    typed.SignedOption -> cymbal.string("signed")
    typed.UnsignedOption -> cymbal.string("unsigned")
    typed.BigOption -> cymbal.string("big")
    typed.LittleOption -> cymbal.string("little")
    typed.NativeOption -> cymbal.string("native")
    typed.SizeValueOption(value) ->
      yaml_block([#("size_value", convert(value))])
    typed.SizeOption(size) -> yaml_block([#("size", cymbal.int(size))])
    typed.UnitOption(unit) -> yaml_block([#("unit", cymbal.int(unit))])
  }
}
