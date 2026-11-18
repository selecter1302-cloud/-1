#!/usr/bin/env python3
"""Join a conventional split ZIP ending in .zip, preserving member bytes."""
import argparse
from pathlib import Path
import shutil
import struct
import zipfile


def join(last, output):
    with last.open("rb") as stream:
        stream.seek(-22, 2)
        signature, disk, dir_disk, on_disk, count, length, offset, comment = struct.unpack(
            "<4s4H2IH", stream.read(22)
        )
        if signature != b"PK\x05\x06" or comment or disk != dir_disk or on_disk != count:
            raise ValueError("Expected a comment-free split ZIP with its directory on the final disk")
        stream.seek(offset)
        directory = bytearray(stream.read(length))

    bases = []
    with output.open("xb") as stream:
        for index in range(disk + 1):
            part = last if index == disk else last.with_suffix(f".z{index + 1:02}")
            bases.append(stream.tell())
            with part.open("rb") as source:
                if index == 0:
                    if source.read(4) != b"PK\x07\x08":
                        raise ValueError("Missing spanning marker")
                    bases[-1] -= 4
                shutil.copyfileobj(source, stream, 1024 * 1024) if index != disk else stream.write(source.read(offset))
        directory_offset = stream.tell()
        position = 0
        for _ in range(count):
            if directory[position:position + 4] != b"PK\x01\x02":
                raise ValueError("Invalid central directory")
            name, extra, note, entry_disk = struct.unpack_from("<4H", directory, position + 28)
            local_offset, = struct.unpack_from("<I", directory, position + 42)
            struct.pack_into("<H", directory, position + 34, 0)
            struct.pack_into("<I", directory, position + 42, bases[entry_disk] + local_offset)
            position += 46 + name + extra + note
        if position != length:
            raise ValueError("Central directory size mismatch")
        stream.write(directory)
        stream.write(struct.pack("<4s4H2IH", signature, 0, 0, count, count, length, directory_offset, 0))
    with zipfile.ZipFile(output) as archive:
        damaged = archive.testzip()
        if damaged:
            raise ValueError(f"Failed CRC check: {damaged}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("last", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    join(args.last, args.output)
