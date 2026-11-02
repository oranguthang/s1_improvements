"""Tails swimming fatigue and water transition regression checks.
Requires a default built ROM and unicorn==2.1.4.
"""
from check_dust_and_music import c1
from unicorn.m68k_const import UC_M68K_REG_A0

def main():
    c=c1();p=c.s['v_player'];c.reg(UC_M68K_REG_A0,p)
    c.w('v_character_p1',1);c.w('v_tails_flying',1)
    c.w(p+c.s['obRoutine'],2);c.w(p+c.s['obStatus'],0x42)
    c.w(p+c.s['obX'],0x180,2);c.w(p+c.s['obY'],0x120,2)
    c.w('v_tails_flytime',240,2)
    for time in range(20):
        c.w('v_framecount',time,2);c.call('Tails_FlightPose')
        assert c.r(p+c.s['obFrame'])==0x79+time//4
    c.w('v_tails_flytime',0,2)
    for time in range(72):
        c.w('v_framecount',time,2);c.call('Tails_FlightPose')
        assert c.r(p+c.s['obFrame'])==c.s['fr_TailsSwimTired']+(time//12)%3
        assert c.r(p+c.s['obX'],2)==0x180 and c.r(p+c.s['obY'],2)==0x120
    # Changing water status or facing changes presentation, never coordinates.
    c.skip('QueueSound2')
    for status in [2,0x42,3,0x43]:
        c.w(p+c.s['obStatus'],status);c.call('Tails_FlightPose')
        assert c.r(p+c.s['obX'],2)==0x180 and c.r(p+c.s['obY'],2)==0x120
    print('S1 normal/tired swimming, 12f tired frames and water/facing coordinate continuity passed')

if __name__=='__main__':main()
