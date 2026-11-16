"""Independent authored finite cases; no production, audio or learner execution."""
import json
import math
from fractions import Fraction
from pathlib import Path
import unittest

EVIDENCE = Path(__file__).resolve().parents[1]
PACKET = json.loads((EVIDENCE / 'unit-a.json').read_text(encoding='utf-8'))
COURSES = {course['code']: course for course in PACKET['courses']}
R = math.sqrt(0.5)
# Reviewer fixed oracles: fractions, analytic constants and manually derived tables.
# None of these values is loaded from a packet expected field.
FIXED = {
    'AUD016': ({'mean': .5, 'ac_samples': [-.5,.5,-.5,.5], 'total_ms': .5, 'ac_ms': .25, 'total_rms': R, 'ac_rms': .5}, {'mean': 0, 'ac_samples': [-.5,.5,-.5,.5], 'total_ms': .25, 'ac_ms': .25, 'total_rms': .5, 'ac_rms': .5}),
    'AUD017': ({'correlation': [0,2,0,-2], 'signed_argmax': [1], 'absolute_argmax': [1,3]}, {'correlation': [0,1,0,0], 'signed_argmax': [1], 'absolute_argmax': [1]}),
    'AUD018': ({'mid': [R,R], 'side': [R,-R], 'left_out': [1,0], 'right_out': [0,1], 'input_energy': 2, 'output_energy': 2}, {'mid': [R,R], 'side': [R,-R], 'left_out': [.5,.5], 'right_out': [.5,.5], 'input_energy': 2, 'output_energy': 1}),
    'GAS015': ({'observed': [1,0,-.25,0], 'zero_modes': [2,4]}, {'observed': [R,.5,R/4,0], 'zero_modes': [4]}),
    'GAS016': ({'extension_m': .0001999800039989008, 'tension_n': 10.1999800039989, 'ideal_f_hz': 100, 'frequency_hz': 100.9747574562156, 'error_cents': 16.79361678856818}, {'extension_m': 0, 'tension_n': 10, 'ideal_f_hz': 100, 'frequency_hz': 100, 'error_cents': 0}),
    'GAS017': ({'B': .01, 'predicted_third_squared_ratio': 109/101, 'held_out_residual': 0, 'valid': True}, {'B': -1/301, 'valid': False}),
    'GTR015': ({'cents': [0,25,0,-25,0], 'period_s': .5, 'peak_to_peak_cents': 50}, {'cents': [0,0,0,0,0], 'period_s': .25, 'peak_to_peak_cents': 50}),
    'GTR016': ({'vibrating_fraction': 2**(-7/12), 'base_hz': 110*2**(7/12), 'touch_fraction_from_bridge': 2**(-7/12)/2, 'sounding_hz': 220*2**(7/12), 'fixed_touch_local': 2**(7/12)/2}, {'vibrating_fraction': 1, 'base_hz': 110, 'touch_fraction_from_bridge': .5, 'sounding_hz': 220, 'fixed_touch_local': .5}),
    'GTR017': ({'union_s': [[0,1]], 'gaps_s': [], 'overlap_s': .1, 'continuous': True}, {'union_s': [[0,.6],[.7,1]], 'gaps_s': [[.6,.7]], 'overlap_s': 0, 'continuous': False}),
    'GAA014': ({'overlap': [[0,4,7]], 'family_disjoint': False, 'distinct_item_ids': 4}, {'overlap': [], 'family_disjoint': True, 'distinct_item_ids': 4}),
    'GAA015': ({'rate': .8, 'lower': .49015684672072346, 'upper': .9433190520193067, 'established': False}, {'rate': .8, 'lower': .7111690380734976, 'upper': .8666340774409013, 'established': True}),
    'GAA016': ({'scores': [4,5,6,7], 'mean_a': 5.5, 'mean_b': 5.5, 'contrast': 0}, {'scores': [4,5,6,7], 'mean_a': 5, 'mean_b': 6, 'contrast': 1}),
    'MCL015': ({'release_times': [2,2], 'scheduled_holds': [2,1]}, {'release_times': [.75,1.5], 'scheduled_holds': [.75,.5]}),
    'MCL016': ({'note_intervals': {'a': [0,4], 'b': [0,2]}, 'cursor_states': [0,4,0,2,4], 'final_cursor': 4, 'valid': True}, {'note_intervals': {'a': [0,4], 'b': [2,4]}, 'cursor_states': [0,4,2,4,6], 'final_cursor': 6, 'valid': False}),
    'MCL017': ({'slope_bpm_per_quarter': 15, 'duration_s': 4*math.log(2), 'endpoint_average_duration_s': 8/3}, {'slope_bpm_per_quarter': 0, 'duration_s': 4, 'endpoint_average_duration_s': 4}),
    'WML014': ({'target_cents': 386.3137138648348, 'step': 6, 'represented_cents': 7200/19, 'error_cents': -7.366345443782166}, {'target_cents': 386.3137138648348, 'step': 4, 'represented_cents': 400, 'error_cents': 13.686286135165204}),
    'WML015': ({'frequencies_hz': [442,884], 'calibration_ratio': 221/220, 'calibration_cents': 7.851415040126504, 'octave_ratio': 2}, {'frequencies_hz': [440,880], 'calibration_ratio': 1, 'calibration_cents': 0, 'octave_ratio': 2}),
    'WML016': ({'degrees': {'1':0,'5':6,'7':10,'9':14}, 'pitch_classes': [0,2,6,10], 'valid': True}, {'valid': False, 'rejected_operation_index': 1, 'reason': 'duplicate_degree', 'degree': 5}),
}
SCOPE = {
    'AUD016': 'Finite normalized real samples; record mean and squared amplitudes, not streaming filtering or joules.',
    'AUD017': 'Equal-length circular real records and listed lag direction; no zero padding or latency measurement.',
    'AUD018': 'Synchronous aligned channel pairs, orthonormal mid/side matrix and declared side gain; no perception.',
    'GAS015': 'Four fixed-end ideal sine modes and signed point displacement; no pickup voltage or spectrum measurement.',
    'GAS016': 'Symmetric SI geometry, linear axial spring, fixed density, one vibrating half; no setup calibration.',
    'GAS017': 'Exact normalized second/third partial ratios and nonnegative coefficient family; no engine mapping.',
    'GTR015': 'Sinusoidal authored cents at exact time grid and zero phase; continuous extent distinct from samples.',
    'GTR016': 'Ideal equal-tempered lengths, bridge origin and midpoint mode; no performed harmonic or contact dynamics.',
    'GTR017': 'Two same-target half-open contact intervals; necessary schedule coverage only, no clean-sound proof.',
    'GAA014': 'Ordered offset keys and cross-partition intersection only; no learner or statistical independence evidence.',
    'GAA015': 'Stipulated iid Bernoulli counts, Wilson z=1.96 and prospective lower endpoint rule; no real mastery claim.',
    'GAA016': 'Four deterministic equal-spaced trials with linear drift and zero effects; no randomized trial.',
    'MCL015': 'One damper interval and distinct event times; scheduled release commands, not acoustic silence.',
    'MCL016': 'Positive fixed division durations, one measure, note/backup/forward only; no parser conformance.',
    'MCL017': 'Positive beat-linear BPM ramp, quarter-beat coordinate and constant limit; no scheduler observation.',
    'WML014': 'One positive ratio, equal octave division and nearest ties upward; no cultural or tuning endorsement.',
    'WML015': 'Two specified MIDI notes with reference-bearing equal-tempered frequency law; no renderer fidelity.',
    'WML016': 'Root zero, ordered strict add/alter/subtract edits; authored collision policy, not full MusicXML semantics.',
}


