# Changelog

## 0.2.2

- Fix rubocop: string interpolation style, ParameterLists cop

## 0.2.1

- Add License badge to README
- Add bug_tracker_uri to gemspec
- Add Development section to README
- Add Requirements section to README

All notable changes to this gem will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
