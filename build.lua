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
-- FeatureSoundDriver picks the Z80 program the build compresses: Sonic 1's DAC
-- driver (0), none with Mega PCM 2 (1) or Flamedriver (2).
local sound_driver
for line in io.lines("sonic.asm") do
    local value = line:match("^FeatureSoundDriver = (%d)")
    if value then
        sound_driver = tonumber(value)
        break
    end
end
if sound_driver == nil then
    print("FeatureSoundDriver is missing from sonic.asm.")
    os.exit(1)
end
-- Build the ROM.
local compression = improved_dac_driver_compression and "kosinski-optimised" or "kosinski"
local z80_size_symbol = ({[0] = "Size_of_DAC_driver_guess", [2] = "Size_of_Snd_driver_guess"})[sound_driver]
local p2bin_options = z80_size_symbol and ("-p=FF -z=0," .. compression .. "," .. z80_size_symbol .. ",after") or "-p=FF"
common.build_rom_and_handle_failure("sonic", output, "-D MDDebugger=1", p2bin_options, false, "https://github.com/sonicretro/s1disasm")

-- Binary resources are read by words (KosM and Enigma headers) or used as DMA
-- sources, so each must start at an even address. An odd one is an address
-- error on real hardware and silent garbage on lenient emulators.
local error_handler_end
for line in io.lines("sonic.lst") do
    local address, label = line:match("^%s*%d+/%s*(%x+) :%s+([%w_]+):%s+binclude")
    if address and tonumber(address, 16) % 2 == 1 then
        print(label .. " starts at an odd address ($" .. address .. "); put 'even' before it.")
        os.exit(1)
    end
    error_handler_end = error_handler_end or line:match("^%s*%d+/%s*(%x+) :%s+ErrorHandler_End:")
end

if include_symbols then
    local before = assert(io.open(output .. ".bin", "rb"))
    local size_before = before:seek("end")
    before:close()
    -- The debugger finds its symbol table directly after its blob, and ConvSym
    -- appends the table to the end of the file, so the blob must end the file.
    if not error_handler_end or tonumber(error_handler_end, 16) ~= size_before then
        print(string.format("The MD Debugger blob ends at $%s, but the ROM is $%X bytes; symbols would be unreachable.", error_handler_end or "?", size_before))
        os.exit(1)
    end
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
