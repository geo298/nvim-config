local jest_config_names = {
  "jest.config.js",
  "jest.config.ts",
  "jest.config.mjs",
  "jest.config.cjs",
  "jest.config.mts",
  "jest.config.cts",
}

local function find_jest_config(path)
  return vim.fs.find(jest_config_names, { path = vim.fs.dirname(path), upward = true, type = "file" })[1]
end

return {
  {
    "nvim-neotest/neotest",
    dependencies = { "nvim-neotest/neotest-jest" },
    opts = {
      adapters = {
        ["neotest-jest"] = {
          -- neotest-jest only detects jest.config.{js,ts} by default.
          jestConfigFile = function(path)
            return find_jest_config(path)
          end,
          cwd = function(path)
            local config = find_jest_config(path)
            return config and vim.fs.dirname(config) or vim.fs.root(path, "package.json")
          end,
        },
      },
    },
  },
}
