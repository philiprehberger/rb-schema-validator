# Philiprehberger::SchemaValidator

Lightweight schema validation for Ruby hashes with type checking and coercion.

## Installation

Add this line to your Gemfile:

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

### Validation Options

#### `format:` — Regex Pattern Validation

```ruby
schema = Philiprehberger::SchemaValidator.define do
  string :email, format: /\A[^@\s]+@[^@\s]+\z/
end
```

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

### Schema Introspection

```ruby
schema = Philiprehberger::SchemaValidator.define do
  string :name
  integer :age
end

schema.fields # => [:name, :age]
```

### Custom Validation

Pass a block to any field definition for custom validation. Return a string to indicate an error:

```ruby
schema = Philiprehberger::SchemaValidator.define do
  integer(:age) { |v| "must be positive" if v.negative? }
  string(:email) { |v| "must contain @" unless v.include?("@") }
end
```

## Supported Types

| DSL Method   | Ruby Type | Coerces From       |
|-------------|-----------|-------------------|
| `string`    | String    | any (via `to_s`)  |
| `integer`   | Integer   | String            |
| `float`     | Float     | String            |
| `boolean`   | Boolean   | String (true/false/yes/no/1/0/on/off) |
| `array`     | Array     | -                 |
| `hash_field`| Hash      | -                 |

## API

### `Philiprehberger::SchemaValidator.define(&block)` -> `Schema`

Creates a new schema using the DSL block.

### `Schema#fields` -> `Array<Symbol>`

Returns the list of defined field names.

### `Schema#validate(data)` -> `Result`

Validates a hash against the schema. Returns a `Result` object.

### `Schema#validate!(data)` -> `Result`

Validates and raises `ValidationError` if invalid.

### `Result#valid?` -> `Boolean`

Returns `true` if there are no errors.

### `Result#errors` -> `Array<String>`

Array of error message strings.

## License

MIT
