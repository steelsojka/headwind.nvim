(jsx_attribute
  (property_identifier) @tag
  (string) @classes
  (#vim-match? @tag "^(className|class|tw)$")
  (#offset! @classes 0 1 0 -1))

(jsx_attribute
  (property_identifier) @tag
  (jsx_expression
    (string) @classes)
  (#vim-match? @tag "^(className|class|tw)$")
  (#offset! @classes 0 1 0 -1)) @test
