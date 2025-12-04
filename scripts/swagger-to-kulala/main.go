package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"

	"gopkg.in/yaml.v3"
)

// StringOrArray handles fields that can be either a string or an array of strings
type StringOrArray []string

func (s *StringOrArray) UnmarshalYAML(value *yaml.Node) error {
	var multi []string
	if err := value.Decode(&multi); err == nil {
		*s = multi
		return nil
	}

	var single string
	if err := value.Decode(&single); err == nil {
		*s = []string{single}
		return nil
	}

	return fmt.Errorf("field must be a string or array of strings")
}

func (s StringOrArray) First() string {
	if len(s) > 0 {
		return s[0]
	}
	return ""
}

// OpenAPI/Swagger structures
type OpenAPISpec struct {
	OpenAPI            string                       `yaml:"openapi" json:"openapi"`
	Swagger            string                       `yaml:"swagger" json:"swagger"`
	Info               Info                         `yaml:"info" json:"info"`
	Servers            []Server                     `yaml:"servers" json:"servers"`
	Host               string                       `yaml:"host" json:"host"`
	BasePath           string                       `yaml:"basePath" json:"basePath"`
	Schemes            []string                     `yaml:"schemes" json:"schemes"`
	Paths              map[string]PathItem          `yaml:"paths" json:"paths"`
	Components         *Components                  `yaml:"components,omitempty" json:"components,omitempty"`
	SecurityDefinitions map[string]SecurityScheme   `yaml:"securityDefinitions,omitempty" json:"securityDefinitions,omitempty"`
	Security           []map[string][]string        `yaml:"security,omitempty" json:"security,omitempty"`
}

type Info struct {
	Title       string `yaml:"title" json:"title"`
	Version     string `yaml:"version" json:"version"`
	Description string `yaml:"description,omitempty" json:"description,omitempty"`
}

type Server struct {
	URL         string `yaml:"url" json:"url"`
	Description string `yaml:"description,omitempty" json:"description,omitempty"`
}

type PathItem struct {
	Get    *Operation `yaml:"get,omitempty" json:"get,omitempty"`
	Post   *Operation `yaml:"post,omitempty" json:"post,omitempty"`
	Put    *Operation `yaml:"put,omitempty" json:"put,omitempty"`
	Patch  *Operation `yaml:"patch,omitempty" json:"patch,omitempty"`
	Delete *Operation `yaml:"delete,omitempty" json:"delete,omitempty"`
	Head   *Operation `yaml:"head,omitempty" json:"head,omitempty"`
	Options *Operation `yaml:"options,omitempty" json:"options,omitempty"`
}

type Operation struct {
	Summary     string                `yaml:"summary,omitempty" json:"summary,omitempty"`
	Description string                `yaml:"description,omitempty" json:"description,omitempty"`
	OperationID string                `yaml:"operationId,omitempty" json:"operationId,omitempty"`
	Tags        []string              `yaml:"tags,omitempty" json:"tags,omitempty"`
	Parameters  []Parameter           `yaml:"parameters,omitempty" json:"parameters,omitempty"`
	RequestBody *RequestBody          `yaml:"requestBody,omitempty" json:"requestBody,omitempty"`
	Security    []map[string][]string `yaml:"security,omitempty" json:"security,omitempty"`
	Consumes    []string              `yaml:"consumes,omitempty" json:"consumes,omitempty"`
}

type Parameter struct {
	Name        string        `yaml:"name" json:"name"`
	In          string        `yaml:"in" json:"in"`
	Required    bool          `yaml:"required,omitempty" json:"required,omitempty"`
	Description string        `yaml:"description,omitempty" json:"description,omitempty"`
	Schema      *Schema       `yaml:"schema,omitempty" json:"schema,omitempty"`
	Type        StringOrArray `yaml:"type,omitempty" json:"type,omitempty"`
	Example     interface{}   `yaml:"example,omitempty" json:"example,omitempty"`
	Default     interface{}   `yaml:"default,omitempty" json:"default,omitempty"`
}

type RequestBody struct {
	Description string                `yaml:"description,omitempty" json:"description,omitempty"`
	Required    bool                  `yaml:"required,omitempty" json:"required,omitempty"`
	Content     map[string]MediaType  `yaml:"content,omitempty" json:"content,omitempty"`
}

