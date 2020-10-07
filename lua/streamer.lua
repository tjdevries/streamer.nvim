local ffi = require('ffi')

ffi.cdef [[
typedef unsigned char char_u;
char_u *get_special_key_name(int c, int modifiers);
]]

ConvBuf = function(buf)
  if not buf then
    return buf
  end

  return ffi.string(ffi.C.get_special_key_name(buf:byte(2, 2), buf:byte(1, 1)))
end

KeysTyped = {}

local ns_streamer = vim.api.nvim_create_namespace('streamer.nvim')

local repper_map = {
  ku = "<Up>",
  kd = "<Down>",
  kb = "<BS>",
  [0xfd] = "<MouseDown>",
  [0xfc] = "<ScrollUp>",
}

LastWeirdOne = nil

local convert_buf_to_readable = function(buf)
  if buf:byte() == 27 then
    return "<ESC>"
  end

  if buf:byte(1, 1) == 128 then
    return repper_map[buf:sub(2)] or repper_map[buf:sub(2):byte(1, 1)] or buf
  end

  return buf
end

if WinID and vim.api.nvim_win_is_valid(WinID) then
  vim.api.nvim_win_close(WinID, true)
end

local width = 40

BufNR = vim.api.nvim_create_buf(false, true)
WinID = vim.api.nvim_open_win(BufNR, false, {
  relative = 'editor',
  row = 3,
  col = 3,
  width = width,
  height = 1,
  style = 'minimal',
})

vim.register_keystroke_callback(function(buf)
  local mode = vim.api.nvim_get_mode().mode
  -- table.insert(KeysTyped, {
  --   mode = mode,
  --   buf = convert_buf_to_readable(buf),
  -- })
  table.insert(KeysTyped, convert_buf_to_readable(buf))

  local currently_displayed = vim.api.nvim_buf_get_lines(BufNR, 0, 1, false)[1] or ''
  local new_text = convert_buf_to_readable(buf):gsub("\n", "<CR>")
  local val = (currently_displayed .. new_text)
  val = val:sub(math.max(#val - width, 1), #val)

  vim.api.nvim_buf_set_lines(BufNR, 0, -1, true, {val})
end, ns_streamer)


