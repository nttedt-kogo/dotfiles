-- mermaid を mermaid-ascii(CLI) でASCII描画し、nvim内の分割ウィンドウに表示する。
-- 画像/Chromium不要。Windows Terminal + tmux でもサイズ問題なく動く。
--   :MermaidAscii  または  <leader>mm
--   - .mmd 等のファイル: バッファ全体を図として描画
--   - markdown: カーソル位置を囲む ```mermaid ... ``` ブロックを描画

-- カーソル位置から描画対象の mermaid ソース行を取り出す
local function get_mermaid_source()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  if vim.bo.filetype ~= 'markdown' then
    return lines -- .mmd 等はバッファ全体
  end
  -- markdown: カーソルを囲む ```mermaid フェンスを探す
  local cur = vim.api.nvim_win_get_cursor(0)[1]
  local start_fence
  for i = cur, 1, -1 do
    if lines[i] and lines[i]:match '^%s*```mermaid' then
      start_fence = i
      break
    end
    if i ~= cur and lines[i] and lines[i]:match '^%s*```' then
      break
    end
  end
  if not start_fence then
    vim.notify('カーソル位置に ```mermaid ブロックが見つかりません', vim.log.levels.WARN)
    return nil
  end
  for i = start_fence + 1, #lines do
    if lines[i]:match '^%s*```' then
      return vim.list_slice(lines, start_fence + 1, i - 1)
    end
  end
  vim.notify('```mermaid ブロックの終端が見つかりません', vim.log.levels.WARN)
  return nil
end

local function render_mermaid()
  if vim.fn.executable 'mermaid-ascii' == 0 then
    vim.notify('mermaid-ascii が見つかりません（PATHを確認）', vim.log.levels.ERROR)
    return
  end
  local src = get_mermaid_source()
  if not src or #src == 0 then
    return
  end
  local res = vim.system({ 'mermaid-ascii', '-f', '-' }, { stdin = table.concat(src, '\n') }):wait()
  if res.code ~= 0 then
    vim.notify('mermaid-ascii エラー:\n' .. (res.stderr or ''), vim.log.levels.ERROR)
    return
  end
  local out = vim.split((res.stdout or ''):gsub('\n$', ''), '\n')
  -- スクラッチバッファを縦分割で表示
  vim.cmd 'vsplit'
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(0, buf)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, out)
  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].modifiable = false
  -- q で閉じられるように
  vim.keymap.set('n', 'q', '<cmd>close<cr>', { buffer = buf, nowait = true, desc = 'プレビューを閉じる' })
end

vim.api.nvim_create_user_command('MermaidAscii', render_mermaid, { desc = 'mermaidをASCIIでプレビュー' })
vim.keymap.set('n', '<leader>mm', render_mermaid, { desc = '[M]ermaid ASCIIプレビュー' })