type MediaType struct {
	Schema  *Schema     `yaml:"schema,omitempty" json:"schema,omitempty"`
	Example interface{} `yaml:"example,omitempty" json:"example,omitempty"`
}

type Schema struct {
	Type       StringOrArray       `yaml:"type,omitempty" json:"type,omitempty"`
	Format     string              `yaml:"format,omitempty" json:"format,omitempty"`
	Properties map[string]*Schema  `yaml:"properties,omitempty" json:"properties,omitempty"`
	Items      *Schema             `yaml:"items,omitempty" json:"items,omitempty"`
	Required   []string            `yaml:"required,omitempty" json:"required,omitempty"`
	Example    interface{}         `yaml:"example,omitempty" json:"example,omitempty"`
	Enum       []interface{}       `yaml:"enum,omitempty" json:"enum,omitempty"`
	Ref        string              `yaml:"$ref,omitempty" json:"$ref,omitempty"`
}

type Components struct {
	Schemas         map[string]*Schema        `yaml:"schemas,omitempty" json:"schemas,omitempty"`
	SecuritySchemes map[string]SecurityScheme `yaml:"securitySchemes,omitempty" json:"securitySchemes,omitempty"`
}

type SecurityScheme struct {
	Type   string `yaml:"type" json:"type"`
	Scheme string `yaml:"scheme,omitempty" json:"scheme,omitempty"`
	In     string `yaml:"in,omitempty" json:"in,omitempty"`
	Name   string `yaml:"name,omitempty" json:"name,omitempty"`
}

// Converter
type Converter struct {
	spec     *OpenAPISpec
	baseURL  string
	security map[string]SecurityScheme
}

func NewConverter(spec *OpenAPISpec) *Converter {
	c := &Converter{
		spec:     spec,
		security: make(map[string]SecurityScheme),
	}

	// Extract base URL
	if spec.OpenAPI != "" {
		// OpenAPI 3.x
		if len(spec.Servers) > 0 {
			c.baseURL = spec.Servers[0].URL
		} else {
			c.baseURL = "http://localhost"
		}
		if spec.Components != nil && spec.Components.SecuritySchemes != nil {
			c.security = spec.Components.SecuritySchemes
		}
	} else {
		// Swagger 2.0
		scheme := "https"
		if len(spec.Schemes) > 0 {
			scheme = spec.Schemes[0]
		}
		host := spec.Host
		if host == "" {
			host = "localhost"
		}
		c.baseURL = fmt.Sprintf("%s://%s%s", scheme, host, spec.BasePath)
		if spec.SecurityDefinitions != nil {
			c.security = spec.SecurityDefinitions
		}
	}

	return c
}

func (c *Converter) Convert(splitByTag bool) map[string]string {
	if splitByTag {
		return c.convertSplitByTag()
	}
	return map[string]string{
		"api.http": c.convertSingleFile(),
	}
}

func (c *Converter) convertSingleFile() string {
	var b strings.Builder

	// Header
	b.WriteString(fmt.Sprintf("# %s - v%s\n", c.spec.Info.Title, c.spec.Info.Version))
	if c.spec.Info.Description != "" {
		b.WriteString(fmt.Sprintf("# %s\n", c.spec.Info.Description))
	}
	b.WriteString("\n")

	// Variables
	b.WriteString("# Variables\n")
	b.WriteString(fmt.Sprintf("@baseUrl=%s\n", c.baseURL))
	if len(c.security) > 0 {
		b.WriteString("@token=your_token_here\n")
		b.WriteString("@api_key=your_api_key_here\n")
	}
	b.WriteString("\n")

	// Process all paths
	for path, pathItem := range c.spec.Paths {
		operations := c.getOperations(pathItem)
		for method, op := range operations {
			b.WriteString(c.generateHTTPRequest(method, path, op))
			b.WriteString("\n")
		}
	}

	return b.String()
}

