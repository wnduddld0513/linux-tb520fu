#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
"""Read-only FAT16 reader for Qualcomm stock NON-HLOS/BTFM images."""
from pathlib import Path
import struct
class FAT:
 def __init__(self,path):
  self.f=path.open('rb');b=self.read(0,512)
  self.bps,self.spc,self.res,self.nfat,self.roots=struct.unpack_from('<HBHBH',b,11)
  self.fatsz=struct.unpack_from('<H',b,22)[0]
  assert self.fatsz and b[54:62]==b'FAT16   '
  self.root=(self.res+self.nfat*self.fatsz)*self.bps
  self.data=self.root+((self.roots*32+self.bps-1)//self.bps)*self.bps
  self.fat=self.read(self.res*self.bps,self.fatsz*self.bps)
 def read(self,o,n):
  self.f.seek(o);b=self.f.read(n)
  if len(b)!=n:raise ValueError('Truncated FAT image')
  return b
 def chain(self,c):
  seen=set();out=bytearray()
  while 2<=c<0xfff8:
   if c in seen:raise ValueError('FAT cycle')
   seen.add(c);out+=self.read(self.data+(c-2)*self.spc*self.bps,self.spc*self.bps);c=struct.unpack_from('<H',self.fat,c*2)[0]
  return bytes(out)
 def walk(self,base='',cluster=None):
  b=self.read(self.root,self.roots*32) if cluster is None else self.chain(cluster)
  lfn=[]
  for i in range(0,len(b),32):
   e=b[i:i+32]
   if not e[0]:break
   if e[0]==0xe5:lfn=[];continue
   if e[11]==15:
    lfn.append((e[0]&31,(e[1:11]+e[14:26]+e[28:32]).decode('utf-16le')));continue
   short=e[:8].decode('ascii').rstrip();ext=e[8:11].decode('ascii').rstrip();name=''.join(x[1] for x in sorted(lfn)).split('\0')[0].replace('\uffff','') if lfn else short+('.'+ext if ext else '');lfn=[]
   if e[11]&8 or name in ['.','..']:continue
   if '/' in name or '\\' in name:raise ValueError('Invalid FAT name')
   path=base+name;cl=struct.unpack_from('<H',e,26)[0];size=struct.unpack_from('<I',e,28)[0]
   if e[11]&16:yield from self.walk(path+'/',cl)
   else:yield path,cl,size
