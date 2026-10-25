"""Independent finite claim checks for Streeling unit A; no audio or learner execution."""
import copy
import json
import math
from fractions import Fraction
from pathlib import Path
import unittest

EVIDENCE = Path(__file__).resolve().parents[1]
PACKET = json.loads((EVIDENCE / 'unit-a.json').read_text(encoding='utf-8'))
COURSES = {c['code']: c for c in PACKET['courses']}
# Fixed reviewer expectations, derived before observing packet calculations.
FIXED = {
 'AUD013': ({'duration_s':1,'output_frames':48000,'relabeled_duration_s':.91875,'relabeled_tone_hz':1088.43537414966},{'duration_s':1,'output_frames':44100,'relabeled_duration_s':1,'relabeled_tone_hz':1000}),
 'AUD014': ({'raw':[1.6,-1.6,.8],'mixed':[.8,-.8,.4],'peak':.8,'clipped_raw':[1,-1,.8]},{'raw':[0,0,0],'mixed':[0,0,0],'peak':0,'clipped_raw':[0,0,0]}),
 'AUD015': ({'integers':[0,0,16384,-16383],'decoded':[0,0,16384/32767,-16383/32767],'errors':[0,-.00001,1/65534,1/65534],'half_step':1/65534},{'integer_before_int16_write':36044,'int16_representable':False}),
 'GAS012': ({'omega_rad_per_s':[10,20],'frequencies_hz':[1.5915494309189535,3.183098861837907]},{'omega_rad_per_s':[10,10],'frequencies_hz':[1.5915494309189535,1.5915494309189535]}),
 'GAS013': ({'initial_frequency_hz':100,'target_tension_n':180,'tension_ratio':2.25},{'initial_frequency_hz':150,'target_tension_n':80,'tension_ratio':1}),
 'GAS014': ({'delay_s':.001,'first_opposition_hz':500,'spacing_hz':1000,'magnitude_at_opposition':0},{'delay_s':.001,'first_opposition_hz':500,'spacing_hz':1000,'magnitude_at_opposition':.5}),
 'GTR012': ({'surviving_modes':[3,6],'frequencies_hz':[330,660],'lowest_surviving_hz':330},{'surviving_modes':[2,4,6],'frequencies_hz':[220,440,660],'lowest_surviving_hz':220}),
 'GTR013': ({'target_cents':200,'target_frequency_hz':123.47082531403103,'signed_error_cents':-5,'worst_abs_error_cents':8,'established_within_tolerance':True},{'target_cents':200,'target_frequency_hz':123.47082531403103,'signed_error_cents':-9,'worst_abs_error_cents':12,'established_within_tolerance':False}),
 'GTR014': ({'pitches':[64,67,64,69],'note_events':4,'pick_attacks':2,'legato_changes':2},{'pitches':[64,67,64,69],'note_events':4,'pick_attacks':3,'legato_changes':1}),
 'GAA011': ({'total':10,'correct':7,'accuracy':.7,'recall':[.75,2/3],'majority_baseline':.6},{'total':10,'correct':3,'accuracy':.3,'recall':[.25,1/3],'majority_baseline':.6}),
 'GAA012': ({'total_trials':8,'cell_counts':[2,2,2,2],'covered_cells':4,'balanced_complete':True},{'total_trials':8,'cell_counts':[4,0,0,4],'covered_cells':2,'balanced_complete':False}),
 'GAA013': ({'distinct_pitch_class_sets':1,'distinct_voicings':3,'distinct_bass_classes':2,'pitch_class_keys':[[0,4,7]]},{'distinct_pitch_class_sets':2,'distinct_voicings':3,'distinct_bass_classes':2,'pitch_class_keys':[[0,4,7],[0,4,5,7]]}),
 'MCL012': ({'sounding_events':[{'pitch':60,'onset_beats':0,'duration_beats':2},{'pitch':62,'onset_beats':2,'duration_beats':1}],'attacks':2,'total_span_beats':3},{'sounding_events':[{'pitch':60,'onset_beats':0,'duration_beats':1},{'pitch':60,'onset_beats':1,'duration_beats':1},{'pitch':62,'onset_beats':2,'duration_beats':1}],'attacks':3,'total_span_beats':3}),
 'MCL013': ({'per_note_ticks':160,'total_ticks':480,'total_quarters':1},{'per_note_ticks':360,'total_ticks':1080,'total_quarters':2.25}),
 'MCL014': ({'grace_each_s':.05,'main_start_s':1.1,'main_duration_s':.4,'next_boundary_s':1.5},{'grace_each_s':.05,'main_start_s':1.1,'main_duration_s':.5,'next_boundary_s':1.6}),
 'WML011': ({'pitch_classes':[0,4,7,10],'third_offset':4,'seventh_offset':10},{'pitch_classes':[0,4,7,11],'third_offset':4,'seventh_offset':11}),
 'WML012': ({'step_allowed':[True,True,False,True],'accepted':False,'union':[0,2,3,4,7,9]},{'step_allowed':[True,True,True,True],'accepted':True,'union':[0,2,3,4,7,9]}),
 'WML013': ({'residual_ratio':531441/524288,'residual_cents':23.460010384649014,'closes_exactly':False},{'residual_ratio':1,'residual_cents':0,'closes_exactly':True}),
}
SCOPE = {
 'AUD013':'Finite clock/count arithmetic only; no interpolation, alias or rendered tone test.',
 'AUD014':'Three aligned authored mono samples; linear summation and hard clipping only; no loudness.',
 'AUD015':'Finite normalized sample quantization using JS tie direction, scale32767; rejected overflow, no codec/listening.',
 'GAS012':'Two identical masses and symmetric linear undamped springs; derived eigenvalues in rad/s and Hz, no guitar coupling probe.',
 'GAS013':'Uniform flexible fixed-end string with SI parameters per case; no material or instrument acceptance.',
 'GAS014':'Two copies with stipulated distances, speed and fixed positive gains; no room measurement.',
 'GTR012':'Ideal node constraint restricted to six candidate modes; no amplitudes/contact performance.',
 'GTR013':'Authored bounded cent uncertainty and inclusive local tolerance; no tracker validation or actual bend.',
 'GTR014':'Four instructed symbolic note actions on one stipulated valid string; no acoustic onset count.',
 'GAA011':'Two-class authored complete confusion counts, fixed row/column labels; no participant or inference.',
 'GAA012':'Two-by-two authored assignment counts only; no playback, randomization or responses.',
 'GAA013':'Four nonempty ascending authored note lists; first-occurrence family order; no fingering/retrieval.',
 'MCL012':'Single voice and first contiguous equal-pitch pair only; symbolic sound attacks, no parser.',
 'MCL013':'One non-nested undotted tuplet at quarter-based resolution; exact rational time, no playback.',
 'MCL014':'Two equal grace notes under declared seconds allocations; no stylistic default or MusicXML execution.',
 'WML011':'Explicit three-kind 12-TET dictionary and supplied root; no label parser or voicing.',
 'WML012':'Authored one-register phrase with no repeated adjacent pitches; directional target membership, no tradition.',
 'WML013':'Stipulated fifth and octave counts; exact pure fraction and symbolic ET closure checked with floating tolerance; no tuning session.',
}

