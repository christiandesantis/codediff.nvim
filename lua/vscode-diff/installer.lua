-- Automatic installer for libvscode-diff binary
-- Downloads pre-built binaries from GitHub releases

local M = {}

-- Get the plugin root directory
local function get_plugin_root()
  local source = debug.getinfo(1).source:sub(2)
  return vim.fn.fnamemodify(source, ":h:h:h")
end

-- Detect OS
local function detect_os()
  local ffi = require("ffi")
  if ffi.os == "Windows" then
    return "windows"
  elseif ffi.os == "OSX" then
    return "macos"
  else
    return "linux"
  end
end

-- Detect architecture
local function detect_arch()
  local uname = vim.loop.os_uname()
  local machine = uname.machine:lower()
  
  -- Handle different naming conventions
  if machine:match("x86_64") or machine:match("amd64") or machine:match("x64") then
    return "x64"
  elseif machine:match("aarch64") or machine:match("arm64") then
    return "arm64"
  else
    return nil, "Unsupported architecture: " .. machine
  end
end

-- Get library extension for current OS
local function get_lib_ext()
  local ffi = require("ffi")
  if ffi.os == "Windows" then
    return "dll"
  elseif ffi.os == "OSX" then
    return "dylib"
  else
    return "so"
  end
end

-- Get library filename (without version)
local function get_lib_filename()
  return "libvscode_diff." .. get_lib_ext()
end

-- Build download URL for GitHub release
local function build_download_url(os, arch)
  local version_file = get_plugin_root() .. "/VERSION"
  local version = "0.8.0" -- Default fallback
  
  -- Try to read version from VERSION file
  local f = io.open(version_file, "r")
  if f then
    local content = f:read("*all")
    f:close()
    -- Extract version, remove trailing whitespace/newlines
    version = content:match("^%s*(.-)%s*$")
  end
  
  local ext = get_lib_ext()
  local filename = string.format("libvscode_diff_%s_%s_%s.%s", os, arch, version, ext)
  local url = string.format(
    "https://github.com/esmuellert/vscode-diff.nvim/releases/download/v%s/%s",
    version,
    filename
  )
  
  return url, filename
end

-- Check if a command exists
local function command_exists(cmd)
  local handle = io.popen("which " .. cmd .. " 2>/dev/null")
  if handle then
    local result = handle:read("*a")
    handle:close()
    return result ~= ""
  end
  return false
end

-- Download file using curl or wget
local function download_file(url, dest_path)
  local cmd
  
  -- Try curl first (more common and better error handling)
  if command_exists("curl") then
    cmd = string.format("curl -fsSL -o '%s' '%s'", dest_path, url)
  elseif command_exists("wget") then
    cmd = string.format("wget -q -O '%s' '%s'", dest_path, url)
  else
    return false, "Neither curl nor wget found. Please install curl or wget."
  end
  
  local exit_code = os.execute(cmd)
  
  -- os.execute returns true on success in Lua 5.2+, or 0 in Lua 5.1
  if exit_code == true or exit_code == 0 then
    return true
  else
    return false, string.format("Download failed with exit code: %s", tostring(exit_code))
  end
end

-- Install the library
function M.install(opts)
  opts = opts or {}
  local force = opts.force or false
  
  local plugin_root = get_plugin_root()
  local lib_path = plugin_root .. "/" .. get_lib_filename()
  
  -- Check if library already exists
  if not force and vim.fn.filereadable(lib_path) == 1 then
    if not opts.silent then
      vim.notify("libvscode-diff already installed at: " .. lib_path, vim.log.levels.INFO)
    end
    return true
  end
  
  -- Detect platform
  local os_name = detect_os()
  local arch, arch_err = detect_arch()
  
  if not arch then
    local msg = "Failed to detect architecture: " .. (arch_err or "unknown error")
    vim.notify(msg, vim.log.levels.ERROR)
    return false, msg
  end
  
  if not opts.silent then
    vim.notify(
      string.format("Installing libvscode-diff for %s %s...", os_name, arch),
      vim.log.levels.INFO
    )
  end
  
  -- Build download URL
  local url, filename = build_download_url(os_name, arch)
  
  if not opts.silent then
    vim.notify("Downloading from: " .. url, vim.log.levels.INFO)
  end
  
  -- Download to temporary location first
  local temp_path = plugin_root .. "/" .. filename .. ".tmp"
  local success, err = download_file(url, temp_path)
  
  if not success then
    local msg = "Failed to download library: " .. (err or "unknown error")
    vim.notify(msg, vim.log.levels.ERROR)
    -- Clean up temp file if it exists
    os.remove(temp_path)
    return false, msg
  end
  
  -- Move to final location
  local ok = os.rename(temp_path, lib_path)
  if not ok then
    local msg = "Failed to move library to final location: " .. lib_path
    vim.notify(msg, vim.log.levels.ERROR)
    os.remove(temp_path)
    return false, msg
  end
  
  if not opts.silent then
    vim.notify("Successfully installed libvscode-diff!", vim.log.levels.INFO)
  end
  
  return true
end

-- Check if library is installed
function M.is_installed()
  local plugin_root = get_plugin_root()
  local lib_path = plugin_root .. "/" .. get_lib_filename()
  return vim.fn.filereadable(lib_path) == 1
end

-- Get library path
function M.get_lib_path()
  local plugin_root = get_plugin_root()
  return plugin_root .. "/" .. get_lib_filename()
end

return M
