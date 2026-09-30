"""Reusable codecs kosinski transformations for Sonic 1 resources."""

from __future__ import annotations

from collections import defaultdict, deque

MODULE_SIZE = 4096
MAX_DISTANCE = 8192
MAX_MATCH = 256
MAX_CANDIDATES = 96


class BitWriter:
    """Kosinski descriptors are little-endian and reload on the 16th bit."""

    def __init__(self) -> None:
        self.data = bytearray(2)
        self.descriptor_at = 0
        self.descriptor = 0
        self.bit_count = 0

    def bit(self, value: int) -> None:
        self.descriptor |= (value & 1) << self.bit_count
        self.bit_count += 1
        if self.bit_count == 16:
            self.data[self.descriptor_at : self.descriptor_at + 2] = self.descriptor.to_bytes(
                2, "little"
            )
            self.descriptor_at = len(self.data)
            self.data.extend(b"\x00\x00")
            self.descriptor = 0
            self.bit_count = 0

    def emit(self, bits: tuple[int, ...], payload: bytes) -> None:
        for value in bits:
            self.bit(value)
        self.data.extend(payload)

    def finish(self) -> bytes:
        self.data[self.descriptor_at : self.descriptor_at + 2] = self.descriptor.to_bytes(
            2, "little"
        )
        return bytes(self.data)


def encode(raw: bytes) -> bytes:
    if not raw:
        raise ValueError("Kosinski module cannot be empty")
    writer = BitWriter()
    history: dict[bytes, deque[int]] = defaultdict(deque)

    def remember(pos: int) -> None:
        if pos + 3 > len(raw):
            return
        locations = history[raw[pos : pos + 3]]
        locations.append(pos)
        if len(locations) > MAX_CANDIDATES:
            locations.popleft()

    pos = 0
    while pos < len(raw):
        best_length = 0
        best_distance = 0
        if pos + 3 <= len(raw):
            for previous in reversed(history.get(raw[pos : pos + 3], ())):
                distance = pos - previous
                if distance > MAX_DISTANCE:
                    break
                limit = min(MAX_MATCH, len(raw) - pos)
                length = 3
                while length < limit and raw[pos + length] == raw[pos + length - distance]:
                    length += 1
                if length > best_length:
                    best_length, best_distance = (length, distance)
                    if length == limit:
                        break
        if best_length >= 3:
            length = best_length
            offset = -best_distance & 8191
            if best_distance <= 256 and length <= 5:
                count = length - 2
                writer.emit((0, 0, count >> 1, count & 1), bytes([-best_distance & 255]))
            elif length <= 9:
                writer.emit((0, 1), bytes([offset & 255, offset >> 8 << 3 | length - 2]))
            else:
                writer.emit((0, 1), bytes([offset & 255, offset >> 8 << 3, length - 1]))
            advance = length
        else:
            writer.emit((1,), raw[pos : pos + 1])
            advance = 1
        for consumed in range(pos, pos + advance):
            remember(consumed)
        pos += advance
    writer.emit((0, 1), b"\x00\x00\x00")
    encoded = writer.finish()
    decoded, consumed = decode_checked(encoded)
    if decoded != raw or consumed != len(encoded):
        raise AssertionError("Kosinski round trip failed")
    return encoded


def encode_moduled(raw: bytes) -> bytes:
    if not raw or len(raw) % 32:
        raise ValueError("tile art must contain complete 32-byte tiles")
    if len(raw) > 65535:
        raise ValueError("moduled Kosinski header supports at most 65535 bytes")
    header = len(raw) // MODULE_SIZE << 12 | len(raw) % MODULE_SIZE
    result = bytearray(header.to_bytes(2, "big"))
    restored = bytearray()
    modules = [raw[i : i + MODULE_SIZE] for i in range(0, len(raw), MODULE_SIZE)]
    for index, module in enumerate(modules):
        encoded = encode(module)
        decoded, consumed = decode_checked(encoded)
        if decoded != module or consumed != len(encoded):
            raise AssertionError("module round trip failed")
        restored.extend(decoded)
        result.extend(encoded)
        if index + 1 != len(modules):
            result.extend(bytes(-len(encoded) & 15))
    if restored != raw:
        raise AssertionError("moduled art round trip failed")
    if decode_moduled(bytes(result)) != raw:
        raise AssertionError("KosM header/module round trip failed")
    return bytes(result)


