-- lua/cpp-switcher/init.lua
local Path = require("plenary.path")
local M = {}

M.config = {
  header_ext = { "h", "hpp", "hxx", "hh" },
  source_ext = { "cpp", "cxx", "cc", "c" },
  header_dirs = { "include", "inc", "headers", "hpp" },
  source_dirs = { "src", "source", "sources", "cpp" },
  search_depth = 5,
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

local function find_corresponding_file(current_file)
  local current_path = Path:new(current_file)
  local current_parent = current_path:parent()
  local base_name = get_base_name(current_path:absolute())
  local ext = get_extension(current_file)
  
  local is_header = vim.tbl_contains(M.config.header_ext, ext)
  local target_ext = is_header and M.config.source_ext or M.config.header_ext
  local target_dirs = is_header and M.config.source_dirs or M.config.header_dirs
  
  -- First, try same directory
  for _, ext in ipairs(target_ext) do
    local same_dir_path = current_parent / (base_name .. "." .. ext)
    if file_exists(same_dir_path:absolute()) then
      return same_dir_path:absolute()
    end
  end
  
  -- Search in parallel directories
  local project_root = current_parent
  for _ = 1, M.config.search_depth do
    if project_root:is_dir() then
      for _, dir in ipairs(target_dirs) do
        local target_dir = project_root / dir
        if target_dir:is_dir() then
          for _, ext in ipairs(target_ext) do
            local target_path = target_dir / (get_base_name(current_path:filename()) .. "." .. ext)
            if file_exists(target_path:absolute()) then
              return target_path:absolute()
            end
          end
        end
      end
    end
    project_root = project_root:parent()
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
  -- Merge user config with defaults
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
  
  -- Set up keymapping
  vim.keymap.set("n", "<leader>`", switch_header_implementation, {
    noremap = true,
    silent = true,
    desc = "Switch between header and implementation"
  })
end

return M
