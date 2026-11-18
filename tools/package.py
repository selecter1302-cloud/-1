#!/usr/bin/env python3
"""Patch the verified Narana APK and audit its sparse resource directory."""
import argparse
import hashlib
from pathlib import Path
import re
import shutil
import struct
from zipfile import ZipFile, ZipInfo, ZIP_STORED


BASE_SHA256 = "f250f70ca53c2a5d1740a348185309b44b8454e5c2c52d148b8135894a18081b"
PACK = "assets/assets.sparsepck"
MANIFEST = "AndroidManifest.xml"
SCRIPTS = (
    "behavior_night", "new_game", "scenarios/expression_filter",
    "ui/cg_view", "ui/expression_surgery", "ui/face_window_view",
)
SIGNATURE = re.compile(r"META-INF/(MANIFEST\.MF|[^/]+\.(SF|RSA|DSA|EC)|SIG-[^/]+)", re.I)


def file_sha256(path):
    with path.open("rb") as source:
        return hashlib.file_digest(source, "sha256").hexdigest()


def sparse_rows(pack):
    expected_header = (b"GDPC", 3, 4, 6, 3, 6, 0)
    if struct.unpack_from("<4s5IQ", pack) != expected_header:
        raise ValueError("Unexpected Godot sparse format or engine version")
    directory, = struct.unpack_from("<Q", pack, 32)
    count, = struct.unpack_from("<I", pack, directory)
    position = directory + 4
    entries = {}
    for _ in range(count):
        size, = struct.unpack_from("<I", pack, position)
        start = position + 4
        end = start + size
        raw_name = pack[start:end]
        name = raw_name.rstrip(b"\0").decode("utf-8")
        offset, length, digest, flags = struct.unpack_from("<QQ16sI", pack, end)
        if name in entries or offset or flags or Path(name).is_absolute() or ".." in Path(name).parts:
            raise ValueError(f"Unexpected sparse entry: {name}")
        entries[name] = (raw_name, length, digest)
        position = end + 36
    if position != len(pack):
        raise ValueError("Sparse directory length mismatch")
    return directory, entries


def rebuild_sparse(pack, replacements, removed):
    directory, entries = sparse_rows(pack)
    if not (replacements.keys() | removed) <= entries.keys():
        raise ValueError("An expected script entry is missing")
    result = bytearray(pack[:directory])
    result.extend(struct.pack("<I", len(entries) - len(removed)))
    for name, (raw_name, length, digest) in entries.items():
        if name in removed:
            continue
        if name in replacements:
            data = replacements[name]
            length, digest = len(data), hashlib.md5(data).digest()
        result.extend(struct.pack("<I", len(raw_name)))
        result.extend(raw_name)
        result.extend(struct.pack("<QQ16sI", 0, length, digest, 0))
    return result


def manifest_version(manifest, update=None):
    data = bytearray(manifest)
    typ, position, size = struct.unpack_from("<HHI", data)
    if typ != 0x0003 or size != len(data):
        raise ValueError("Invalid binary Android manifest")
    resource_ids = ()
    while position < len(data):
        typ, header, length = struct.unpack_from("<HHI", data, position)
        if length < header or header < 8 or position + length > len(data):
            raise ValueError("Invalid AXML chunk")
        if typ == 0x0180:
            ids_bytes = data[position + header:position + length]
            resource_ids = struct.unpack(f"<{len(ids_bytes) // 4}I", ids_bytes)
        if typ == 0x0102:  # Root element, manifest.
            attrs, stride, count = struct.unpack_from("<HHH", data, position + header + 8)
            for index in range(count):
                offset = position + header + attrs + stride * index
                _, name, raw, value_size, _, value_type, old = struct.unpack_from("<IIIHBBI", data, offset)
                if name < len(resource_ids) and resource_ids[name] == 0x0101021B:
                    if raw != 0xFFFFFFFF or value_size != 8 or value_type != 0x10:
                        raise ValueError("Unexpected versionCode encoding")
                    if update is not None:
                        if old != 57 or update <= old:
                            raise ValueError(f"Invalid upgrade from versionCode {old} to {update}")
                        struct.pack_into("<I", data, offset + 16, update)
                    return old, data
            break
        position += length
    raise ValueError("versionCode not found")


