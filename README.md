# headwind.nvim

Port of the [VSCode headwind plugin](https://marketplace.visualstudio.com/items?itemName=heybourn.headwind)

This is still alpha level software... use with caution.

## Install

```lua
-- Packer
use "steelsojka/headwind.nvim"
```

## Setup

```lua
require "headwind".setup {
  -- options here
}
```

### Options

#### sort_tailwind_class

A list that determines Headwind's defauls sort order

#### remove_duplicates

Headwind will remove duplicate class names by default. This can be toggled on or off. This defaults to `true`.

#### prepend_custom_classes

Headwind will append custom class names by default. They can be prepended instead. Defaults to `false`.

#### class_regex

Patterns to use for matching class strings. Note, this has no effect when using treesitter.

#### run_on_save

Headwind will run on save by default (if a `tailwind.config.js` file is present within your working directory). This can be toggled on or off. Defaults to `true`.

#### use_treesitter

Use treesitter to find class strings. This will be MUCH more accurate with a couple caveats...

- The `class_regex` option has no effect
- The syntax must be valid for the language. The css `@apply` is not valid css so treesitter can parse it. This requires a postCSS parser which is not supported yet.

**Treesitter is ON by default. This method will be the primary supported method, since it is superior to regular pattern matching.
If you have the correct treesitter parser installed then this flag just needs to be set to true.
For more information on installing parsers look at the** [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) plugin.

## Usage

Headwind doesn't do anything... you must call the API methods. This allows users to control when they want things to happen.

### Api

#### buf_sort_tailwind_classes([bufnr], [opts])

Sorts all tailwind class matchers in the buffer and edits them in place.

- `bufnr`: The buffer to use. Will use active buffer if not provided.
- `opts`: Options that will override the global and user defined options.

#### visual_sort_tailwind_classes([opts])

Sorts all tailwind classes in the visual selection. Note, everything in the visual selection will be sorted as a class.
This is useful for one off sorting.

- `opts`: Options that will override the global and user defined options.

#### string_sort_tailwind_classes([str], [opts])

Sorts the given tailwind class string and returns the result.

- `str`: The string to sort.
- `opts`: Options that will override the global and user defined options.
