local ts = require "vim.treesitter"

local M = {}

-- Gets the current lang at a position.
-- Will use treesitter to get the most specific language if possible.
function M.get_current_lang(bufnr, ft)
  ft = ft or vim.api.nvim_buf_get_option(bufnr, "filetype")

  local has_parser, ts_parser = pcall(ts.get_parser, bufnr, ft)

  if has_parser and ts_parser then
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    local tree_at_pos = ts_parser:language_for_range({row, col - 1, row, col - 1})

    if tree_at_pos then
      return tree_at_pos:lang()
    end
  end

  return ft
end

function M.iter_matches(matchers, text)
  local index = nil
  local pattern_index = 1
  local patterns = {}

  for _, matcher in ipairs(matchers) do
    vim.list_extend(patterns, matcher.regex)
  end

  local pattern = patterns[pattern_index]

  local function iter()
    if not pattern then return end

    local start, end_, capture = string.find(text, pattern, index)

    if start and end_ and capture then
      index = end_

      local match_text = string.sub(text, start, end_)
      local sub_start = string.find(match_text, capture, 1, true)
      local capture_start = (start + sub_start - 1)

      return capture_start, capture_start + #capture, capture, match_text
    else
      pattern_index = pattern_index + 1
      pattern = patterns[pattern_index]
      index = nil

      return iter()
    end
  end

  return iter
end

function M.split_str(str, delimiter)
  local result = {}
  local from = 1
  local delim_from, delim_to = string.find(str, delimiter, from)

  while delim_from do
    table.insert(result, string.sub(str, from , delim_from - 1))
    from = delim_to + 1
    delim_from, delim_to = string.find(str, delimiter, from)
  end

  table.insert(result, string.sub(str, from))

  return result
end

function M.split_pattern(str, pattern)
  local result = {}

  for match in string.gmatch(str, "[^" .. pattern .. "]+") do
    table.insert(result, match)
  end

  return result
end

function M.dedupe(list)
  local result = {}
  local seen = {}

  for _, v in ipairs(list) do
    if not seen[v] then
      table.insert(result, v)
      seen[v] = true
    end
  end

  return result
end

function M.to_index_tbl(list)
  local result = {}

  for i, v in ipairs(list) do
    result[v] = i
  end

  return result
end

function M.trim_str(str)
  return string.gsub(str, "^%s*(.-)%s*$", "%1")
end

function M.get_buf_lines(bufnr, range)
  local lines = vim.api.nvim_buf_get_lines(bufnr, range[1], range[3] + 1, false)

  if range[1] == range[3] then
    lines[1] = string.sub(lines[1], range[2] + 1, range[4])
  else
    lines[1] = string.sub(lines[1], range[2] + 1)
    lines[#lines] = string.sub(lines[#lines], 1, range[4])
  end

  return lines
end

-- Thanks @theHamsta
function M.get_visual_selection()
  local _, csrow, cscol, _ = unpack(vim.fn.getpos("'<"))
  local _, cerow, cecol, _ = unpack(vim.fn.getpos("'>"))

  if csrow < cerow or (csrow == cerow and cscol <= cecol) then
    return csrow - 1, cscol - 1, cerow - 1, cecol
  else
    return cerow - 1, cecol - 1, csrow - 1, cscol
  end
end

return M
