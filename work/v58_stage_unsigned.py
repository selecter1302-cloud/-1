#!/usr/bin/env python3
"""Create UNSIGNED v58 staging APK; never distribute as an update."""
import zipfile,struct,hashlib,sys
from pathlib import Path
src=Path(sys.argv[1]); root=Path(sys.argv[2]);out=Path(sys.argv[3])
changed=['scripts/behavior_night.gd','scripts/scenarios/expression_filter.gd','scripts/ui/cg_view.gd','scripts/ui/expression_surgery.gd','scripts/ui/face_window_view.gd']
def bump(b):
    a=bytearray(b)
    def u16(p):return struct.unpack_from('<H',a,p)[0]
    def u32(p):return struct.unpack_from('<I',a,p)[0]
    assert u16(0)==3 and u32(4)==len(a)
    pos=8;names=[];ids=[];found=0
    while pos<len(a):
        kind,hsize,total=struct.unpack_from('<HHI',a,pos)
        assert total>=hsize>=8
        if kind==1:
            start=pos+u32(pos+20)
            assert u32(pos+16)&0x100==0,'unsupported UTF8 stringpool'
            for i in range(u32(pos+8)):
                p=start+u32(pos+hsize+4*i);n=u16(p)
                names.append(a[p+2:p+2+2*n].decode('utf-16le'))
        if kind==0x180:ids=[u32(p) for p in range(pos+hsize,pos+total,4)]
        if kind==0x102 and names[u32(pos+20)]=='manifest':
            off,size,count=struct.unpack_from('<HHH',a,pos+24)
            for i in range(count):
                p=pos+16+off+i*size;key=u32(p+4)
                if names[key]=='versionCode' and ids[key]==0x0101021b:
                    assert a[p+15]==0x10 and u32(p+16)==57
                    struct.pack_into('<I',a,p+16,58);found+=1
        pos+=total
    assert found==1 and pos==len(a)
    return bytes(a)
with zipfile.ZipFile(src) as zin:
    names=set(zin.namelist()); assert len(names)==2978
    pack=bytearray(zin.read('assets/assets.sparsepck'));assert pack[:4]==b'GDPC'
    count=struct.unpack_from('<I',pack,104)[0];pos=108;entries={}
    for i in range(count):
        n=struct.unpack_from('<I',pack,pos)[0];pos+=4
        name=pack[pos:pos+n].split(b'\0',1)[0].decode();pos+=n
        pos+=8;sizepos=pos;pos+=8;md5pos=pos;pos+=20
        entries[name]=(sizepos,md5pos)
    assert count==2890 and pos==len(pack)
    assert {f'assets/{key}' for key in entries}<=names
    for name in changed:
        assert name in entries
        data=(root/name).read_bytes();sp,mp=entries[name]
        struct.pack_into('<Q',pack,sp,len(data));pack[mp:mp+16]=hashlib.md5(data).digest()
    for name,(sp,mp) in entries.items():
        data=(root/name).read_bytes() if name in changed else zin.read('assets/'+name)
        assert len(data)==struct.unpack_from('<Q',pack,sp)[0],name
        assert hashlib.md5(data).digest()==pack[mp:mp+16],name
    print('ALL_2890_RESOURCE_ENTRIES_VERIFIED')
    manifest=bump(zin.read('AndroidManifest.xml'))
    with zipfile.ZipFile(out,'w',allowZip64=True) as zout:
        for info in zin.infolist():
            name=info.filename
            if name.startswith('META-INF/') and name.upper().endswith(('.RSA','.DSA','.EC','.SF','.MF')):continue
            if name=='AndroidManifest.xml':value=manifest
            elif name=='assets/assets.sparsepck':value=bytes(pack)
            elif name.startswith('assets/') and name[7:] in changed:value=(root/name[7:]).read_bytes()
            else:value=zin.read(name)
            zout.writestr(info,value)
with zipfile.ZipFile(out) as check:
    assert check.testzip() is None
    assert check.read('AndroidManifest.xml')==manifest
    assert check.read('assets/assets.sparsepck')==bytes(pack)
print('STAGED_UNSIGNED',out,out.stat().st_size)