def observe(code, v):
    if code == 'AUD013':
        d = Fraction(v['input_frames'], v['input_rate_hz'])
        return dict(duration_s=float(d), output_frames=float(d*v['output_rate_hz']), relabeled_duration_s=v['input_frames']/v['output_rate_hz'], relabeled_tone_hz=v['tone_hz']*v['output_rate_hz']/v['input_rate_hz'])
    if code == 'AUD014':
        raw=[a+b for a,b in zip(v['a'],v['b'])]; mixed=[v['gain']*x for x in raw]; limit=v['peak_limit']
        return dict(raw=raw,mixed=mixed,peak=max(map(abs,mixed)),clipped_raw=[max(-limit,min(limit,x)) for x in raw])
    if code == 'AUD015':
        q=[math.floor(v['scale']*x+.5) for x in v['samples']]
        if any(not -32768<=n<=32767 for n in q):
            return dict(integer_before_int16_write=q[0],int16_representable=False)
        decoded=[n/v['scale'] for n in q]
        return dict(integers=q,decoded=decoded,errors=[y-x for y,x in zip(decoded,v['samples'])],half_step=1/(2*v['scale']))
    if code == 'GAS012':
        # Matrix eigenvalues (diagonal +/- off-diagonal), distinct from Hz.
        diagonal=(v['anchor_stiffness_n_per_m']+v['coupling_stiffness_n_per_m'])/v['mass_kg']; off=-v['coupling_stiffness_n_per_m']/v['mass_kg']
        omega=[math.sqrt(diagonal+off),math.sqrt(diagonal-off)]
        return dict(omega_rad_per_s=omega,frequencies_hz=[w/math.tau for w in omega])
    if code == 'GAS013':
        f=math.sqrt(v['initial_tension_n']/v['linear_density_kg_per_m'])/(2*v['length_m']); tension=v['linear_density_kg_per_m']*(2*v['length_m']*v['target_frequency_hz'])**2
        return dict(initial_frequency_hz=f,target_tension_n=tension,tension_ratio=tension/v['initial_tension_n'])
    if code == 'GAS014':
        delay=(v['path_b_m']-v['path_a_m'])/v['sound_speed_m_per_s']
        return dict(delay_s=delay,first_opposition_hz=.5/delay,spacing_hz=1/delay,magnitude_at_opposition=abs(1-v['relative_gain']))
    if code == 'GTR012':
        modes=[n for n in v['mode_numbers'] if Fraction(n*v['touch_fraction_numerator'],v['touch_fraction_denominator']).denominator==1]; frequencies=[n*v['fundamental_hz'] for n in modes]
        return dict(surviving_modes=modes,frequencies_hz=frequencies,lowest_surviving_hz=min(frequencies))
    if code == 'GTR013':
        cents=100*v['target_semitones']; error=v['estimated_bend_cents']-cents; worst=abs(error)+v['uncertainty_cents']
        return dict(target_cents=cents,target_frequency_hz=v['base_frequency_hz']*2**(v['target_semitones']/12),signed_error_cents=error,worst_abs_error_cents=worst,established_within_tolerance=worst<=v['tolerance_cents'])
    if code == 'GTR014':
        events=v['events']; return dict(pitches=[e['pitch'] for e in events],note_events=len(events),pick_attacks=sum(e['action']=='pick' for e in events),legato_changes=sum(e['action'] in ('hammer','pull') for e in events))
    if code == 'GAA011':
        rows=v['rows_true_columns_answer']; totals=list(map(sum,rows)); total=sum(totals); correct=sum(rows[i][i] for i in range(len(rows)))
        return dict(total=total,correct=correct,accuracy=correct/total,recall=[rows[i][i]/totals[i] for i in range(len(rows))],majority_baseline=max(totals)/total)
    if code == 'GAA012':
        counts=[sum(t['count'] for t in v['trials'] if t['interval']==i and t['timbre']==j) for i in v['intervals'] for j in v['timbres']]
        return dict(total_trials=sum(counts),cell_counts=counts,covered_cells=sum(n>0 for n in counts),balanced_complete=min(counts)>0 and len(set(counts))==1)
    if code == 'GAA013':
        families=list(dict.fromkeys(tuple(sorted({n%12 for n in row})) for row in v['candidates']))
        return dict(distinct_pitch_class_sets=len(families),distinct_voicings=len({tuple(row) for row in v['candidates']}),distinct_bass_classes=len({min(row)%12 for row in v['candidates']}),pitch_class_keys=[list(x) for x in families])
    if code == 'MCL012':
        notes=copy.deepcopy(v['notes']); a,b=notes[:2]
        if v['first_pair_relation']=='tie' and a['pitch']==b['pitch'] and a['onset_beats']+a['duration_beats']==b['onset_beats']:
            a['duration_beats']+=b['duration_beats']; notes.pop(1)
        return dict(sounding_events=notes,attacks=len(notes),total_span_beats=max(n['onset_beats']+n['duration_beats'] for n in notes)-min(n['onset_beats'] for n in notes))
    if code == 'MCL013':
        each=v['ticks_per_quarter']*Fraction(v['base_duration_quarters_numerator'],v['base_duration_quarters_denominator'])*Fraction(v['normal_notes'],v['actual_notes']); total=each*v['note_count']
        return dict(per_note_ticks=float(each),total_ticks=float(total),total_quarters=float(total/v['ticks_per_quarter']))
    if code == 'MCL014':
        main=v['written_main_duration_s']-v['grace_total_s'] if v['policy']=='steal_following' else v['written_main_duration_s']; start=v['start_s']+v['grace_total_s']
        return dict(grace_each_s=v['grace_total_s']/v['grace_count'],main_start_s=start,main_duration_s=main,next_boundary_s=start+main)
    if code == 'WML011':
        offsets={'dominant':[0,4,7,10],'minor-seventh':[0,3,7,10],'major-seventh':[0,4,7,11]}[v['kind']]
        return dict(pitch_classes=sorted((v['root_pitch_class']+n)%12 for n in offsets),third_offset=offsets[1],seventh_offset=offsets[3])
    if code == 'WML012':
        flags=[b%12 in v['ascending' if b>a else 'descending'] for a,b in zip(v['phrase'],v['phrase'][1:])]
        return dict(step_allowed=flags,accepted=all(flags),union=sorted(set(v['ascending']+v['descending'])))
    if code == 'WML013':
        ratio=v['fifth_ratio']**v['fifth_count']/2**v['octave_count']; cents=1200*math.log2(ratio)
        return dict(residual_ratio=ratio,residual_cents=cents,closes_exactly=abs(cents)<1e-10)
    raise AssertionError(code)

