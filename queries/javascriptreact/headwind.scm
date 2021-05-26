(jsx_attribute
  (property_identifier) @tag
  (string) @classes
  (#vim-match? @tag "^(className|class|tw)$")
  (#offset! @classes 0 1 0 -1))

(jsx_attribute
  (property_identifier) @tag
  (jsx_expression) @expression
  (#vim-match? @tag "^(className|class|tw)$")
  (#headwind-all-types! @expression "string" 1 -1))
