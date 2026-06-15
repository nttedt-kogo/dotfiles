-- claudecode.nvim : Neovim と Claude Code CLI を接続するプラグイン（coder製）
-- 選択範囲をClaudeに送る / Claudeの編集を差分で承認 / nvim内でClaudeをトグル
-- vim.pack 方式で導入（kickstart の他プラグインと同じ作法）

vim.pack.add { 'https://github.com/coder/claudecode.nvim' }

require('claudecode').setup {}

-- キーマップ（<leader> は kickstart 既定でスペース）
local map = vim.keymap.set
map('n', '<leader>ac', '<cmd>ClaudeCode<cr>', { desc = '[A]I: [C]laude トグル' })
map('n', '<leader>af', '<cmd>ClaudeCodeFocus<cr>', { desc = '[A]I: [F]ocus' })
map('n', '<leader>ar', '<cmd>ClaudeCode --resume<cr>', { desc = '[A]I: [R]esume（履歴から再開）' })
map('n', '<leader>aC', '<cmd>ClaudeCode --continue<cr>', { desc = '[A]I: [C]ontinue（直前の続き）' })
map('v', '<leader>as', '<cmd>ClaudeCodeSend<cr>', { desc = '[A]I: 選択範囲を[S]end' })
-- Claudeが提案した差分の承認/却下
map('n', '<leader>aa', '<cmd>ClaudeCodeDiffAccept<cr>', { desc = '[A]I: 差分を[A]ccept' })
map('n', '<leader>ad', '<cmd>ClaudeCodeDiffDeny<cr>', { desc = '[A]I: 差分を[D]eny' })