def decode_moduled(blob: bytes) -> bytes:
    """Read the KosM header and padded modules as the ROM loader will."""
    if len(blob) < 2:
        raise ValueError("missing KosM header")
    header = int.from_bytes(blob[:2], "big")
    full_modules, final_size = (header >> 12, header & 4095)
    module_count = full_modules + bool(final_size)
    if module_count == 0:
        raise ValueError("empty KosM asset")
    cursor = 2
    result = bytearray()
    for index in range(module_count):
        decoded, consumed = decode_checked(blob[cursor:])
        expected = MODULE_SIZE if index < full_modules else final_size
        if len(decoded) != expected:
            raise ValueError(f"module {index}: expected {expected} bytes, got {len(decoded)}")
        result.extend(decoded)
        cursor += consumed
        if index + 1 != module_count:
            padding = -consumed & 15
            if any(blob[cursor : cursor + padding]):
                raise ValueError(f"module {index}: nonzero padding")
            cursor += padding
    if cursor != len(blob):
        raise ValueError(f"trailing KosM data: {len(blob) - cursor} bytes")
    return bytes(result)


def decode_checked(data: bytes) -> tuple[bytes, int]:
    """Kosinski decode that also returns how many input bytes were consumed.

    Same algorithm as title_compare_fixed.decode_kosinski (KosDec semantics:
    the descriptor reloads right after its 16th bit); the result is compared
    with that decoder to make sure both agree.
    """
    out = bytearray()
    pos = 0

    def load() -> int:
        nonlocal pos
        value = data[pos] | data[pos + 1] << 8
        pos += 2
        return value

    desc, left = (load(), 16)

    def bit() -> int:
        nonlocal desc, left
        value = desc & 1
        desc >>= 1
        left -= 1
        if left == 0:
            desc, left = (load(), 16)
        return value

    while True:
        if bit():
            out.append(data[pos])
            pos += 1
            continue
        if bit():
            low, high = (data[pos], data[pos + 1])
            pos += 2
            offset = ((high & 248) << 5 | low) - 8192
            count = high & 7
            if count:
                count += 2
            else:
                count = data[pos]
                pos += 1
                if count == 0:
                    break
                if count == 1:
                    continue
                count += 1
        else:
            count = (bit() << 1 | bit()) + 2
            offset = data[pos] - 256
            pos += 1
        if len(out) + offset < 0:
            raise ValueError("Kosinski copy before the start of the output")
        for _ in range(count):
            out.append(out[len(out) + offset])
    return (bytes(out), pos)


def decode(data: bytes) -> bytes:
    """Kosinski decoder matching KosDec (descriptor reloads right after its 16th bit)."""
    out = bytearray()
    pos = 0

    def load() -> int:
        nonlocal pos
        value = data[pos] | data[pos + 1] << 8
        pos += 2
        return value

    desc, left = (load(), 16)

    def bit() -> int:
        nonlocal desc, left
        value = desc & 1
        desc >>= 1
        left -= 1
        if left == 0:
            desc, left = (load(), 16)
        return value

    while True:
        if bit():
            out.append(data[pos])
            pos += 1
            continue
        if bit():
            low, high = (data[pos], data[pos + 1])
            pos += 2
            offset = ((high & 248) << 5 | low) - 8192
            count = high & 7
            if count:
                count += 2
            else:
                count = data[pos]
                pos += 1
                if count == 0:
                    break
                if count == 1:
                    continue
                count += 1
        else:
            count = (bit() << 1 | bit()) + 2
            offset = data[pos] - 256
            pos += 1
        for _ in range(count):
            out.append(out[len(out) + offset])
    return bytes(out)
