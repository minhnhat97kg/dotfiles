-- Lightweight Go LSP configuration for SSH
-- Reduces analyses from 70+ to ~10 essential ones for performance

return {
	cmd = { "gopls" },
	filetypes = { "go", "gomod", "gowork", "gotmpl", "gosum" },
	root_markers = { "go.mod", "go.work", ".git" },
	settings = {
		gopls = {
			gofumpt = true,

			-- Minimal codelenses (only essential ones)
			codelenses = {
				gc_details = false,
				generate = false,
				regenerate_cgo = false,
				run_govulncheck = false,
				test = false,
				tidy = false,
				upgrade_dependency = false,
				vendor = false,
			},

			-- Disable all hints (causes visual overhead)
			hints = {
				assignVariableTypes = false,
				compositeLiteralFields = false,
				compositeLiteralTypes = false,
				constantValues = false,
				functionTypeParameters = false,
				parameterNames = false,
				rangeVariableTypes = false,
			},

			-- MINIMAL analyses (only critical errors)
			-- Reduced from 70+ to 10 essential checks
			analyses = {
				-- Critical error detection only
				nilness = true, -- Nil pointer errors
				unusedparams = false,
				unusedwrite = false,
				useany = false,
				unreachable = false,
				modernize = false,
				stylecheck = false,
				appends = true, -- Array append errors
				assign = true, -- Assignment errors
				atomic = true, -- Atomic operation errors
				bools = false,
				buildtag = false,
				cgocall = false,
				composite = false,
				contextcheck = false,
				deba = false,
				atomicalign = false,
				composites = false,
				copylocks = true, -- Lock copying errors
				deepequalerrors = false,
				defers = false,
				deprecated = false,
				directive = false,
				embed = false,
				errorsas = false,
				fillreturns = false,
				framepointer = false,
				gofix = false,
				hostport = false,
				infertypeargs = false,
				lostcancel = false,
				httpresponse = false,
				ifaceassert = false,
				loopclosure = false,
				nilfunc = false,
				nonewvars = false,
				noresultvalues = false,
				printf = true, -- Printf format errors
				shadow = false,
				shift = false,
				sigchanyzer = false,
				simplifycompositelit = false,
				simplifyrange = false,
				simplifyslice = false,
				slog = false,
				sortslice = false,
				stdmethods = false,
				stdversion = false,
				stringintconv = false,
				structtag = true, -- Struct tag errors
				testinggoroutine = false,
				tests = false,
				timeformat = false,
				unmarshal = false,
				unsafeptr = false,
				unusedfunc = false,
				unusedresult = false,
				waitgroup = false,
				yield = false,
				unusedvariable = false,
			},

			usePlaceholders = true,
			completeUnimported = false, -- Disable for performance
			staticcheck = false, -- Disable heavy static analysis
			directoryFilters = { "-.git", "-.vscode", "-.idea", "-.vscode-test", "-node_modules" },
			semanticTokens = false, -- Disable semantic tokens (heavy over SSH)
		},
	},
}
