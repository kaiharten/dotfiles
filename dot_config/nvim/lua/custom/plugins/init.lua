-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
return {
  {
    'neoclide/coc.nvim',
    branch = 'release',
    config = function()
      vim.cmd 'CocInstall coc-clangd'
    end,
  },
  -- TOOLING: COMPLETION, DIAGNOSTICS, FORMATTING
}
