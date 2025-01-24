local Path = require("plenary.path")
local M = {}

M.config = {
  header_ext = { "h", "hpp", "hxx", "hh" },
  source_ext = { "cpp", "cxx", "cc", "c" },
  header_dirs = { "include", "inc", "headers", "hpp" },
  source_dirs = { "src", "source", "sources", "cpp" },
  search_depth = 5,
  custom_project_roots = { "G:/repos/cryo" }
}

local function get_extension(filename)
  return filename:match("%.([^%.]+)$")
end

local function get_base_name(filename)
  return filename:match("(.+)%.[^%.]+$") or filename
end

local function file_exists(path)
  local f = io.open(path, "r")
  if f then f:close() return true end
  return false
end

local function find_project_root(start_dir)
  for _, custom_root in ipairs(M.config.custom_project_roots) do
    local custom_path = Path:new(custom_root)
    if custom_path:exists() then return custom_path end
  end

  local markers = { ".git", "CMakeLists.txt", "Makefile", ".clangd", "compile_commands.json" }
  local dir = Path:new(start_dir)

  for _ = 1, M.config.search_depth do
    if not dir then break end
    
    if dir:absolute() == dir:parent():absolute() then break end

    for _, marker in ipairs(markers) do
      local marker_path = dir:joinpath(marker)
      if marker_path:exists() then return dir end
    end
    dir = dir:parent()
  end

  return nil
end

local function find_corresponding_file(current_file)
  local dir = vim.fn.fnamemodify(current_file, ":h")
  local filename = vim.fn.fnamemodify(current_file, ":t")
  
  local base_name = get_base_name(filename)
  local ext = get_extension(filename)

  if not base_name or not ext then return nil end

  local is_header = vim.tbl_contains(M.config.header_ext, ext)
  local target_ext = is_header and M.config.source_ext or M.config.header_ext
  local target_dirs = is_header and M.config.source_dirs or M.config.header_dirs

  local current_path = Path:new(dir)
  local project_root = find_project_root(dir) or current_path

  -- 1. Check same directory first
  for _, ext in ipairs(target_ext) do
    local target_path = current_path:joinpath(base_name .. "." .. ext)
    if target_path:exists() then return target_path:absolute() end
  end

  -- 2. Check project root directories
  for _, dir in ipairs(target_dirs) do
    local target_dir = project_root:joinpath(dir)
    if target_dir:exists() then
      for _, ext in ipairs(target_ext) do
        local target_path = target_dir:joinpath(base_name .. "." .. ext)
        if target_path:exists() then return target_path:absolute() end
      end
    end
  end

  -- 3. Search upward through parent directories
  local search_dir = current_path
  for _ = 1, M.config.search_depth do
    search_dir = search_dir:parent()
    if not search_dir or search_dir:absolute() == search_dir:parent():absolute() then break end

    for _, dir in ipairs(target_dirs) do
      local target_dir = search_dir:joinpath(dir)
      if target_dir:exists() then
        for _, ext in ipairs(target_ext) do
          local target_path = target_dir:joinpath(base_name .. "." .. ext)
          if target_path:exists() then return target_path:absolute() end
        end
      end
    end
  end

  return nil
end

local function switch_header_implementation()
  local current_file = vim.fn.expand("%:p")
  local corresponding_file = find_corresponding_file(current_file)
  
  if corresponding_file then
    vim.cmd("edit " .. vim.fn.fnameescape(corresponding_file))
  else
    vim.notify("Corresponding file not found", vim.log.levels.WARN)
  end
end

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
  
  vim.keymap.set("n", "<leader>`", switch_header_implementation, {
    noremap = true,
    silent = true,
    desc = "Switch between header and implementation"
  })
end

return M
