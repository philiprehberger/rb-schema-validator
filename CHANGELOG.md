# Changelog

All notable changes to this gem will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