class UnitA(unittest.TestCase):
    def same(self, observed, expected, path='result'):
        if isinstance(expected,dict):
            self.assertEqual(set(observed),set(expected),path)
            for k,v in expected.items(): self.same(observed[k],v,path+'.'+k)
        elif isinstance(expected,list):
            self.assertEqual(len(observed),len(expected),path)
            for i,v in enumerate(expected): self.same(observed[i],v,f'{path}[{i}]')
        elif isinstance(expected,bool): self.assertIs(observed,expected,path)
        elif isinstance(expected,(int,float)):
            self.assertFalse(isinstance(observed,bool),path)
            self.assertTrue(math.isfinite(observed) and math.isclose(observed,expected,rel_tol=1e-11,abs_tol=1e-12),f'{path}: {observed!r} != {expected!r}')
        else: self.assertEqual(observed,expected,path)
    def check_course(self, code):
        model=COURSES[code]['authored_model']
        for index,case in enumerate(('model','negative')):
            entry=model if case=='model' else model['negative_control']; values=entry['values']
            if code=='AUD014' and len(values['a'])!=len(values['b']):
                print('OBSERVATION '+json.dumps(dict(code=code,case=case,observed=dict(aligned_sample_counts=False,a_length=len(values['a']),b_length=len(values['b'])),expected=dict(aligned_sample_counts=True),scope=SCOPE[code]),allow_nan=False),flush=True)
                self.assertEqual(len(values['a']),len(values['b']),'AUD014 requires aligned sample arrays of equal length')
            observed=observe(code,values); fixed=FIXED[code][index]
            print('OBSERVATION '+json.dumps(dict(code=code,case=case,observed=observed,expected=fixed,scope=SCOPE[code]),ensure_ascii=False,allow_nan=False),flush=True)
            self.same(observed,fixed)
            self.same(observed,entry['expected'])
            if code=='AUD015' and case=='model': self.assertLessEqual(max(map(abs,observed['errors'])),1/65534+1e-16)
            if code=='GAS012':
                self.same([w*w for w in observed['omega_rad_per_s']],[100,400] if case=='model' else [100,100])
            if code=='MCL013' and case=='model': self.same([i*observed['per_note_ticks'] for i in range(3)],[0,160,320])
            if code=='WML013' and case=='model': self.assertEqual(Fraction(3,2)**12/Fraction(2)**7,Fraction(531441,524288))

def course_test(code):
    def test(self): self.check_course(code)
    return test
for _code in FIXED: setattr(UnitA,'test_'+_code,course_test(_code))
if __name__ == '__main__': unittest.main(verbosity=2)
