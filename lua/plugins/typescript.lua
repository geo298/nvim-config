-- TypeScript/JavaScript support for LazyVim.
--
-- This is intentionally configured here instead of importing LazyVim's
-- lang.typescript extra: that extra enables vtsls by default, while this
-- configuration uses typescript-tools.nvim directly.

local typescript_filetypes = {
  "javascript",
  "javascriptreact",
  "typescript",
  "typescriptreact",
}

return {
  {
    "pmizio/typescript-tools.nvim",
    dependencies = {
      -- Already present in this LazyVim installation, but required by the
      -- plugin and therefore declared here for lazy.nvim's dependency graph.
      "nvim-lua/plenary.nvim",
      "neovim/nvim-lspconfig",
    },
    opts = function()
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      local ok, blink = pcall(require, "blink.cmp")
      if ok then
        capabilities = blink.get_lsp_capabilities(capabilities)
      end

      return {
        capabilities = capabilities,
        filetypes = typescript_filetypes,
        on_attach = function(_, buffer)
          local function map(lhs, rhs, desc)
            vim.keymap.set("n", lhs, rhs, { buffer = buffer, desc = desc, silent = true })
          end

          -- LazyVim already provides the usual gd/gr/K/rename/code-action
          -- mappings. These are TypeScript-tools-specific commands that are
          -- useful enough to expose directly as well.
          map("gR", "<cmd>TSToolsFileReferences<cr>", "File References")
          map("gS", "<cmd>TSToolsGoToSourceDefinition<cr>", "Goto Source Definition")
          map("<leader>cM", "<cmd>TSToolsAddMissingImports<cr>", "Add Missing Imports")
          map("<leader>cN", "<cmd>TSToolsRenameFile<cr>", "Rename TypeScript File")
          map("<leader>cX", "<cmd>TSToolsFixAll<cr>", "Fix All TypeScript Diagnostics")
        end,
        settings = {
          -- Keep diagnostics slightly less noisy while typing. TypeScript
          -- still reports them on insert leave and save.
          separate_diagnostic_server = true,
          publish_diagnostic_on = "insert_leave",

          -- Make TypeScript's source actions available through normal LSP
          -- code actions as well as the TSTools* commands.
          expose_as_code_action = "all",

          -- Use the workspace's TypeScript installation when available.
          -- Your Astro project currently provides TypeScript 6.0.3 locally.
          tsserver_path = nil,
          tsserver_max_memory = "auto",

          -- Match the useful parts of VS Code's TypeScript experience.
          complete_function_calls = true,
          include_completions_with_insert_text = true,
          code_lens = "off",

          tsserver_file_preferences = {
            includeInlayParameterNameHints = "literals",
            includeInlayParameterNameHintsWhenArgumentMatchesName = false,
            includeInlayFunctionParameterTypeHints = true,
            includeInlayFunctionLikeReturnTypeHints = true,
            includeInlayVariableTypeHints = false,
            includeInlayPropertyDeclarationTypeHints = true,
            includeInlayEnumMemberValueHints = true,
            includeCompletionsForModuleExports = true,
            quotePreference = "auto",
          },
          tsserver_format_options = {
            allowIncompleteCompletions = false,
            allowRenameOfImportPath = true,
          },

          -- LazyVim already installs nvim-ts-autotag, so leave this feature
          -- disabled to avoid two plugins inserting closing JSX tags.
          jsx_close_tag = {
            enable = false,
            filetypes = { "javascriptreact", "typescriptreact" },
          },
        },
      }
    end,
  },

  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.servers = opts.servers or {}

      -- Astro needs its own language server for .astro files. We configure it
      -- directly instead of importing LazyVim's Astro extra, because that
      -- extra also imports and enables vtsls.
      opts.servers.astro = type(opts.servers.astro) == "table" and opts.servers.astro or {}
      opts.servers.astro.enabled = true
      -- Use the project's node_modules/.bin/astro-ls instead of waiting for
      -- Mason to install another copy.
      opts.servers.astro.mason = false

      -- Ensure no second TypeScript server attaches if another LazyVim extra
      -- is enabled later or leaves a server in the merged options.
      for _, server in ipairs({ "tsserver", "ts_ls", "vtsls", "tsgo", "tsc" }) do
        opts.servers[server] = type(opts.servers[server]) == "table" and opts.servers[server] or {}
        opts.servers[server].enabled = false
      end
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      for _, parser in ipairs({ "astro", "css" }) do
        if not vim.tbl_contains(opts.ensure_installed, parser) then
          table.insert(opts.ensure_installed, parser)
        end
      end
    end,
  },

  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}

      -- Use the project's local Prettier when it is available. Existing
      -- formatter choices win, so this will not fight a future Biome/Oxlint
      -- setup or a LazyVim formatting extra.
      for _, filetype in ipairs({
        "javascript",
        "javascriptreact",
        "typescript",
        "typescriptreact",
        "json",
        "jsonc",
        "css",
        "scss",
        "html",
      }) do
        opts.formatters_by_ft[filetype] = opts.formatters_by_ft[filetype] or { "prettier" }
      end

      -- This project has no prettier-plugin-astro. Leave Astro without an
      -- external formatter so LazyVim's global lsp_format fallback uses the
      -- project-local Astro language server, which supports formatting.
    end,
  },

  {
    "mfussenegger/nvim-lint",
    opts = function(_, opts)
      opts.linters_by_ft = opts.linters_by_ft or {}
      opts.linters = opts.linters or {}

      -- The current project does not have ESLint installed, so the condition
      -- keeps nvim-lint quiet now while making ESLint work automatically if a
      -- project-local or global installation is added later.
      opts.linters.eslint = vim.tbl_deep_extend("force", opts.linters.eslint or {}, {
        condition = function(ctx)
          local local_binary = vim.fs.find("node_modules/.bin/eslint", {
            path = ctx.dirname,
            upward = true,
            type = "file",
          })[1]
          return local_binary ~= nil or vim.fn.executable("eslint") == 1
        end,
      })

      for _, filetype in ipairs({
        "javascript",
        "javascriptreact",
        "typescript",
        "typescriptreact",
      }) do
        opts.linters_by_ft[filetype] = opts.linters_by_ft[filetype] or { "eslint" }
      end
    end,
  },
}
