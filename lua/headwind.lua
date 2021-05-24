local Utils = require "headwind.utils"

local M = {}

local default_options = {
  sort_tailwind_classes = require "headwind.default_sort_order",
  class_regex = require "headwind.class_regex",
  run_on_save = true,
  remove_duplicates = true,
  prepend_custom_classes = false,
  custom_tailwind_prefix = ""
}

local global_options = {}
local is_bound = false

local function resolve_option(opts, name, is_bool)
  if is_bool then
    if opts[name] ~= nil then
      return opts[name]
    end

    if global_options[name] ~= nil then
      return global_options[name]
    end

    return default_options[name]
  else
    return opts[name]
      or global_options[name]
      or default_options[name]
  end
end

local function make_options(opts)
  opts = opts or {}
  opts.sort_tailwind_classes = resolve_option(opts, "sort_tailwind_classes")
  opts.class_regex = vim.tbl_extend("force", {},
    default_options.class_regex,
    global_options.class_regex or {},
    opts.class_regex or {})
  opts.custom_tailwind_prefix = resolve_option(opts, "custom_tailwind_prefix")
  opts.prepend_custom_classes = resolve_option(opts, "prepend_custom_classes", true)
  opts.remove_duplicates = resolve_option(opts, "remove_duplicates", true)
  opts.run_on_save = resolve_option(opts, "run_on_save", true)

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

  if opts.remove_duplicates then
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
  global_options = vim.tbl_extend("force", global_options, opts or {})

  opts = make_options(opts)

  if opts.run_on_save and not is_bound then
    is_bound = true
    vim.cmd [[augroup Headwind]]
    vim.cmd [[autocmd Headwind BufWritePre * lua require "headwind"._on_buf_write()]]
    vim.cmd [[augroup END]]
  elseif not opts.run_on_save and is_bound then
    is_bound = false
    vim.cmd [[augroup! Headwind]]
  end
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

function M._on_buf_write()
  local cwd = vim.fn.getcwd()
  local path = cwd .. "/tailwind.config.js"

  if vim.fn.filereadable(path) == 1 then
    M.buf_sort_tailwind_classes()
  end
end

return M