func (c *Converter) convertSplitByTag() map[string]string {
	files := make(map[string]string)
	byTag := make(map[string][]struct {
		method string
		path   string
		op     *Operation
	})
	var untagged []struct {
		method string
		path   string
		op     *Operation
	}

	// Group by tags
	for path, pathItem := range c.spec.Paths {
		operations := c.getOperations(pathItem)
		for method, op := range operations {
			if len(op.Tags) > 0 {
				tag := op.Tags[0]
				byTag[tag] = append(byTag[tag], struct {
					method string
					path   string
					op     *Operation
				}{method, path, op})
			} else {
				untagged = append(untagged, struct {
					method string
					path   string
					op     *Operation
				}{method, path, op})
			}
		}
	}

	// Generate files for each tag
	for tag, endpoints := range byTag {
		filename := strings.ReplaceAll(strings.ToLower(tag), " ", "_") + ".http"
		files[filename] = c.generateTaggedFile(tag, endpoints)
	}

	// Generate file for untagged
	if len(untagged) > 0 {
		files["untagged.http"] = c.generateTaggedFile("Untagged", untagged)
	}

	return files
}

func (c *Converter) generateTaggedFile(tag string, endpoints []struct {
	method string
	path   string
	op     *Operation
}) string {
	var b strings.Builder

	b.WriteString(fmt.Sprintf("# %s - %s\n\n", c.spec.Info.Title, tag))

	// Variables
	b.WriteString("# Variables\n")
	b.WriteString(fmt.Sprintf("@baseUrl=%s\n", c.baseURL))
	if len(c.security) > 0 {
		b.WriteString("@token=your_token_here\n")
		b.WriteString("@api_key=your_api_key_here\n")
	}
	b.WriteString("\n")

	for _, e := range endpoints {
		b.WriteString(c.generateHTTPRequest(e.method, e.path, e.op))
		b.WriteString("\n")
	}

	return b.String()
}

func (c *Converter) generateHTTPRequest(method, path string, op *Operation) string {
	var b strings.Builder

	// Comment
	b.WriteString("###\n")
	if op.Summary != "" {
		b.WriteString(fmt.Sprintf("# %s\n", op.Summary))
	}
	if op.Description != "" && op.Description != op.Summary {
		b.WriteString(fmt.Sprintf("# %s\n", op.Description))
	}
	if op.OperationID != "" {
		b.WriteString(fmt.Sprintf("# Operation ID: %s\n", op.OperationID))
	}

	// Parameters
	pathParams := make(map[string]Parameter)
	var queryParams []Parameter
	var headerParams []Parameter

	for _, param := range op.Parameters {
		switch param.In {
		case "path":
			pathParams[param.Name] = param
		case "query":
			queryParams = append(queryParams, param)
		case "header":
			headerParams = append(headerParams, param)
		}
	}

	// Build URL
	urlPath := path
	for name, param := range pathParams {
		placeholder := fmt.Sprintf("{%s}", name)
		value := c.getExampleValue(param)
		urlPath = strings.ReplaceAll(urlPath, placeholder, value)
	}

	// Add query string
	if len(queryParams) > 0 {
		var queryParts []string
		for _, param := range queryParams {
			value := c.getExampleValue(param)
			queryParts = append(queryParts, fmt.Sprintf("%s=%s", param.Name, value))
		}
		urlPath = urlPath + "?" + strings.Join(queryParts, "&")
	}

	// Request line
	b.WriteString(fmt.Sprintf("%s {{baseUrl}}%s\n", method, urlPath))

	// Headers
	var headers []string

	// Security headers
	headers = append(headers, c.generateSecurityHeaders(op)...)

	// Custom headers
	for _, param := range headerParams {
		value := c.getExampleValue(param)
		headers = append(headers, fmt.Sprintf("%s: %s", param.Name, value))
	}

	// Content-Type for body requests
	if method == "POST" || method == "PUT" || method == "PATCH" {
		contentType := c.getContentType(op)
		hasContentType := false
		for _, h := range headers {
			if strings.HasPrefix(strings.ToLower(h), "content-type:") {
				hasContentType = true
				break
			}
		}
		if !hasContentType {
			headers = append(headers, fmt.Sprintf("Content-Type: %s", contentType))
		}
	}

	for _, header := range headers {
		b.WriteString(header + "\n")
	}

	// Request body
	if method == "POST" || method == "PUT" || method == "PATCH" {
		if body := c.getRequestBody(op); body != "" {
			b.WriteString("\n")
			b.WriteString(body)
		}
	}

	return b.String()
}

