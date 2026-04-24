# philiprehberger-schema_validator

[![Tests](https://github.com/philiprehberger/rb-schema-validator/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-schema-validator/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-schema_validator.svg)](https://rubygems.org/gems/philiprehberger-schema_validator)
[![Last updated](https://img.shields.io/github/last-commit/philiprehberger/rb-schema-validator)](https://github.com/philiprehberger/rb-schema-validator/commits/main)

Lightweight schema validation for hashes with type coercion

## Requirements

- Ruby >= 3.1

## Installation

Add to your Gemfile:

```ruby
gem "philiprehberger-schema_validator"
```

Or install directly:

```bash
gem install philiprehberger-schema_validator
```

## Usage

### Define a Schema

```ruby
require "philiprehberger/schema_validator"

schema = Philiprehberger::SchemaValidator.define do
  string :name
  integer :age
  float :score, required: false, default: 0.0
  boolean :active
  array :tags, required: false
  hash_field :metadata, required: false
end
```

### Validate Data

```ruby
result = schema.validate({ name: "Alice", age: 30, active: true })

if result.valid?
  puts "Data is valid!"
else
  puts result.errors
end
```

### Raise on Invalid Data

```ruby
schema.validate!({ name: "Alice" })
# => raises Philiprehberger::SchemaValidator::ValidationError
```

### Type Coercion

Values are automatically coerced to the declared type when possible:

```ruby
schema = Philiprehberger::SchemaValidator.define do
  integer :count
  boolean :enabled
end

result = schema.validate({ count: "123", enabled: "true" })
result.valid? # => true
```

### Validate and Coerce in One Call

Use `validate_and_coerce` when you want the coerced payload alongside validity and errors in a single call:

```ruby
schema = Philiprehberger::SchemaValidator.define do
  string :name
  integer :age
end

outcome = schema.validate_and_coerce({ name: 'Alice', age: '30' })
outcome[:valid]  # => true
outcome[:values] # => { name: "Alice", age: 30 }
outcome[:errors] # => []
```

Coercion is best-effort even when validation fails — fields with well-defined coercion are coerced, and fields without a valid coercion are returned as-is so the caller can inspect the original input:

```ruby
outcome = schema.validate_and_coerce({ name: 123, age: 'bad' })
outcome[:valid]  # => false
outcome[:values] # => { name: "123", age: "bad" }
outcome[:errors] # => ["age must be integer"]
```

### Validation Options

#### `format:` — Regex Pattern Validation

```ruby
schema = Philiprehberger::SchemaValidator.define do
  string :email, format: /\A[^@\s]+@[^@\s]+\z/
end
```

#### Format Presets

Use built-in format presets instead of writing regex patterns:

```ruby
schema = Philiprehberger::SchemaValidator.define do
  string :email, format: :email
  string :website, format: :url
  string :id, format: :uuid
  string :created_at, format: :iso8601
  string :phone, format: :phone
end
```

Available presets:

| Preset     | Matches                                          |
|------------|--------------------------------------------------|
| `:email`   | Basic email format (`user@domain.tld`)           |
| `:url`     | HTTP/HTTPS URLs                                  |
| `:uuid`    | UUID v4 format                                   |
| `:iso8601` | ISO 8601 date and datetime                       |
| `:phone`   | International phone numbers                      |

Both symbol presets and `Regexp` values are supported for `format:`.

#### `in:` — Allowlist Validation

```ruby
schema = Philiprehberger::SchemaValidator.define do
  string :role, in: %w[admin user guest]
end
```

#### `min:` / `max:` — Numeric Range Validation

```ruby
schema = Philiprehberger::SchemaValidator.define do
  integer :age, min: 0, max: 150
  float :score, min: 0.0, max: 100.0
end
```

#### `length:` — String and Array Length Validation

Constrain the length of strings and arrays with an `Integer` (exact) or `Range` (bounded, endless, or beginless):

```ruby
schema = Philiprehberger::SchemaValidator.define do
  string :username, length: 3..20           # between 3 and 20 chars
  string :code, length: 4                   # exactly 4 chars
  string :password, length: (8..)           # at least 8 chars
  string :note, length: (..280)             # at most 280 chars
  array :tags, length: 1..5                 # between 1 and 5 elements
end

result = schema.validate({ username: 'al', code: 'ABC', password: 'short', note: 'ok', tags: [] })
result.errors
# => [
#   "username length must be between 3 and 20 (got 2)",
#   "code length must be exactly 4 (got 3)",
#   "password length must be >= 8 (got 5)",
#   "tags length must be between 1 and 5 (got 0)"
# ]
```

Length constraints are also exported to JSON Schema as `minLength`/`maxLength` (strings) and `minItems`/`maxItems` (arrays).

### Nested Schema Validation

Validate objects within objects using the `nested` DSL method:

```ruby
schema = Philiprehberger::SchemaValidator.define do
  string :name, required: true
  nested :address, required: true do
    string :city, required: true
    string :zip, required: true
  end
end

result = schema.validate({ name: "Alice", address: { city: "Vienna" } })
result.errors # => ["address.zip is required"]
```

Nested schemas support all the same field types and options. Nesting can go arbitrarily deep:

```ruby
schema = Philiprehberger::SchemaValidator.define do
  nested :config, required: true do
    nested :database, required: true do
      string :host, required: true
      integer :port, required: true
    end
  end
end
```

### Array Element Validation

Validate the type of each element in an array with `of:`:

```ruby
schema = Philiprehberger::SchemaValidator.define do
  array :tags, of: :string
  array :scores, of: :integer
end

result = schema.validate({ tags: ["a", "b"], scores: [1, "bad", 3] })
result.errors # => ["scores[1] must be a integer"]
```

Validate arrays of objects with `schema:`:

```ruby
address_schema = Philiprehberger::SchemaValidator.define do
  string :city, required: true
  string :zip, required: true
end

schema = Philiprehberger::SchemaValidator.define do
  array :addresses, schema: address_schema
end

result = schema.validate({ addresses: [{ city: "Vienna" }] })
result.errors # => ["addresses[0].zip is required"]
```

### Cross-Field Validation

Add schema-level validation blocks for relational checks between fields:

```ruby
schema = Philiprehberger::SchemaValidator.define do
  integer :min_age, required: false
  integer :max_age, required: false

  validate do |data, errors|
    if data[:min_age] && data[:max_age] && data[:min_age] > data[:max_age]
      errors << "min_age must be less than or equal to max_age"
    end
  end
end
```

Multiple `validate` blocks can be defined on the same schema.

### Schema Composition

Combine and extend schemas using `merge`:

```ruby
base = Philiprehberger::SchemaValidator.define do
  string :name, required: true
end

extended = base.merge do
  integer :age, required: false
  string :email, required: true
end

extended.fields # => [:name, :age, :email]
```

The original schema is not modified. Nested schemas and cross-field validators are preserved in the merged schema.

### Schema Introspection

```ruby
schema = Philiprehberger::SchemaValidator.define do
  string :name
  integer :age
end

schema.fields # => [:name, :age]
```

Query which fields are required (defaults to `true`):

```ruby
schema = Philiprehberger::SchemaValidator.define do
  string :name
  integer :age, required: false
end

schema.required_fields # => [:name]
```

### Custom Validation

Pass a block to any field definition for custom validation. Return a string to indicate an error:

```ruby
schema = Philiprehberger::SchemaValidator.define do
  integer(:age) { |v| "must be positive" if v.negative? }
  string(:email) { |v| "must contain @" unless v.include?("@") }
end
```

### Conditional Dependencies

```ruby
schema = Philiprehberger::SchemaValidator.define do
  string :country, required: true
  string :state
  depends_on :state, when_field: { country: "US" }
end
```

### Exclusive Groups

```ruby
schema = Philiprehberger::SchemaValidator.define do
  string :credit_card
  string :bank_account
  exclusive_group :payment, %i[credit_card bank_account]
end
```

### Schema Projection

```ruby
sub = Schema.pick(base_schema, :name, :email)
sub = Schema.omit(base_schema, :age)
```

### Strict Mode

Reject any keys that are not declared in the schema by calling `strict!` inside the DSL block:

```ruby
schema = Philiprehberger::SchemaValidator.define do
  string :name, required: true
  integer :age, required: false
  strict!
end

result = schema.validate({ name: "Alice", age: 30, extra: "nope" })
result.errors # => ["extra is not a recognized key"]
```

Strict mode is preserved across `merge` and exported to JSON Schema as `additionalProperties: false`.

### Structured Result Output

`Result` exposes helpers for rendering errors in logs, APIs, or UIs:

```ruby
result = schema.validate({})

result.valid?          # => false
result.error_count     # => 2
result.to_h            # => { valid: false, errors: [...], error_count: 2 }
result.errors_by_field # => { "name" => ["name is required"], "address" => ["address.city is required"] }
```

`errors_by_field` groups errors by the leading field segment, so nested errors like `address.city is required` are grouped under `"address"`.

### JSON Schema Export

Export a schema as a simplified JSON Schema (draft 7) hash:

```ruby
schema = Philiprehberger::SchemaValidator.define do
  string :name
  integer :age, min: 0, max: 150
  array :tags, of: :string, required: false
end

schema.to_json_schema
# => {
#   "type" => "object",
#   "properties" => {
#     "name" => { "type" => "string" },
#     "age"  => { "type" => "integer", "minimum" => 0, "maximum" => 150 },
#     "tags" => { "type" => "array", "items" => { "type" => "string" } }
#   },
#   "required" => ["name", "age"]
# }
```

## API

### `SchemaValidator`

| Method | Description |
|--------|-------------|
| `.define(&block)` | Create a new schema using the DSL block |

### `Schema`

| Method | Description |
|--------|-------------|
| `#fields` | Return the list of defined field names |
| `#required_fields` | Return the names of fields declared with `required: true` |
| `#validate(data)` | Validate a hash against the schema; returns a `Result` |
| `#validate!(data)` | Validate and raise `ValidationError` if invalid |
| `#validate_and_coerce(data)` | Validate and return `{ valid:, values:, errors: }` with best-effort coerced payload |
| `#merge(&block)` | Create a new schema combining current fields with additional definitions |
| `#strict!` | Reject unknown keys not declared in the schema |
| `#strict?` | Return `true` if the schema rejects unknown keys |
| `depends_on(field, when_field:)` | Conditional field requirement |
| `exclusive_group(name, fields)` | Mutual exclusivity validation |
| `Schema.pick(base, *fields)` | Sub-schema with selected fields |
| `Schema.omit(base, *fields)` | Sub-schema excluding fields |
| `#to_json_schema` | Export schema as a JSON Schema (draft 7) hash |

### Field Options

| Option | Applies to | Description |
|--------|-----------|-------------|
| `required:` | all types | Mark field as required (default `true`) |
| `default:` | all types | Default value when the field is absent |
| `format:` | `string` | Regex or preset (`:email`, `:url`, `:uuid`, `:iso8601`, `:phone`) |
| `in:` | all types | Allowlist of acceptable values |
| `min:` / `max:` | `integer`, `float` | Numeric range bounds |
| `length:` | `string`, `array` | Exact length (Integer) or length range (Range) |
| `of:` | `array` | Element type (`:string`, `:integer`, ...) |
| `schema:` | `array` | Sub-schema each element must satisfy |

### `Result`

| Method | Description |
|--------|-------------|
| `#valid?` | Return `true` if there are no errors |
| `#errors` | Array of error message strings |
| `#error_count` | Number of errors in the result |
| `#to_h` | Structured hash: `{ valid:, errors:, error_count: }` |
| `#errors_by_field` | Group errors by the leading field name |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## Support

If you find this project useful:

⭐ [Star the repo](https://github.com/philiprehberger/rb-schema-validator)

🐛 [Report issues](https://github.com/philiprehberger/rb-schema-validator/issues?q=is%3Aissue+is%3Aopen+label%3Abug)

💡 [Suggest features](https://github.com/philiprehberger/rb-schema-validator/issues?q=is%3Aissue+is%3Aopen+label%3Aenhancement)

❤️ [Sponsor development](https://github.com/sponsors/philiprehberger)

🌐 [All Open Source Projects](https://philiprehberger.com/open-source-packages)

💻 [GitHub Profile](https://github.com/philiprehberger)

🔗 [LinkedIn Profile](https://www.linkedin.com/in/philiprehberger)

## License

[MIT](LICENSE)