def audit(apk, source=None, expected_version=None, aligned=False):
    with ZipFile(apk) as archive, apk.open("rb") as backing:
        if len(archive.namelist()) != len(set(archive.namelist())):
            raise ValueError("Duplicate APK members")
        _, entries = sparse_rows(archive.read(PACK))
        members = {i.filename.removeprefix("assets/") for i in archive.infolist()
                   if i.filename.startswith("assets/") and not i.is_dir() and i.filename != PACK}
        if members != entries.keys():
            raise ValueError(f"APK/sparse membership mismatch: {members ^ entries.keys()}")
        for name, (_, length, digest) in entries.items():
            with archive.open("assets/" + name) as stream:
                actual = hashlib.file_digest(stream, "md5").digest()
            if length != archive.getinfo("assets/" + name).file_size or digest != actual:
                raise ValueError(f"Sparse size or digest mismatch: {name}")
        version, _ = manifest_version(archive.read(MANIFEST))
        if expected_version is not None and version != expected_version:
            raise ValueError(f"Unexpected versionCode {version}")
        if source is not None:
            for script in SCRIPTS:
                name = "scripts/" + script
                if name + ".gdc" in members or name + ".gd.remap" in members:
                    raise ValueError(f"Stale compiled source or remap: {name}")
                if (source / "assets" / (name + ".gd")).read_bytes() != archive.read("assets/" + name + ".gd"):
                    raise ValueError(f"Patched bytes differ: {name}")
        libs = [i for i in archive.infolist() if i.filename.startswith("lib/") and i.filename.endswith(".so")]
        if aligned and not libs:
            raise ValueError("No APK native libraries")
        for entry in libs if aligned else ():
            backing.seek(entry.header_offset + 26)
            name_size, extra_size = struct.unpack("<HH", backing.read(4))
            offset = entry.header_offset + 30 + name_size + extra_size
            if entry.compress_type != ZIP_STORED or offset % 16384:
                raise ValueError(f"Native library lacks 16 KiB ZIP alignment: {entry.filename}")
            native = archive.read(entry)
            if native[:6] != b"\x7fELF\x02\x01":
                raise ValueError(f"Expected a little-endian ELF64 library: {entry.filename}")
            table_offset, = struct.unpack_from("<Q", native, 32)
            entry_size, count = struct.unpack_from("<HH", native, 54)
            loads = 0
            for index in range(count):
                offset = table_offset + entry_size * index
                kind, _, file_offset, address, _, _, _, alignment = struct.unpack_from("<II6Q", native, offset)
                if kind == 1:
                    loads += 1
                    if alignment < 16384 or (file_offset - address) % 16384:
                        raise ValueError(f"16 KiB incompatible PT_LOAD: {entry.filename}")
            if not loads:
                raise ValueError(f"No PT_LOAD segments: {entry.filename}")
            print(f"16 KiB ZIP and ELF alignment: {entry.filename}")
        print(f"versionCode {version}: {len(entries)} assets match sparse membership, lengths, CRC and MD5")


def build(base, source, output):
    if file_sha256(base) != BASE_SHA256:
        raise ValueError("Input APK SHA-256 mismatch")
    replacements = {f"scripts/{s}.gd": (source / f"assets/scripts/{s}.gd").read_bytes() for s in SCRIPTS}
    removed = {f"scripts/{s}.gdc" for s in SCRIPTS}
    with ZipFile(base) as original, ZipFile(output, "x", allowZip64=False) as patched:
        changed = {"assets/" + key: value for key, value in replacements.items()}
        changed[PACK] = rebuild_sparse(original.read(PACK), replacements, removed)
        _, changed[MANIFEST] = manifest_version(original.read(MANIFEST), 58)
        for entry in original.infolist():
            name = entry.filename
            if (name.startswith("assets/") and name[7:] in removed) or SIGNATURE.fullmatch(name):
                continue
            info = ZipInfo(name, entry.date_time)
            info.compress_type = ZIP_STORED if name.startswith("lib/") and name.endswith(".so") else entry.compress_type
            info.external_attr = entry.external_attr
            info.create_system = entry.create_system
            if name in changed:
                patched.writestr(info, changed[name])
            else:
                with original.open(entry) as src, patched.open(info, "w") as dst:
                    shutil.copyfileobj(src, dst, 1024 * 1024)
    audit(output, source, 58)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="action", required=True)
    create = sub.add_parser("build")
    create.add_argument("base", type=Path)
    create.add_argument("source", type=Path)
    create.add_argument("output", type=Path)
    verify = sub.add_parser("audit")
    verify.add_argument("apk", type=Path)
    verify.add_argument("--source", type=Path)
    verify.add_argument("--version", type=int)
    verify.add_argument("--aligned", action="store_true")
    args = parser.parse_args()
    if args.action == "build":
        build(args.base, args.source, args.output)
    else:
        audit(args.apk, args.source, args.version, args.aligned)
