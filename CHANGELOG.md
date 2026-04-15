# Changelog

All notable changes to this gem will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.7.0] - 2026-04-15

### Added
- `Schema#validate_and_coerce(data)` returns `{ valid:, values:, errors: }` with a best-effort coerced payload alongside the existing error list — coerces fields with well-defined coercion and preserves raw values for the rest, even when validation fails

## [0.6.0] - 2026-04-15

### Added
- `length:` option for `string` and `array` fields — supports exact `Integer` length, bounded `Range`, endless `Range`, and beginless `Range`
- `strict!` DSL method on `Schema` to reject unknown keys not declared in the schema; exposed via `Schema#strict?` and exported as `additionalProperties: false` in `to_json_schema`
- `Result#error_count`, `Result#to_h`, and `Result#errors_by_field` for structured error reporting
- `length:` is exported to JSON Schema as `minLength`/`maxLength` (strings) and `minItems`/`maxItems` (arrays)

## [0.5.0] - 2026-04-04

### Added
- `to_json_schema` method on `Schema` for exporting a simplified JSON Schema (draft 7) representation
- Gem version field in bug report issue template
- Alternatives considered textarea in feature request issue template

## [0.4.0] - 2026-04-01

### Added
- `depends_on(field, when_field:)` for conditional field dependencies
- `exclusive_group(name, fields)` for mutual exclusivity validation
- `Schema.pick(base, *fields)` for creating sub-schemas with selected fields
- `Schema.omit(base, *fields)` for creating sub-schemas excluding fields

## [0.3.6] - 2026-03-31

### Added
- Add GitHub issue templates, dependabot config, and PR template

## [0.3.5] - 2026-03-31

### Changed
- Standardize README badges, support section, and license format

## [0.3.4] - 2026-03-26

### Fixed
- Add Sponsor badge to README
- Fix license section link format

## [0.3.3] - 2026-03-24

### Fixed
- Align README one-liner with gemspec summary

## [0.3.2] - 2026-03-24

### Fixed
- Standardize README API section to table format

## [0.3.1] - 2026-03-22

### Changed
- Remove extra Supported Types section from README for template compliance

## [0.3.1] - 2026-03-21

### Fixed
- Standardize Installation section in README

## [0.3.0] - 2026-03-17

### Added
- Nested schema validation via `nested` DSL method with recursive error prefixing
- Array element validation with `of:` option for type-checked elements
- Array of objects validation with `schema:` option
- Built-in format presets: `:email`, `:url`, `:uuid`, `:iso8601`, `:phone`
- Cross-field validation via `validate` block at schema level
- Schema composition via `merge` method to combine and extend schemas

## [0.2.2] - 2026-03-16

### Fixed
- Fix rubocop: string interpolation style, ParameterLists cop

## [0.2.1] - 2026-03-16

### Changed
- Remove extra Supported Types section from README for template compliance
- Add bug_tracker_uri to gemspec
- Add Development section to README
- Add Requirements section to README

## [0.2.0] - 2026-03-13

### Added
- `format:` option for regex pattern validation on string fields
- `in:` option for enum/allowlist validation on any field
- `min:` / `max:` options for numeric range validation on integer and float fields
- `fields` accessor on `Schema` for introspecting defined field names

### Fixed
- `coerce_boolean` now returns `nil` for unrecognized values instead of implicit `nil` that behaved as `false`

## [0.1.0] - 2026-03-10

### Added
- Initial release
- Schema DSL with `string`, `integer`, `float`, `boolean`, `array`, and `hash_field` types
- Required/optional fields with default values
- Type coercion (string to integer, float, boolean)
- Custom validation via blocks
- `Result` object with `valid?` and `errors` accessors
- `validate!` raises `ValidationError` on failure

[Unreleased]: https://github.com/philiprehberger/rb-schema-validator/compare/v0.6.0...HEAD
[0.6.0]: https://github.com/philiprehberger/rb-schema-validator/compare/v0.5.0...v0.6.0
[0.5.0]: https://github.com/philiprehberger/rb-schema-validator/compare/v0.4.0...v0.5.0
[0.4.0]: https://github.com/philiprehberger/rb-schema-validator/compare/v0.3.6...v0.4.0
[0.3.6]: https://github.com/philiprehberger/rb-schema-validator/compare/v0.3.5...v0.3.6
[0.3.5]: https://github.com/philiprehberger/rb-schema-validator/compare/v0.3.4...v0.3.5
[0.3.4]: https://github.com/philiprehberger/rb-schema-validator/compare/v0.3.3...v0.3.4
[0.3.3]: https://github.com/philiprehberger/rb-schema-validator/compare/v0.3.2...v0.3.3
[0.3.2]: https://github.com/philiprehberger/rb-schema-validator/compare/v0.3.1...v0.3.2
[0.3.1]: https://github.com/philiprehberger/rb-schema-validator/compare/v0.3.0...v0.3.1
[0.3.0]: https://github.com/philiprehberger/rb-schema-validator/compare/v0.2.2...v0.3.0
[0.2.2]: https://github.com/philiprehberger/rb-schema-validator/compare/v0.2.1...v0.2.2
[0.2.1]: https://github.com/philiprehberger/rb-schema-validator/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/philiprehberger/rb-schema-validator/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/philiprehberger/rb-schema-validator/releases/tag/v0.1.0
