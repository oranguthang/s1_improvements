#!/usr/bin/env lua

--------------
-- Settings --
--------------

-- Set this to true to use a better compression algorithm for the DAC driver.
-- Having this set to false will use an inferior compression algorithm that
-- results in an accurate ROM being produced.
local improved_dac_driver_compression = false

---------------------
-- End of settings --
---------------------

-------------------------------------
-- Actual build script begins here --
-------------------------------------

local common = require "build_tools.lua.common"

-- Produce PCM and DPCM data.
common.convert_pcm_files_in_directory("sound/dac/pcm")
common.convert_dpcm_files_in_directory("sound/dac/dpcm")

-- The debugger is always enabled; symbol names can be omitted explicitly.
local debug_build = false
local include_symbols = true
for _, option in ipairs(arg) do
    if option == "debug" then
        debug_build = true
    elseif option == "--no-symbols" then
        include_symbols = false
    else
        io.stderr:write("Unknown build option: " .. option .. "\nUsage: build.lua [debug] [--no-symbols]\n")
        os.exit(1)
    end
end
local output = debug_build and "s1built.debug" or "s1built"
local convsym = os.getenv("CONVSYM")
if include_symbols and not convsym then
    local tools = common.find_tools("ConvSym", "https://github.com/vladikcomper/md-modules/tree/master/utils/convsym", "https://github.com/oranguthang/s1_improvements", "convsym")
    if not tools then os.exit(1) end
    convsym = tools.convsym
end
-- Build the ROM.
local compression = improved_dac_driver_compression and "kosinski-optimised" or "kosinski"
common.build_rom_and_handle_failure("sonic", output, "-D MDDebugger=1", "-p=FF -z=0," .. compression .. ",Size_of_DAC_driver_guess,after", false, "https://github.com/sonicretro/s1disasm")

if include_symbols then
    local before = assert(io.open(output .. ".bin", "rb"))
    local size_before = before:seek("end")
    before:close()
    local shell_prefix = package.config:sub(1, 1) == "\\" and "call " or ""
    local ok = os.execute(shell_prefix .. '"' .. convsym .. '" sonic.lst ' .. output .. '.bin -input as_lst -range 0 FFFFFF -exclude -filter "(z.+)|(id_.+)|(plcid_.+)|(palid_.+)" -a')
    if not ok then os.exit(1) end
    local after = assert(io.open(output .. ".bin", "rb"))
    local size_after = after:seek("end")
    after:close()
    if size_after <= size_before then
        print("ConvSym did not append the debugger symbol table.")
        os.exit(1)
    end
    print("Debugger symbol table: " .. (size_after - size_before) .. " bytes.")
end
-- Symbols must immediately follow the debugger blob. Pad only afterwards.
-- Keep cartridge sizes at powers of two, starting at exactly 1 MiB.
local rom = assert(io.open(output .. ".bin", "ab"))
local size = assert(rom:seek("end"))
local padded_size = 0x100000
while padded_size < size do
    padded_size = padded_size * 2
end
local padding = padded_size - size
assert(rom:write(string.rep("\255", padding)))
assert(rom:close())
print("ROM padding: " .. padding .. " bytes; final size: " .. padded_size .. " bytes.")

-- Correct the header only after symbols and padding are included.
common.fix_header(output .. ".bin")

-- A successful build; we can quit now.
common.exit()
