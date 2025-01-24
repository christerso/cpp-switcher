-- lua/cpp-switcher/init.lua
local Path = require("plenary.path")
local M = {}

M.config = {
  header_ext = { "h", "hpp", "hxx", "hh" },
  source_ext = { "cpp", "cxx", "cc", "c" },
  header_dirs = { "include", "inc", "headers", "hpp" },
  source_dirs = { "src", "source", "sources", "cpp" },
  search_depth = 5, -- Depth to search for the project root and ancestor directories
}

-- Helper functions
local function get_extension(filename)
  return filename:match("%.([^%.]+)$")
end

local function get_base_name(filename)
  return filename:match("(.+)%.[^%.]+$")
end

local function file_exists(path)
  local f = io.open(path, "r")
  if f then
    f:close()
    return true
  end
  return false
end

-- Find project root
local function find_project_root(start_dir)
  local markers = { ".git", "CMakeLists.txt", "Makefile", ".clangd", "compile_commands.json" }
  local dir = Path:new(start_dir)

  for _ = 1, M.config.search_depth do
    for _, marker in ipairs(markers) do
      if (dir / marker):exists() then
        return dir
      end
    end
    dir = dir:parent()
  end
  return nil
end

-- Updated file search logic
local function find_corresponding_file(current_file)
  local current_path = Path:new(current_file)
  local current_parent = current_path:parent()
  local filename = current_path:filename()
  local base_name = get_base_name(filename)
  local ext = get_extension(filename)

  -- Check for valid extension
  if not base_name or not ext then
    vim.notify("Current file has no valid extension", vim.log.levels.WARN)
    return nil
  end

  local is_header = vim.tbl_contains(M.config.header_ext, ext)
  local target_ext = is_header and M.config.source_ext or M.config.header_ext
  local target_dirs = is_header and M.config.source_dirs or M.config.header_dirs

  local project_root = find_project_root(current_parent:absolute()) or current_parent

  vim.notify("Searching from root: " .. project_root:absolute(), vim.log.levels.DEBUG)

  -- 1. Check same directory first
  for _, ext in ipairs(target_ext) do
    local same_dir_path = Path:new(current_parent, base_name .. "." .. ext)
    if file_exists(same_dir_path:absolute()) then
      return same_dir_path:absolute()
    end
  end

  -- 2. Check project root's target directories
  for _, dir in ipairs(target_dirs) do
    local target_dir = Path:new(project_root, dir)
    if target_dir:is_dir() then
      for _, ext in ipairs(target_ext) do
        local target_path = Path:new(target_dir, base_name .. "." .. ext)
        if file_exists(target_path:absolute()) then
          return target_path:absolute()
        end
      end
    end
  end

  -- 3. Check ancestor directories for target folders
  local search_dir = current_parent
  for _ = 1, M.config.search_depth do
    search_dir = search_dir:parent()
    if not search_dir then break end

    for _, dir in ipairs(target_dirs) do
      local target_dir = Path:new(search_dir, dir)
      if target_dir:is_dir() then
        for _, ext in ipairs(target_ext) do
          local target_path = Path:new(target_dir, base_name .. "." .. ext)
          if file_exists(target_path:absolute()) then
            return target_path:absolute()
          end
        end
      end
    end
  end

  return nil
end

-- Switch function
local function switch_header_implementation()
  local current_file = vim.fn.expand("%:p")
  local corresponding_file = find_corresponding_file(current_file)

  if corresponding_file then
    vim.cmd("edit " .. corresponding_file)
  else
    vim.notify("Corresponding file not found", vim.log.levels.WARN)
  end
end

-- Setup function
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
  vim.keymap.set("n", "<leader>`", switch_header_implementation, {
    noremap = true,
    silent = true,
    desc = "Switch between header and implementation"
  })
end

return M
