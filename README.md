# C++ Header/Implementation Switcher for Neovim

A Neovim plugin that provides intelligent switching between C++ header and implementation files. This plugin automatically finds corresponding header/implementation files even across different directories, without prompting for file selection.

## Features

- Quick switching between header (.h, .hpp, etc.) and implementation (.cpp, .c, etc.) files
- Smart path detection across different directory structures
- Supports multiple file extensions for both headers and source files
- Configurable search depth and directory names
- No prompts - automatically finds the most relevant file
- Works with various project structures (src/include, src/inc, etc.)

## Requirements

- Neovim 0.5 or later
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "cpp-switcher",
  name = "cpp-switcher",
  dir = vim.fn.stdpath("config") .. "/lua/custom/cpp-switcher",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = true
}
```

## Default Configuration

```lua
{
  -- Extensions considered as headers
  header_ext = { "h", "hpp", "hxx", "hh" },
  
  -- Extensions considered as source files
  source_ext = { "cpp", "cxx", "cc", "c" },
  
  -- Directories to search for headers
  header_dirs = { "include", "inc", "headers", "hpp" },
  
  -- Directories to search for sources
  source_dirs = { "src", "source", "sources", "cpp" },
  
  -- How many directory levels up to search
  search_depth = 5
}
```

## Usage

The default keybinding is `<leader>sh` which switches between header and implementation files.

The plugin will:
1. First look in the current directory for the corresponding file
2. If not found, it will search in parallel directories (src/include, etc.)
3. Continue searching up the directory tree up to the configured search depth

## Supported Directory Structures

The plugin works with various common C++ project layouts:

```
project/
├── src/
│   └── file.cpp
└── include/
    └── file.hpp

project/
├── src/
│   └── file.cpp
└── inc/
    └── file.h

project/
└── source/
    ├── file.cpp
    └── file.hpp

// ... and other common variations
```

## Configuration

You can customize the plugin's behavior by modifying any of the default settings:

```lua
{
  "cpp-switcher",
  name = "cpp-switcher",
  dir = vim.fn.stdpath("config") .. "/lua/custom/cpp-switcher",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    require("cpp-switcher").setup({
      header_ext = { "h", "hpp" },  -- Only look for these header extensions
      source_ext = { "cpp" },       -- Only look for these source extensions
      search_depth = 3,             -- Reduce search depth
      -- ... other options
    })
  end
}
```

## License

MIT

