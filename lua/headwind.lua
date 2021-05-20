local Utils = require "headwind.utils"

local M = {}

local default_options = {
  default_sort_order = require "headwind.default_sort_order",
  class_regex = require "headwind.class_regex"
}

local global_options = {}

local function make_options(opts)
  opts = opts or {}
  opts.sort_tailwind_classes = opts.sort_tailwind_classes
    or global_options.sort_tailwind_classes
    or default_options.default_sort_order
  opts.class_regex = vim.tbl_extend("force", {},
    default_options.class_regex,
    global_options.class_regex or {},
    opts.class_regex or {})
  opts.custom_tailwind_prefix = opts.custom_tailwind_prefix
    or global_options.custom_tailwind_prefix
    or ""
  opts.prepend_custom_classes = (opts.prepend_custom_classes ~= nil and opts.prepend_custom_classes)
    or (global_options.prepend_custom_classes ~= nil and global_options.prepend_custom_classes)
    or true
  opts.should_remove_duplicates = (opts.should_remove_duplicates ~= nil and opts.should_remove_duplicates)
    or (global_options.should_remove_duplicates ~= nil and global_options.should_remove_duplicates)
    or true

  return opts
end

local function is_array_of_strings(value)
  if type(value) == "table" and vim.tbl_islist(value) then
    for _, v in ipairs(value) do
      if type(v) ~= "string" then
        return false
      end
    end

    return true
  end

  return false
end

local function build_matcher(entry)
  if type(entry) == "string" then
    return { regex = { entry } }
  elseif is_array_of_strings(entry) then
    return { regex = entry }
  elseif entry == nil then
    return { regex = {} }
  else
    local regex = entry.regex
    local separator = entry.separator

    if type(regex) == "string" then
      regex = { regex }
    elseif regex == nil then
      regex = {}
    end

    return {
      regex = regex,
      separator = separator,
      replacement = entry.replacement or entry.separator
    }
  end
end

local function build_matchers(value)
  if value == nil then
    return {}
  elseif type(value) == "table" and vim.tbl_islist(value) then
    if #value == 0 then
      return {}
    elseif not is_array_of_strings(value) then
      local result = {}

      for _, v in ipairs(value) do
        table.insert(result, build_matcher(v))
      end

      return result
    end
  end

  return {build_matcher(value)}
end

local function sort_class_list(class_list, sort_order, prepend_custom_classes)
  local pre_list = {}
  local post_list = {}
  local custom_list = prepend_custom_classes and pre_list or post_list
  local tailwind_list = {}

  for _, v in ipairs(class_list) do
    if sort_order[v] == nil then
      table.insert(custom_list, v)
    else
      table.insert(tailwind_list, v)
    end
  end

  table.sort(tailwind_list, function(a, b)
    return sort_order[a] < sort_order[b]
  end)

  return vim.list_extend(pre_list, vim.list_extend(tailwind_list, post_list))
end

local function sort_class_str(class_str, sort_order, opts)
  local separator = opts.separator or "%s"
  local class_list = Utils.split_pattern(class_str, separator)

  if opts.should_remove_duplicates then
    class_list = Utils.dedupe(class_list)
  end

  local sort_order_clone = vim.tbl_extend("force", {}, sort_order)

  if opts.custom_tailwind_prefix then
    local tbl = {}

    for k, v in pairs(sort_order_clone) do
      tbl[opts.custom_tailwind_prefix .. k] = v
    end

    sort_order_clone = tbl
  end

  class_list = sort_class_list(class_list, sort_order_clone, opts.prepend_custom_classes)

  return Utils.trim_str(table.concat(class_list, opts.replacement or " "))
end

function M.setup(opts)
  global_options = opts
end

function M.buf_sort_tailwind_classes(bufnr, opts)
  opts = make_options(opts)
  bufnr = bufnr or vim.api.nvim_win_get_buf(0)

  local start = opts.start or 0
  local end_ = opts.end_ or -1
  local ft = Utils.get_current_lang(bufnr, opts.ft)
  local matchers = build_matchers(opts.class_regex[ft])

  if #matchers == 0 then return end

  local lines = vim.api.nvim_buf_get_lines(bufnr, start, end_, false)
  local text = table.concat(lines, "\n")
  local sort_lookup_tbl = Utils.to_index_tbl(opts.sort_tailwind_classes)
  local edits = {}

  for match_start, match_end, match in Utils.iter_matches(matchers, text) do
    local adjusted = sort_class_str(
      match,
      sort_lookup_tbl,
      vim.tbl_extend("keep", {
        separator = match.separator,
        replacement = match.relacement
      }, opts))

    local start_byte = vim.fn.byteidx(text, match_start)
    local end_byte = vim.fn.byteidx(text, match_end)
    local start_line = vim.fn.byte2line(start_byte)
    local end_line = vim.fn.byte2line(end_byte)
    local start_line_byte = vim.api.nvim_buf_get_offset(bufnr, start_line - 1)
    local end_line_byte = vim.api.nvim_buf_get_offset(bufnr, end_line - 1)
    local start_pos = { line = start_line - 1, character = start_byte - start_line_byte - 1 }
    local end_pos = { line = end_line - 1, character = end_byte - end_line_byte - 1 }
    local range = {
      start = start_pos
    }

    range["end"] = end_pos

    table.insert(edits, {
      range = range,
      newText = adjusted
    })
  end

  vim.lsp.util.apply_text_edits(edits, bufnr)
end

return M
