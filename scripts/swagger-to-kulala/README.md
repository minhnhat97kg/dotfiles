# swagger-to-kulala

Convert Swagger/OpenAPI YAML specifications to [kulala.nvim](https://github.com/mistweaverco/kulala.nvim) HTTP request files.

## Features

- ✅ Supports OpenAPI 3.x and Swagger 2.0
- ✅ Generates IntelliJ HTTP Client compatible format
- ✅ Handles authentication (API Key, Bearer, Basic, OAuth2)
- ✅ Generates example request bodies from schemas
- ✅ Supports path, query, and header parameters
- ✅ Split output by tags or single file
- ✅ Includes operation summaries and descriptions

## Installation

### Build from source

```bash
cd scripts/swagger-to-kulala
go build -o swagger-to-kulala
```

### Install via Nix (in this dotfiles repo)

The tool will be built and available in your PATH after running `make install`.

## Usage

### Basic usage - output to stdout

```bash
swagger-to-kulala -i api.yaml
```

### Output to file

```bash
swagger-to-kulala -i api.yaml -o api.http
```

### Split by tags (creates multiple files)

```bash
swagger-to-kulala -i api.yaml -o output_dir -split
```

This creates separate `.http` files for each tag in the OpenAPI spec.

## Example Output

Given a simple OpenAPI spec:

```yaml
openapi: 3.0.0
info:
  title: Pet Store API
  version: 1.0.0
servers:
  - url: https://api.petstore.com/v1
paths:
  /pets:
    get:
      summary: List all pets
      parameters:
        - name: limit
          in: query
          schema:
            type: integer
            default: 10
      responses:
        '200':
          description: OK
    post:
      summary: Create a pet
      requestBody:
        content:
          application/json:
            schema:
              type: object
              properties:
                name:
                  type: string
                tag:
                  type: string
      responses:
        '201':
          description: Created
```

Generates:

```http
# Pet Store API - v1.0.0

# Variables
@baseUrl=https://api.petstore.com/v1

###
# List all pets
GET {{baseUrl}}/pets?limit=10

###
# Create a pet
POST {{baseUrl}}/pets
Content-Type: application/json

{
  "name": "string",
  "tag": "string"
}
```

## Features in Generated Files

### Variables

The tool generates common variables:
- `@baseUrl` - extracted from servers or host/basePath
- `@token` - placeholder for bearer tokens (if auth is used)
- `@api_key` - placeholder for API keys (if API key auth is used)

### Authentication

Automatically generates appropriate headers based on security schemes:

**API Key:**
```http
X-API-Key: {{api_key}}
```

**Bearer Token:**
```http
Authorization: Bearer {{token}}
```

**Basic Auth:**
```http
Authorization: Basic {{base64_credentials}}
```

### Request Bodies

Generates example JSON bodies from OpenAPI schemas:

```http
POST {{baseUrl}}/users
Content-Type: application/json

{
  "username": "string",
  "email": "user@example.com",
  "age": 0,
  "isActive": true,
  "roles": [
    "string"
  ]
}
```

### Parameters

- **Path parameters**: Substituted with example values
- **Query parameters**: Added to URL with example values
- **Header parameters**: Added as HTTP headers

## Use Cases

### Testing APIs in Neovim

1. Convert your OpenAPI spec to HTTP files
2. Open in Neovim with kulala.nvim installed
3. Use kulala commands to execute requests:
   - `<leader>rs` - Send request
   - `<leader>ri` - Inspect request
   - `<leader>rp` - Toggle response preview

### API Documentation

Generate human-readable HTTP request examples for your API documentation.

### Postman Alternative

Use generated files with any HTTP client that supports IntelliJ HTTP format:
- kulala.nvim (Neovim)
- IntelliJ IDEA
- VS Code REST Client extension

## Comparison with Other Tools

| Feature | swagger-to-kulala | Postman | curl |
|---------|------------------|---------|------|
| Version control friendly | ✅ | ❌ | ⚠️ |
| Works in terminal/editor | ✅ | ❌ | ✅ |
| OpenAPI native | ✅ | ⚠️ | ❌ |
| Human readable | ✅ | ⚠️ | ❌ |
| No GUI required | ✅ | ❌ | ✅ |

## Integration with kulala.nvim

After generating HTTP files, use them with kulala.nvim:

```lua
-- In your Neovim config
require('kulala').setup({
  default_view = "body",
  default_env = "dev",
})
```

Then navigate to any request and execute it!

## Limitations

- Does not resolve `$ref` references across files (only inline refs)
- Example generation is basic (uses type defaults)
- Does not generate response assertions
- OAuth2 flows require manual token management

## Contributing

This tool is part of the [dotfiles](https://github.com/nhath/dotfiles) repository.

## License

MIT
