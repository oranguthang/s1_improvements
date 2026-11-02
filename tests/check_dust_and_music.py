"""Regression checks on the built 68000 code; requires unicorn==2.1.4.
Build the ROM first, then run this script with Python 3.
"""
import re
from pathlib import Path
from unicorn import Uc, UC_ARCH_M68K, UC_MODE_BIG_ENDIAN, UC_HOOK_CODE
from unicorn.m68k_const import *

ROOT=Path(__file__).resolve().parents[1]

class CPU:
    cache={}
    def __init__(self, root, rom, lst):
        key=(str(root),rom,lst,(root/rom).stat().st_mtime_ns,(root/lst).stat().st_mtime_ns)
        if key not in self.cache:
            self.cache[key]=((root/rom).read_bytes(),{m[1]:int(m[2],16)&0xffffffff for m in re.finditer(r'\b([\w.]+)\s*:\s*([0-9A-F]+)\s+[-A-Z]',(root/lst).read_text(errors='replace'))})
        self.rom,self.s=self.cache[key]
        self.uc=Uc(UC_ARCH_M68K,UC_MODE_BIG_ENDIAN)
        self.uc.ctl_set_cpu_model(UC_CPU_M68K_M68000)
        self.uc.mem_map(0,0x800000);self.uc.mem_write(0,self.rom)
        self.uc.mem_map(0xFFFF0000,0x10000)
        self.uc.mem_map(0xA00000,0x20000);self.uc.mem_map(0xC00000,0x1000)
        self.uc.reg_write(UC_M68K_REG_SR,0x2700)
    def addr(self,a):return self.s[a] if isinstance(a,str) else a
    def w(self,a,v,n=1):self.uc.mem_write(self.addr(a),(v&((1<<(n*8))-1)).to_bytes(n,'big'))
    def r(self,a,n=1):return int.from_bytes(self.uc.mem_read(self.addr(a),n),'big')
    def reg(self,n,v):self.uc.reg_write(n,v)
    def call(self,name):
        self.reg(UC_M68K_REG_A7,0xFFFFF000);self.w(0xFFFFF000,0x7f0000,4)
        try:self.uc.emu_start(self.s[name],0x7f0000,count=1000000)
        except Exception as e:raise RuntimeError((name,hex(self.uc.reg_read(UC_M68K_REG_PC)))) from e
        assert self.uc.reg_read(UC_M68K_REG_PC)==0x7f0000,(name,hex(self.uc.reg_read(UC_M68K_REG_PC)))
        # Materialize Unicorn's lazy 68000 CCR through an actual MOVE SR.
        saved=self.uc.reg_read(UC_M68K_REG_D7)
        self.uc.mem_write(0x7f0000,b'\x40\xc7')
        self.uc.emu_start(0x7f0000,0x7f0002,count=1)
        sr=self.uc.reg_read(UC_M68K_REG_D7)
        self.reg(UC_M68K_REG_D7,saved)
        return not bool(sr&4)
    def skip(self,name,callback=None):
        def hook(uc,pc,size,user):
            if callback:callback(self)
            sp=uc.reg_read(UC_M68K_REG_A7)
            uc.reg_write(UC_M68K_REG_PC,self.r(sp,4));uc.reg_write(UC_M68K_REG_A7,sp+4)
        self.uc.hook_add(UC_HOOK_CODE,hook,begin=self.s[name],end=self.s[name])

def c1():return CPU(ROOT,'s1built.bin','sonic.lst')

def record(c,version,payload,magic):
    rec=magic+bytes([version,len(payload)])+bytes(payload)
    rec+=sum(rec).to_bytes(2,'big')
    start=c.s.get('SRAM_settings',0x200001)
    for i,b in enumerate(rec):c.w(start+2*i,b)

def settings():
    c=c1();c.call('Settings_Defaults');assert c.r('v_dev_supermusic')==1
    c.w('v_dev_supermusic',0);c.call('Settings_Save');c.w('v_dev_supermusic',1)
    c.call('Settings_Load');assert c.r('v_dev_supermusic')==0
    record(c,2,[1,1,1,10,1,1,2,255],b'S1DV');c.call('Settings_Load')
    assert c.r('v_dev_supermusic')==1 and c.r('v_character_selected')==2 and c.r('v_dev_god')==1

def music():
    c=c1();c.w('v_supersonic',1);c.w('v_dev_supermusic',0);c.w('v_zone_act',0,2)
    c.call('GetActMusic');level=c.uc.reg_read(UC_M68K_REG_D0)
    c.call('GetSonicMusic');assert c.uc.reg_read(UC_M68K_REG_D0)==level
    c.w('f_bossmusic',1);c.call('GetSonicMusic');assert c.uc.reg_read(UC_M68K_REG_D0)==c.s['bgm_Boss']
    c.w('v_dev_supermusic',1);c.call('GetSonicMusic');assert c.uc.reg_read(UC_M68K_REG_D0)==c.s['bgm_Super']

def dust_and_signs():
    for character,slide,offset in [(0,False,16),(1,False,12),(2,False,16),(2,True,6)]:
        c=c1();p=c.s['v_player'];manager=c.s['v_dustobj'];spawned=[];dmas=[]
        c.reg(UC_M68K_REG_A0,manager);c.w(p+c.s['obRoutine'],2)
        c.w(p+c.s['obAnim'],c.s['id_Wait'] if slide else c.s['id_Stop'])
        c.w('v_character_p1',character);c.w('v_knux_state',5 if slide else 0)
        c.w(p+c.s['obY'],0x100,2);c.w(p+c.s['obX'],0x200,2);c.w(p+c.s['obVelX'],0x100,2)
        def allocate(cpu):
            obj=cpu.s['v_objspace']+cpu.s['object_size']*(20+len(spawned))
            cpu.reg(UC_M68K_REG_A1,obj);spawned.append(obj)
            cpu.reg(UC_M68K_REG_SR,0x2704)
        c.skip('FindFreeObj',allocate)
        c.skip('QueueDMATransfer',lambda cpu:dmas.append((cpu.uc.reg_read(UC_M68K_REG_D1),cpu.uc.reg_read(UC_M68K_REG_D3))))
        for _ in range(12):c.call('SpinDust_Main')
        assert len(spawned)==3 and len(dmas)==1,(character,slide,len(spawned),dmas)
        assert dmas==[(c.s['Art_SkidDust'],256)]
        for obj in spawned:assert c.r(obj+c.s['obY'],2)==0x100+offset
        c.reg(UC_M68K_REG_A0,spawned[0]);c.skip('DisplaySprite')
        deleted=[];c.skip('DeleteObject',lambda cpu:deleted.append(1))
        frames=[]
        for _ in range(17):c.call('SpinDust_SkidPuff');frames.append(c.r(spawned[0]+c.s['obFrame']))
        assert frames[:16]==[0]*4+[1]*4+[2]*4+[3]*4 and len(deleted)==1,frames
    for character in range(3):
        c=c1();loaded=[];c.w('v_character_p1',character);c.w('v_debuguse',1,2)
        c.w('v_limitright2',0x2000,2);c.w('v_screenposx',0x1f00,2);c.w('f_timecount',1)
        c.skip('NewPLC',lambda cpu:loaded.append(cpu.uc.reg_read(UC_M68K_REG_D0)))
        c.call('SignpostArtLoad');assert len(loaded)==1
        c.call('SignpostArtLoad');assert len(loaded)==1
    return {'character_and_slide_cases':4,'debug_signpost_characters':3}

if __name__=='__main__':
    settings();music();print(dust_and_signs());print('S1 checks passed')
