return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        sources = {
          explorer = {
            hidden = true,
            ignored = true,
            exclude = { "node_modules" },
          },
          files = {
            hidden = true,
          },
        },
      },
    },
  },
}
