//// Pattern match coverage analysis.
////
//// Based on "Warnings for pattern matching" by Maranget.

import gleam/list
import gleam/option.{type Option}

pub type ConstructorId {
  ConstructorId(module: String, name: String)
}

pub type Pattern {
  Wild
  ConstructorPattern(constructor: ConstructorId, arguments: List(Pattern))
  IntPattern(value: String)
  FloatPattern(value: String)
  StringPattern(value: String)
  OpaquePattern
}

pub type Domain {
  ClosedDomain(constructors: List(Constructor))
  OpenDomain
}

pub type Constructor {
  Constructor(
    id: ConstructorId,
    labels: List(Option(String)),
    arity: Int,
    arguments: fn() -> List(Domain),
  )
}

/// Returns pattern witnesses matched by the query but not covered by the matrix.
pub fn witnesses(
  domains: List(Domain),
  matrix: List(List(Pattern)),
  query: List(Pattern),
  limit: Int,
) -> List(List(Pattern)) {
  do_witnesses(domains, matrix, query, 0)
  |> list.take(limit)
}

fn do_witnesses(
  domains: List(Domain),
  matrix: List(List(Pattern)),
  query: List(Pattern),
  depth: Int,
) -> List(List(Pattern)) {
  case query {
    // An empty query is a witness unless the matrix contains an empty row, which covers every value.
    [] ->
      case list.contains(matrix, []) {
        True -> []
        False -> [[]]
      }
    _ ->
      case matrix == [] && depth > 0 {
        // When the matrix is empty, return the rest of the query as the witness
        // except when depth=0 to improve error messages.
        True -> [query]
        False ->
          case query, domains {
            _, [] -> []
            [], _ -> []
            [q, ..qs], [d, ..ds] ->
              case q {
                Wild ->
                  case d {
                    ClosedDomain(constructors) ->
                      case column_mentions(matrix) || matrix == [] {
                        True ->
                          list.flat_map(constructors, fn(constructor) {
                            do_witnesses(
                              list.append(constructor.arguments(), ds),
                              specialize(
                                matrix,
                                constructor.id,
                                constructor.arity,
                              ),
                              list.append(wildcards(constructor.arity), qs),
                              depth + 1,
                            )
                            |> expand_all(constructor.id, constructor.arity)
                          })
                        // No information about this column, move on to the next column.
                        False ->
                          do_witnesses(ds, default_matrix(matrix), qs, depth)
                          |> list.map(fn(witness) { [Wild, ..witness] })
                      }
                    OpenDomain ->
                      do_witnesses(ds, default_matrix(matrix), qs, depth)
                      |> list.map(fn(witness) { [Wild, ..witness] })
                  }
                ConstructorPattern(constructor, arguments) -> {
                  let arity = list.length(arguments)
                  case constructor_domains(d, constructor, arity) {
                    Error(Nil) -> []
                    Ok(argument_domains) ->
                      do_witnesses(
                        list.append(argument_domains, ds),
                        specialize(matrix, constructor, arity),
                        list.append(arguments, qs),
                        depth + 1,
                      )
                      |> expand_all(constructor, arity)
                  }
                }
                OpaquePattern -> {
                  // Only wildcards are known to cover an opaque pattern, so use the default matrix.
                  do_witnesses(ds, default_matrix(matrix), qs, depth + 1)
                  |> list.map(fn(witness) { [OpaquePattern, ..witness] })
                }
                literal -> literal_witnesses(matrix, literal, qs, ds, depth + 1)
              }
          }
      }
  }
}

/// Witnesses for a literal query column.
/// Only the same literal or a wildcard can cover the queried literal.
fn literal_witnesses(
  matrix: List(List(Pattern)),
  literal: Pattern,
  query_tail: List(Pattern),
  domains_tail: List(Domain),
  depth: Int,
) -> List(List(Pattern)) {
  let specialised =
    list.filter_map(matrix, fn(row) {
      case row {
        [Wild, ..tail] -> Ok(tail)
        [head, ..tail] if head == literal -> Ok(tail)
        _ -> Error(Nil)
      }
    })
  do_witnesses(domains_tail, specialised, query_tail, depth)
  |> list.map(fn(witness) { [literal, ..witness] })
}

/// Whether any row of the matrix constrains the current column to specific
/// constructors or literals rather than matching every value.
fn column_mentions(matrix: List(List(Pattern))) -> Bool {
  list.any(matrix, fn(row) {
    case row {
      [Wild, ..] | [OpaquePattern, ..] -> False
      [ConstructorPattern(..), ..]
      | [IntPattern(..), ..]
      | [FloatPattern(..), ..]
      | [StringPattern(..), ..] -> True
      [] -> False
    }
  })
}

fn expand_all(
  witnesses: List(List(Pattern)),
  constructor: ConstructorId,
  arity: Int,
) -> List(List(Pattern)) {
  list.map(witnesses, fn(witness) {
    let #(taken, rest) = list.split(witness, arity)
    [ConstructorPattern(constructor, taken), ..rest]
  })
}

/// Keeps the rows that can match a value built with the given constructor,
/// replacing the head with one slot per constructor argument.
fn specialize(
  matrix: List(List(Pattern)),
  constructor: ConstructorId,
  arity: Int,
) -> List(List(Pattern)) {
  list.filter_map(matrix, fn(row) {
    case row {
      [] -> Error(Nil)
      [Wild, ..tail] -> Ok(list.append(wildcards(arity), tail))
      [ConstructorPattern(id, arguments), ..tail] if id == constructor ->
        Ok(list.append(arguments, tail))
      _ -> Error(Nil)
    }
  })
}

/// Keeps rows whose first pattern is a wildcard, then removes that wildcard.
/// These are the only rows known to match every value in the current column.
fn default_matrix(matrix: List(List(Pattern))) -> List(List(Pattern)) {
  list.filter_map(matrix, fn(row) {
    case row {
      [Wild, ..tail] -> Ok(tail)
      _ -> Error(Nil)
    }
  })
}

/// Returns the domains of a constructor's arguments.
/// Returns an error if the current domain cannot contain that constructor.
/// For an open domain, each argument also has an open domain.
fn constructor_domains(
  domain: Domain,
  constructor: ConstructorId,
  arity: Int,
) -> Result(List(Domain), Nil) {
  case domain {
    ClosedDomain(constructors) ->
      case list.find(constructors, fn(c) { c.id == constructor }) {
        Ok(c) -> Ok(c.arguments())
        Error(_) -> Error(Nil)
      }
    OpenDomain -> Ok(list.repeat(OpenDomain, arity))
  }
}

fn wildcards(n: Int) -> List(Pattern) {
  list.repeat(Wild, n)
}