func (c *Converter) getOperations(pathItem PathItem) map[string]*Operation {
	ops := make(map[string]*Operation)
	if pathItem.Get != nil {
		ops["GET"] = pathItem.Get
	}
	if pathItem.Post != nil {
		ops["POST"] = pathItem.Post
	}
	if pathItem.Put != nil {
		ops["PUT"] = pathItem.Put
	}
	if pathItem.Patch != nil {
		ops["PATCH"] = pathItem.Patch
	}
	if pathItem.Delete != nil {
		ops["DELETE"] = pathItem.Delete
	}
	if pathItem.Head != nil {
		ops["HEAD"] = pathItem.Head
	}
	if pathItem.Options != nil {
		ops["OPTIONS"] = pathItem.Options
	}
	return ops
}

func (c *Converter) getExampleValue(param Parameter) string {
	if param.Example != nil {
		return fmt.Sprintf("%v", param.Example)
	}
	if param.Default != nil {
		return fmt.Sprintf("%v", param.Default)
	}

	// Generate based on type
	paramType := param.Type.First()
	if param.Schema != nil {
		paramType = param.Schema.Type.First()
	}

	switch paramType {
	case "integer":
		return "0"
	case "number":
		return "0.0"
	case "boolean":
		return "true"
	case "string":
		if param.Schema != nil {
			switch param.Schema.Format {
			case "date":
				return "2024-01-01"
			case "date-time":
				return "2024-01-01T00:00:00Z"
			case "email":
				return "user@example.com"
			case "uuid":
				return "123e4567-e89b-12d3-a456-426614174000"
			}
			if len(param.Schema.Enum) > 0 {
				return fmt.Sprintf("%v", param.Schema.Enum[0])
			}
		}
		return "value"
	default:
		return "value"
	}
}

func (c *Converter) generateSecurityHeaders(op *Operation) []string {
	var headers []string

	security := op.Security
	if len(security) == 0 {
		security = c.spec.Security
	}

	for _, secReq := range security {
		for secName := range secReq {
			secDef, ok := c.security[secName]
			if !ok {
				continue
			}

			switch secDef.Type {
			case "apiKey":
				if secDef.In == "header" {
					headers = append(headers, fmt.Sprintf("%s: {{api_key}}", secDef.Name))
				}
			case "http":
				if strings.ToLower(secDef.Scheme) == "bearer" {
					headers = append(headers, "Authorization: Bearer {{token}}")
				} else if strings.ToLower(secDef.Scheme) == "basic" {
					headers = append(headers, "Authorization: Basic {{base64_credentials}}")
				}
			case "oauth2", "openIdConnect":
				headers = append(headers, "Authorization: Bearer {{access_token}}")
			}
		}
	}

	return headers
}

func (c *Converter) getContentType(op *Operation) string {
	// OpenAPI 3.x
	if op.RequestBody != nil && op.RequestBody.Content != nil {
		if _, ok := op.RequestBody.Content["application/json"]; ok {
			return "application/json"
		}
		for ct := range op.RequestBody.Content {
			return ct
		}
	}

	// Swagger 2.0
	if len(op.Consumes) > 0 {
		return op.Consumes[0]
	}

	return "application/json"
}

func (c *Converter) getRequestBody(op *Operation) string {
	var schema *Schema

	// OpenAPI 3.x
	if op.RequestBody != nil && op.RequestBody.Content != nil {
		for _, media := range op.RequestBody.Content {
			if media.Schema != nil {
				schema = media.Schema
				break
			}
		}
	}

	// Swagger 2.0
	for _, param := range op.Parameters {
		if param.In == "body" && param.Schema != nil {
			schema = param.Schema
			break
		}
	}

	if schema == nil {
		return ""
	}

	example := c.getSchemaExample(schema)
	jsonBytes, err := json.MarshalIndent(example, "", "  ")
	if err != nil {
		return "{}"
	}

	return string(jsonBytes)
}

func (c *Converter) resolveSchema(schema *Schema) *Schema {
	if schema == nil {
		return nil
	}

	// Resolve $ref
	if schema.Ref != "" {
		return c.resolveSchemaRef(schema.Ref)
	}

	return schema
}

