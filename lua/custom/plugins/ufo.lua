local ftMap = {
  vim = 'indent',
  python = { 'indent' },
  git = '',
}

local function custom_selector_handler(bufnr)
  local function handleFallbackException(err, providerName)
    if type(err) == 'string' and err:match 'UfoFallbackException' then
      return require('ufo').getFolds(bufnr, providerName)
    else
      return require('promise').reject(err)
    end
  end

  return require('ufo')
    .getFolds(bufnr, 'lsp')
    :catch(function(err)
      return handleFallbackException(err, 'treesitter')
    end)
    :catch(function(err)
      return handleFallbackException(err, 'indent')
    end)
end

local function custom_virt_text_handler(virtText, lnum, endLnum, width, truncate)
  local newVirtText = {}
  local suffix = ('  %d'):format(endLnum - lnum)
  local sufWidth = vim.fn.strdisplaywidth(suffix)
  local targetWidth = width - sufWidth
  local curWidth = 0
  for _, chunk in ipairs(virtText) do
    local chunkText = chunk[1]
    local chunkWidth = vim.fn.strdisplaywidth(chunkText)
    if targetWidth > curWidth + chunkWidth then
      table.insert(newVirtText, chunk)
    else
      chunkText = truncate(chunkText, targetWidth - curWidth)
      local hlGroup = chunk[2]
      table.insert(newVirtText, { chunkText, hlGroup })
      chunkWidth = vim.fn.strdisplaywidth(chunkText)
      if curWidth + chunkWidth < targetWidth then
        suffix = suffix .. (' '):rep(targetWidth - curWidth - chunkWidth)
      end
      break
    end
    curWidth = curWidth + chunkWidth
  end
  table.insert(newVirtText, { suffix, 'Comment' })
  return newVirtText
end

return {
  'kevinhwang91/nvim-ufo',
  event = 'BufRead',
  dependencies = {
    'kevinhwang91/promise-async',
  },
  opts = function(_, opts)
    vim.o.foldcolumn = '1'
    vim.o.foldlevel = 99
    vim.o.foldlevelstart = 99
    vim.o.foldenable = true
    vim.o.fillchars = [[eob: ,fold: ,foldopen:⏷,foldsep: ,foldclose:⏵]]

    opts.preview = {
      win_config = {
        border = 'rounded',
        winhighlight = 'Normal:Folded',
        winblend = 0,
      },
      mappings = {
        scrollU = '<C-u>',
        scrollD = '<C-d>',
        jumpTop = '[',
        jumpBot = ']',
      },
    }

    -- Custom fold virtual text, which shows number of folded lines
    opts.fold_virt_text_handler = custom_virt_text_handler

    -- Custom provider selector which should go lsp->treesitter->indent
    opts.provider_selector = function(_, filetype, _)
      return ftMap[filetype] or custom_selector_handler
    end
  end,
  keys = {
    {
      'zR',
      function()
        require('ufo').openAllFolds()
      end,
      desc = 'Open all folds',
    },
    {
      'zM',
      function()
        require('ufo').closeAllFolds()
      end,
      desc = 'Close all folds',
    },
    {
      'zK',
      function()
        local winid = require('ufo').peekFoldedLinesUnderCursor()
        if not winid then
          vim.lsp.buf.hover()
        end
      end,
    },
  },
}
-- return {
--   'kevinhwang91/nvim-ufo',
--   dependencies = {
--     'kevinhwang91/promise-async',
--     -- {
--     --   'luukvbaal/statuscol.nvim',
--     --   config = function()
--     --     local builtin = require 'statuscol.builtin'
--     --     require('statuscol').setup {
--     --       relculright = true,
--     --       segments = {
--     --         { text = { builtin.foldfunc }, click = 'v:lua.ScFa' },
--     --         { text = { '%s' }, click = 'v:lua.ScSa' },
--     --         { text = { builtin.lnumfunc, ' ' }, click = 'v:lua.ScLa' },
--     --       },
--     --     }
--     --   end,
--     -- },
--   },
--   event = 'BufRead',
--   keys = {
--     {
--       'zR',
--       function()
--         require('ufo').openAllFolds()
--       end,
--     },
--     {
--       'zM',
--       function()
--         require('ufo').closeAllFolds()
--       end,
--     },
--     {
--       'zK',
--       function()
--         local winid = require('ufo').peekFoldedLinesUnderCursor()
--         if not winid then
--           vim.lsp.buf.hover()
--         end
--       end,
--     },
--   },
--   config = function()
--     vim.o.foldcolumn = '1' -- or '0' ?
--     vim.o.foldlevel = 99 -- UFO needs a high value
--     vim.o.foldlevelstart = 99
--     vim.o.foldenable = true
--     vim.o.fillchars = [[eob: ,fold: ,foldopen:⏷,foldsep: ,foldclose:⏵]]
--     -- vim.o.fillchars = [[eob: ,fold: ,foldopen:,foldsep: ,foldclose:]]
--     require('ufo').setup {
--       provider_selector = function(bufnr, filetype, buftype)
--         return { 'lsp', 'indent' }
--       end,
--       close_fold_kinds_for_ft = { 'imports' },
--       -- close_fold_kinds = { 'imports' },
--     }
--   end,
-- }
