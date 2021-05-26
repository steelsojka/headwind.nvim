local ts_query = require "vim.treesitter.query"

local M = {}

local function for_all_children(node, cb)
  local count = node:named_child_count()

  for i = 1, count, 1 do
    local child = node:named_child(i - 1)

    if child then
      cb(child)
      for_all_children(child, cb)
    end
  end
end

local function all_types_directive(match, _, _, pred, metadata)
  local node = match[pred[2]]
  local node_type = pred[3]
  local start_offset = tonumber(pred[4] or 0)
  local end_offset = tonumber(pred[5] or 0)
  local nodes = {}

  for_all_children(node, function(child)
    if child:type() == node_type then
      local range = {child:range()}

      range[2] = range[2] + start_offset
      range[4] = range[4] + end_offset
      table.insert(nodes, range)
    end
  end)

  metadata.content = nodes
end

function M.init()
  ts_query.add_directive("headwind-all-types!", all_types_directive, true)
end

return M