func (c *Converter) resolveSchemaRef(ref string) *Schema {
	if !strings.HasPrefix(ref, "#/components/schemas/") {
		return nil
	}

	schemaName := strings.TrimPrefix(ref, "#/components/schemas/")
	if c.spec.Components != nil && c.spec.Components.Schemas != nil {
		if schema, ok := c.spec.Components.Schemas[schemaName]; ok {
			return schema
		}
	}

	return nil
}

func (c *Converter) getSchemaExample(schema *Schema) interface{} {
	if schema == nil {
		return nil
	}

	// Resolve refs first
	schema = c.resolveSchema(schema)
	if schema == nil {
		return nil
	}

	if schema.Example != nil {
		return schema.Example
	}

	switch schema.Type.First() {
	case "string":
		switch schema.Format {
		case "date":
			return "2024-01-01"
		case "date-time":
			return "2024-01-01T00:00:00Z"
		case "email":
			return "user@example.com"
		case "uuid":
			return "123e4567-e89b-12d3-a456-426614174000"
		default:
			if len(schema.Enum) > 0 {
				return schema.Enum[0]
			}
			return "string"
		}
	case "integer":
		return 0
	case "number":
		return 0.0
	case "boolean":
		return true
	case "array":
		if schema.Items != nil {
			return []interface{}{c.getSchemaExample(schema.Items)}
		}
		return []interface{}{}
	case "object":
		obj := make(map[string]interface{})
		for propName, propSchema := range schema.Properties {
			obj[propName] = c.getSchemaExample(propSchema)
		}
		return obj
	default:
		return nil
	}
}

func main() {
	var (
		inputFile  = flag.String("i", "", "Input Swagger/OpenAPI YAML file (required)")
		outputFile = flag.String("o", "", "Output HTTP file (default: stdout)")
		splitByTag = flag.Bool("split", false, "Split output into multiple files by tag")
	)

	flag.Usage = func() {
		fmt.Fprintf(os.Stderr, "Usage: %s -i <input.yaml> [-o <output.http>] [-split]\n\n", os.Args[0])
		fmt.Fprintf(os.Stderr, "Convert Swagger/OpenAPI YAML specs to kulala.nvim HTTP files\n\n")
		fmt.Fprintf(os.Stderr, "Options:\n")
		flag.PrintDefaults()
		fmt.Fprintf(os.Stderr, "\nExamples:\n")
		fmt.Fprintf(os.Stderr, "  %s -i api.yaml                 # Output to stdout\n", os.Args[0])
		fmt.Fprintf(os.Stderr, "  %s -i api.yaml -o api.http    # Output to file\n", os.Args[0])
		fmt.Fprintf(os.Stderr, "  %s -i api.yaml -split         # Create multiple files by tag\n", os.Args[0])
	}

	flag.Parse()

	if *inputFile == "" {
		flag.Usage()
		os.Exit(1)
	}

	// Read input file
	data, err := os.ReadFile(*inputFile)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error reading file: %v\n", err)
		os.Exit(1)
	}

	// Parse YAML
	var spec OpenAPISpec
	if err := yaml.Unmarshal(data, &spec); err != nil {
		fmt.Fprintf(os.Stderr, "Error parsing YAML: %v\n", err)
		os.Exit(1)
	}

	// Convert
	converter := NewConverter(&spec)
	results := converter.Convert(*splitByTag)

	// Output
	if *splitByTag {
		outputDir := "."
		if *outputFile != "" {
			outputDir = *outputFile
		}

		if err := os.MkdirAll(outputDir, 0755); err != nil {
			fmt.Fprintf(os.Stderr, "Error creating directory: %v\n", err)
			os.Exit(1)
		}

		for filename, content := range results {
			outputPath := filepath.Join(outputDir, filename)
			if err := os.WriteFile(outputPath, []byte(content), 0644); err != nil {
				fmt.Fprintf(os.Stderr, "Error writing file %s: %v\n", outputPath, err)
				os.Exit(1)
			}
			fmt.Printf("Created: %s\n", outputPath)
		}
	} else {
		content := results["api.http"]
		if *outputFile != "" {
			if err := os.WriteFile(*outputFile, []byte(content), 0644); err != nil {
				fmt.Fprintf(os.Stderr, "Error writing file: %v\n", err)
				os.Exit(1)
			}
			fmt.Printf("Created: %s\n", *outputFile)
		} else {
			io.WriteString(os.Stdout, content)
		}
	}
}
