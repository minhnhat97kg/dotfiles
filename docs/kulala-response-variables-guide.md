# Complete Guide: Extracting Response Fields and Setting Variables in Kulala.nvim

Based on the [official kulala.nvim documentation](https://neovim.getkulala.net/docs/usage), here are **all the methods** to extract response fields and set variables:

## Method 1: Request Variables (Simplest - No Scripts Needed)

Reference previous request responses directly using JSONPath notation:

```http
### LOGIN
POST https://api.example.com/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "secret"
}

### GET_PROFILE
GET https://api.example.com/profile
Authorization: Bearer {{LOGIN.response.body.$.token}}
X-User-Id: {{LOGIN.response.body.$.user.id}}
```

**Syntax:** `{{REQUEST_NAME.response.body.$.jsonPath}}`

### Accessing Headers from Previous Requests

```http
### REQUEST_ONE
GET https://httpbin.org/get

### REQUEST_TWO
GET https://httpbin.org/get
X-Previous-Date: {{REQUEST_ONE.response.headers.Date}}
X-Content-Type: {{REQUEST_ONE.response.headers['Content-Type']}}
```

### Accessing Cookies

```http
Cookie: {{REQUEST_ONE.response.cookies.session_id.value}}
```

**Cookie properties:** `value`, `domain`, `flag`, `path`, `secure`, `expires`

---

## Method 2: Post-Request Scripts (Most Powerful)

Use scripts to extract and store values as **global variables** that persist across requests and Neovim sessions.

### Inline JavaScript Script

```http
### LOGIN
POST https://api.example.com/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password"
}

> {%
  // Extract from JSON response
  client.global.set("access_token", response.body.token);
  client.global.set("user_id", response.body.user.id);
  client.global.set("user_email", response.body.user.email);

  // Access nested fields
  client.global.set("profile_name", response.body.user.profile.name);

  // Access arrays
  client.global.set("first_role", response.body.user.roles[0]);

  // Log for debugging
  client.log("Token set: " + response.body.token);
%}

### USE_TOKEN
GET https://api.example.com/protected
Authorization: Bearer {{access_token}}
```

### Inline Lua Script

```http
### LOGIN
POST https://api.example.com/auth/login
Content-Type: application/json

{
  "email": "user@example.com"
}

> {%
  -- Lua syntax
  client.global.set("token", response.body.token)
  client.global.set("user_id", response.body.user.id)

  client.log("Token: " .. response.body.token)
%}
```

### External Script File

**auth.http:**
```http
### LOGIN
POST https://api.example.com/auth/login
Content-Type: application/json

{"email": "user@example.com"}

> ./scripts/extract-token.js
```

**scripts/extract-token.js:**
```javascript
client.global.set("access_token", response.body.token);
client.global.set("refresh_token", response.body.refresh_token);
client.global.set("user_id", response.body.user.id);

console.log("Tokens extracted successfully");
```

---

## Method 3: Pre-Request Scripts

Set variables **before** sending a request:

```http
### PROTECTED_ENDPOINT
< {%
  // Pre-request script
  const timestamp = Date.now();
  request.variables.set("timestamp", timestamp);

  // Or set global
  client.global.set("request_time", timestamp);
%}
GET https://api.example.com/data
X-Request-Time: {{timestamp}}
```

---

## Method 4: External Command with stdin (For Complex Processing)

Use external tools like `jq` to process responses:

```http
### GET_JWT
POST https://api.example.com/auth
Content-Type: application/json

{"username": "user"}

@env-stdin-cmd decoded_claims echo "$stdin" | jq -r '.token' | base64 -d | jq -r '.claims.userId'
```

---

## Client Object Methods

### Variable Management

```javascript
// Set global variable (persists across sessions)
client.global.set("token", "abc123");

// Get global variable
const token = client.global.get("token");

// Clear specific variable
client.clear("token");

// Clear all global variables
client.clearAll();

// Check if globals are empty
if (client.isEmpty()) {
  console.log("No variables set");
}
```

### Request-Scoped Variables (Only in Pre-Request Scripts)

```javascript
// Set request variable (only for current request)
request.variables.set("temp_value", "xyz");
```

### Debugging

```javascript
// Log to Script Output panel
client.log("Token: " + response.body.token);
client.log(response.body);
console.log("Also works!");
```

### Testing

```javascript
// Create test
client.test("Status is 200", function() {
  client.assert(response.responseCode === 200, "Expected 200");
});

// Exit script early
if (response.responseCode !== 200) {
  client.exit();
}
```

---

## Response Object Properties

```javascript
// Status code
response.responseCode  // e.g., 200

// Body (auto-parsed JSON if content-type is JSON)
response.body          // JavaScript object or string
response.body.token    // Access JSON fields
response.body.user.id  // Nested access
response.body.items[0] // Array access

// Headers
response.headers.valueOf("Content-Type")      // Single value
response.headers.valuesOf("Set-Cookie")       // Multiple values (array)
```

---

## Complete Real-World Example

```http
### Variables
@baseUrl=https://api.example.com

### 1. Login and extract token
POST {{baseUrl}}/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "secret123"
}

> {%
  // Extract and store tokens
  client.global.set("access_token", response.body.access_token);
  client.global.set("refresh_token", response.body.refresh_token);
  client.global.set("user_id", response.body.user.id);

  // Log success
  client.log("Login successful. User ID: " + response.body.user.id);

  // Test response
  client.test("Login returns 200", function() {
    client.assert(response.responseCode === 200, "Should be 200");
  });
%}

### 2. Get user profile using stored token
GET {{baseUrl}}/users/{{user_id}}
Authorization: Bearer {{access_token}}

> {%
  // Store profile data
  client.global.set("user_name", response.body.name);
  client.global.set("user_email", response.body.email);
%}

### 3. Update profile
PUT {{baseUrl}}/users/{{user_id}}
Authorization: Bearer {{access_token}}
Content-Type: application/json

{
  "name": "{{user_name}}",
  "bio": "Updated via kulala.nvim"
}

### 4. Get data using reference to previous request (no script needed)
GET {{baseUrl}}/posts
Authorization: Bearer {{1. Login and extract token.response.body.$.access_token}}
```

---

## Clearing Variables from Neovim

```lua
-- In your Neovim config or command line
:lua require('kulala').scripts_clear_global('access_token')

-- Clear all
:lua require('kulala').scripts_clear_global()

-- Clear multiple
:lua require('kulala').scripts_clear_global({'token1', 'token2'})
```

---

## Key Differences Between Methods

| Method | Persistence | Scope | Best For |
|--------|------------|-------|----------|
| Request Variables | No | Current file | Simple references |
| Post-Request Scripts | Yes (saved) | Global | Complex extraction, reusable tokens |
| Pre-Request Scripts | Varies | Request or Global | Dynamic headers, timestamps |
| External Commands | No | N/A | Complex transformations (JWT decode) |

---

## Tips and Best Practices

### 1. Choose the Right Method

- **Simple token extraction?** Use request variables (`{{REQUEST.response.body.$.token}}`)
- **Need persistence across sessions?** Use post-request scripts with `client.global.set()`
- **Complex JSON manipulation?** Use external commands with `jq`

### 2. Debugging Scripts

```javascript
// Always log extracted values for debugging
> {%
  const token = response.body.token;
  client.log("Extracted token: " + token);
  client.global.set("token", token);
%}
```

### 3. Error Handling

```javascript
> {%
  if (response.responseCode !== 200) {
    client.log("Login failed with status: " + response.responseCode);
    client.exit();
  }

  if (!response.body.token) {
    client.log("No token in response!");
    client.exit();
  }

  client.global.set("token", response.body.token);
%}
```

### 4. Working with Different Content Types

```javascript
> {%
  // JSON (auto-parsed)
  const jsonData = response.body.field;

  // Plain text (string)
  const textData = response.body;

  // Parse manually if needed
  const parsed = JSON.parse(response.body);
%}
```

### 5. Script File Organization

Organize external scripts by functionality:

```
project/
├── api/
│   ├── auth.http
│   ├── users.http
│   └── posts.http
└── scripts/
    ├── auth/
    │   ├── extract-token.js
    │   └── refresh-token.js
    └── common/
        └── utils.js
```

### 6. Node.js Module Support

You can use Node.js modules in external scripts:

```javascript
// scripts/extract-token.js
const jwt = require('jsonwebtoken');

const token = response.body.token;
const decoded = jwt.decode(token);

client.global.set("access_token", token);
client.global.set("user_id", decoded.sub);
client.global.set("token_expires", decoded.exp);

console.log("Token expires at:", new Date(decoded.exp * 1000));
```

---

## Troubleshooting

### Variable Not Found

If you see `{{variable}}` in the actual request:

1. **For request variables:** Make sure you executed the named request first
2. **For global variables:** Check the variable name matches exactly (case-sensitive)
3. **Check spelling:** `client.global.set("token", ...)` → use `{{token}}` not `{{access_token}}`

### Script Not Running

1. **JavaScript scripts:** Ensure Node.js is installed
2. **Check syntax:** Look for syntax errors in inline scripts
3. **File paths:** External scripts use relative paths from the script's directory
4. **Language mixing:** First script determines language (JS or Lua) for all scripts in request

### Response Body is String Not Object

```javascript
// If response.body is a string, parse it manually
> {%
  const data = JSON.parse(response.body);
  client.global.set("token", data.token);
%}
```

### JSONPath Not Working

```http
# Wrong: Missing the $ prefix
{{LOGIN.response.body.token}}

# Correct: Use $ for JSONPath
{{LOGIN.response.body.$.token}}
```

---

## Sources

- [Kulala.nvim Usage Documentation](https://neovim.getkulala.net/docs/usage)
- [Request Variables](https://neovim.getkulala.net/docs/usage/request-variables)
- [Dynamically Setting Environment Variables from JSON](https://neovim.getkulala.net/docs/usage/dynamically-setting-environment-variables-based-on-response-json)
- [Dynamically Setting Environment Variables from Headers](https://neovim.getkulala.net/docs/usage/dynamically-setting-environment-variables-based-on-headers)
- [Scripts Overview](https://neovim.getkulala.net/docs/scripts/overview)
- [Client Reference](https://neovim.getkulala.net/docs/scripts/client-reference)
- [Response Reference](https://neovim.getkulala.net/docs/scripts/response-reference)
- [IntelliJ IDEA HTTP Response Handling Examples](https://www.jetbrains.com/help/idea/http-response-handling-examples.html)
- [IntelliJ IDEA HTTP Client Variables Documentation](https://www.jetbrains.com/help/idea/http-client-variables.html)