def aligned(code, case, **arrays):
    lengths = {name: len(values) for name, values in arrays.items()}
    if len(set(lengths.values())) != 1:
        print('\nOBSERVATION '+json.dumps(dict(code=code, case=case, observed={'aligned_lengths': lengths}, expected={'equal_lengths': True}, scope=SCOPE[code])), flush=True)
        raise AssertionError(f'{code}: unequal paired input lengths {lengths}')


def observe(code, v, case='model'):
    if code == 'AUD016':
        x = [Fraction(str(a)) for a in v['samples']]
        mean = sum(x)/len(x)
        ac = [a-mean for a in x]
        total = sum(a*a for a in x)/len(x)
        centered = sum(a*a for a in ac)/len(ac)
        return dict(mean=float(mean), ac_samples=list(map(float, ac)), total_ms=float(total), ac_ms=float(centered), total_rms=math.sqrt(total), ac_rms=math.sqrt(centered))
    if code == 'AUD017':
        x,y = v['x'],v['y']
        aligned(code,case,x=x,y=y)
        c = [sum(x[n]*y[(n+k)%len(x)] for n in range(len(x))) for k in v['lags']]
        return dict(correlation=c, signed_argmax=[v['lags'][i] for i,a in enumerate(c) if a==max(c)], absolute_argmax=[v['lags'][i] for i,a in enumerate(c) if abs(a)==max(map(abs,c))])
    if code == 'AUD018':
        left,right = v['left'],v['right']
        aligned(code,case,left=left,right=right)
        mid=[(left[i]+right[i])/math.sqrt(2) for i in range(len(left))]
        side=[(left[i]-right[i])/math.sqrt(2) for i in range(len(left))]
        lo=[(mid[i]+v['side_gain']*side[i])/math.sqrt(2) for i in range(len(left))]
        ro=[(mid[i]-v['side_gain']*side[i])/math.sqrt(2) for i in range(len(left))]
        return dict(mid=mid,side=side,left_out=lo,right_out=ro,input_energy=sum(a*a for a in left+right),output_energy=sum(a*a for a in lo+ro))
    if code == 'GAS015':
        aligned(code,case,amplitudes=v['amplitudes'],modes=v['modes'])
        y=[v['amplitudes'][i]*math.sin(n*math.pi*v['position_fraction']) for i,n in enumerate(v['modes'])]
        return dict(observed=y,zero_modes=[n for i,n in enumerate(v['modes']) if abs(y[i])<1e-12])
    if code == 'GAS016':
        length=v['length_m']; h=v['midpoint_displacement_m']
        path=math.hypot(length,2*h)
        extension=path-length
        tension=v['initial_tension_n']+v['axial_stiffness_n_per_m']*extension
        f=math.sqrt(tension/v['linear_density_kg_per_m'])/path
        ref=math.sqrt(v['initial_tension_n']/v['linear_density_kg_per_m'])/length
        return dict(extension_m=extension,tension_n=tension,ideal_f_hz=ref,frequency_hz=f,error_cents=1200*math.log2(f/ref))
    if code == 'GAS017':
        ratio=v['squared_normalized_second_ratio']; b=(ratio-1)/(4-ratio)
        valid=1<=ratio<4 and b>=0
        if not valid: return dict(B=b,valid=False)
        predicted=(1+9*b)/(1+b)
        return dict(B=b,predicted_third_squared_ratio=predicted,held_out_residual=v['squared_normalized_third_ratio']-predicted,valid=True)
    if code == 'GTR015':
        return dict(cents=[v['extent_cents']*math.sin(math.tau*v['rate_hz']*t) for t in v['times_s']],period_s=1/v['rate_hz'],peak_to_peak_cents=2*v['extent_cents'])
    if code == 'GTR016':
        ratio=2**(v['fretted_semitones']/12); length=1/ratio; base=v['open_hz']*ratio
        return dict(vibrating_fraction=length,base_hz=base,touch_fraction_from_bridge=length/v['touch_mode'],sounding_hz=base*v['touch_mode'],fixed_touch_local=v['fixed_absolute_touch_fraction']/length)
    if code == 'GTR017':
        intervals=sorted([list(map(lambda a: Fraction(str(a)),c['interval_s'])) for c in v['contacts']])
        merged=[]
        for start,end in intervals:
            if merged and start<=merged[-1][1]: merged[-1][1]=max(merged[-1][1],end)
            else: merged.append([start,end])
        start,end=map(lambda a: Fraction(str(a)),v['required_interval_s']); cursor=start; gaps=[]
        for lo,hi in merged:
            if lo>cursor: gaps.append([cursor,min(lo,end)])
            cursor=max(cursor,hi)
        if cursor<end: gaps.append([cursor,end])
        overlap=max(Fraction(0),min(i[1] for i in intervals)-max(i[0] for i in intervals))
        return dict(union_s=[[float(a),float(b)] for a,b in merged],gaps_s=[[float(a),float(b)] for a,b in gaps],overlap_s=float(overlap),continuous=not gaps)
    if code == 'GAA014':
        def families(rows): return {tuple(n-r['notes'][0] for n in r['notes']) for r in rows}
        overlap=sorted(families(v['train']) & families(v['test']))
        return dict(overlap=[list(row) for row in overlap],family_disjoint=not overlap,distinct_item_ids=len({r['id'] for r in v['train']+v['test']}))
    if code == 'GAA015':
        n=v['attempts']; p=v['passes']/n; z=v['z']; denominator=n+z*z
        center=(n*p+z*z/2)/denominator
        half=z*math.sqrt(n*p*(1-p)+z*z/4)/denominator
        return dict(rate=p,lower=center-half,upper=center+half,established=center-half>=v['required_lower_bound'])
    if code == 'GAA016':
        scores=[v['base']+v['drift_per_trial']*i+v['condition_effect'][a] for i,a in enumerate(v['order'])]
        means={a:sum(scores[i] for i,b in enumerate(v['order']) if a==b)/v['order'].count(a) for a in ('A','B')}
        return dict(scores=scores,mean_a=means['A'],mean_b=means['B'],contrast=means['B']-means['A'])
    if code == 'MCL015':
        releases=[v['pedal_up'] if v['pedal_down']<=n['key_off']<v['pedal_up'] else n['key_off'] for n in v['notes']]
        return dict(release_times=releases,scheduled_holds=[release-v['notes'][i]['on'] for i,release in enumerate(releases)])
    if code == 'MCL016':
        cursor=0; states=[0]; notes={}
        for op in v['operations']:
            if op['op'] not in ('note','backup','forward'):
                print('\nOBSERVATION '+json.dumps(dict(code=code,case='invalid-input',observed=op['op'],expected=['note','backup','forward'],scope=SCOPE[code]),allow_nan=False),flush=True)
                raise AssertionError(f"{code}: unsupported operation {op['op']!r}")
            if op['op']=='note': notes[op['id']]=[cursor,cursor+op['duration']]
            cursor+=(-1 if op['op']=='backup' else 1)*op['duration']; states.append(cursor)
        return dict(note_intervals=notes,cursor_states=states,final_cursor=cursor,valid=all(0<=a<=v['measure_units'] for a in states))
    if code == 'MCL017':
        a,b,q=v['start_bpm'],v['end_bpm'],v['quarter_beats']; slope=(b-a)/q
        duration=60*q/a if a==b else 60*q*math.log(b/a)/(b-a)
        return dict(slope_bpm_per_quarter=slope,duration_s=duration,endpoint_average_duration_s=120*q/(a+b))
    if code == 'WML014':
        cents=1200*math.log2(v['target_ratio']); divisions=v['octave_divisions']; step=math.floor(cents*divisions/1200+.5); represented=1200*step/divisions
        return dict(target_cents=cents,step=step,represented_cents=represented,error_cents=represented-cents)
    if code == 'WML015':
        f=[v['reference_a_hz']*2**((n-69)/12) for n in v['midi_notes']]; ratio=v['reference_a_hz']/v['comparison_a_hz']
        return dict(frequencies_hz=f,calibration_ratio=ratio,calibration_cents=1200*math.log2(ratio),octave_ratio=f[1]/f[0])
    if code == 'WML016':
        degrees=dict(v['degrees'])
        for i,op in enumerate(v['operations']):
            if op['op'] not in ('add','alter','subtract'):
                print('\nOBSERVATION '+json.dumps(dict(code=code,case='invalid-input',observed=op['op'],expected=['add','alter','subtract'],scope=SCOPE[code]),allow_nan=False),flush=True)
                raise AssertionError(f"{code}: unsupported operation {op['op']!r}")
            key=str(op['degree'])
            if op['op']=='add':
                if key in degrees: return dict(valid=False,rejected_operation_index=i,reason='duplicate_degree',degree=op['degree'])
                degrees[key]=op['semitones']
            elif op['op']=='alter': degrees[key]+=op['delta']
            elif op['op']=='subtract': del degrees[key]
        return dict(degrees=degrees,pitch_classes=sorted({n%12 for n in degrees.values()}),valid=True)
    raise AssertionError(code)


