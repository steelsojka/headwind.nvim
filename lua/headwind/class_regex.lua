local M = {}

M.html = "class%s*=%s*['\"]([_a-zA-Z0-9%s%-:/]+)['\"]"
M.css = "@apply%s+([_a-zA-Z0-9%s%-:/]+);"
M.javascript = {
  "className%s*=%s*{([%w%d%s!?_:/${}()%[%]\"',`%-]+)}",
  "class%s*=%s*{([%w%d%s!?_:/${}()%[%]\"',`%-]+)}",
  "tw%s*=%s*{([%w%d%s!?_:/${}()%[%]\"',`%-]+)}",
  "className%s*=%s*[\"']([%w%d%s!?_:/${}()%[%]\"',`%-]+)[\"']",
  "class%s*=%s*[\"']([%w%d%s!?_:/${}()%[%]\"',`%-]+)[\"']",
  "tw%s*=%s*[\"']([%w%d%s!?_:/${}()%[%]\"',`%-]+)[\"']"
  -- "[\"']([%w%d%s!?%+:/${}()%[%]\"',`]+)[\"']"
}

M.javascriptreact = M.javascript
M.typescript = M.javascript
M.typescriptreact = M.javascript
M.tsx = M.typescriptreact
M.jsx = M.javascriptreact

return M