class UnitA(unittest.TestCase):
    def same(self, actual, expected, path='result'):
        if isinstance(expected,dict):
            self.assertEqual(set(actual),set(expected),path)
            for key,value in expected.items(): self.same(actual[key],value,path+'.'+key)
        elif isinstance(expected,list):
            self.assertEqual(len(actual),len(expected),path)
            for i,value in enumerate(expected): self.same(actual[i],value,f'{path}[{i}]')
        elif isinstance(expected,bool): self.assertIs(actual,expected,path)
        elif isinstance(expected,(float,int)):
            self.assertNotIsInstance(actual,bool,path)
            self.assertTrue(math.isfinite(actual) and math.isclose(actual,expected,rel_tol=1e-11,abs_tol=1e-11),f'{path}: {actual!r} != {expected!r}')
        else: self.assertEqual(actual,expected,path)

    def check_course(self, code):
        model=COURSES[code]['authored_model']
        for index,case in enumerate(('model','negative')):
            entry=model if case=='model' else model['negative_control']
            result=observe(code,entry['values'],case)
            print('\nOBSERVATION '+json.dumps(dict(code=code,case=case,observed=result,expected=FIXED[code][index],scope=SCOPE[code]),ensure_ascii=False,allow_nan=False),flush=True)
            self.same(result,FIXED[code][index])
            self.same(result,entry['expected'])
            if code=='AUD016': self.same(result['total_ms'],result['mean']**2+result['ac_ms'])
            if code=='GTR015':
                frequencies=[entry['values']['base_hz']*2**(c/1200) for c in result['cents']]
                self.same(frequencies,[440,446.39994737251044,440,433.6918074016825,440] if case=='model' else [440]*5)


def course_test(code):
    def test(self): self.check_course(code)
    return test


for _code in FIXED:
    setattr(UnitA,'test_'+_code,course_test(_code))

if __name__=='__main__': unittest.main(verbosity=2)
