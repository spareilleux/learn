"""Independent finite teaching cases; no audio, engine, MIDI or learner execution."""
import json
import math
import unittest
from collections import Counter
from fractions import Fraction
from pathlib import Path

EVIDENCE = Path(__file__).resolve().parents[1]
PACKET = json.loads((EVIDENCE / 'unit-a.json').read_text(encoding='utf-8'))
COURSES = {c['code']: c for c in PACKET['courses']}

# Separately fixed reviewer oracles, derived by hand from the declared cases.
# Analytic constants retain exact expressions rather than packet rounding.
FIXED = {
    'AUD019': ({'A': [-1,-.25,.25,1], 'B': [-.5,-.25,.25,.5], 'residual': [-.5,0,0,.5], 'commutes': False}, {'A': [-.25,-.125,.125,.25], 'B': [-.25,-.125,.125,.25], 'residual': [0,0,0,0], 'commutes': True}),
    'AUD020': ({'weight': [1]*4, 'output': [2,4,6,8], 'perfect': True}, {'weight': [.5]*4, 'output': [1,2,3,4], 'perfect': False}),
    'AUD021': ({'output': [1,0,.5,0,.25,0,.125], 'stable': True, 'absolute_sum_infinite': 2}, {'output': [1,0,1.1,0,1.21,0,1.331], 'stable': False, 'absolute_sum_infinite': None}),
    'GAS018': ({'pressure_reflection': .5, 'pressure_transmission': 1.5, 'reflected_fraction': .25, 'transmitted_fraction': .75, 'total': 1}, {'pressure_reflection': 0, 'pressure_transmission': 1, 'reflected_fraction': 0, 'transmitted_fraction': 1, 'total': 1}),
    'GAS019': ({'relative_power': [.2,.5,1,.5,.2], 'half_power_edges_hz': [95,105], 'bandwidth_hz': 10, 'Q': 10}, {'relative_power': [.2,.5,1,.5,.2], 'half_power_edges_hz': [90,110], 'bandwidth_hz': 20, 'Q': 5}),
    'GAS020': ({'point': [1,0,-1,0], 'aperture': [2*math.sqrt(2)/math.pi,0,-2*math.sqrt(2)/(3*math.pi),0]}, {'point': [1,0,-1,0], 'aperture': [1,0,-1,0]}),
    'GTR018': ({'transition_legal': [True,False], 'plan_legal': False}, {'transition_legal': [True,True], 'plan_legal': True}),
    'GTR019': ({'length': [1,Fraction(3,4),.5], 'frequency_hz': [100,400/3,200]}, {'length': [1,1/math.sqrt(2),.5], 'frequency_hz': [100,100*math.sqrt(2),200]}),
    'GTR020': ({'events_time_s_and_index': [[0,0],[.02,2],[.05,5]], 'spread_s': .05}, {'events_time_s_and_index': [[0,5],[.03,2],[.05,0]], 'spread_s': .05}),
    'GAA017': ({'pre_update_tempo': [60,65,70,65,60,65], 'post_update_tempo': [65,70,65,60,65,60], 'reversal_indices': [2,4,5], 'stop_index': 5, 'estimate_tempo': 65}, {'pre_update_tempo': [60,65,70,75,80,85], 'post_update_tempo': [65,70,75,80,85,90], 'reversal_indices': [], 'stop_index': None, 'estimate_tempo': None}),
    'GAA018': ({'ledger': [{'attempt_id':'A','pass':True},{'attempt_id':'B','pass':False}], 'rejected_ids': [], 'unresolved_ids': []}, {'ledger': [{'attempt_id':'A','pass':None},{'attempt_id':'B','pass':False}], 'rejected_ids': ['C'], 'unresolved_ids': ['A']}),
    'GAA019': ({'match_starts': [0,2], 'count': 2, 'stream_multiset': {'2':3,'-1':2}}, {'match_starts': [], 'count': 0, 'stream_multiset': {'2':3,'-1':2}}),
    'MCL018': ({'old_quarter_s': .5, 'pivot_s': .75, 'new_quarter_s': .75, 'new_quarter_bpm': 80}, {'old_quarter_s': .5, 'pivot_s': .75, 'new_quarter_s': .5, 'new_quarter_bpm': 120}),
    'MCL019': ({'pitches': [60,62,60,62,60,62], 'onsets_s': [0,.2,.4,.6,.8,1], 'duration_each_s': .2, 'terminal_pitch': 62}, {'pitches': [60,62,60,62,60], 'onsets_s': [0,.24,.48,.72,.96], 'duration_each_s': .24, 'terminal_pitch': 60}),
    'MCL020': ({'effective_alters': [0,0,1,1], 'pitches': [65,65,78,66]}, {'effective_alters': [0,0,1,0], 'pitches': [65,65,78,65]}),
    'WML017': ({'period_counts': [0,1,2,0], 'canonical_ratios': ['1','1','1','2'], 'equivalence_groups': [[0,1,2],[3]]}, {'period_counts': [0,1,3,1], 'canonical_ratios': ['1','3/2','9/8','1'], 'equivalence_groups': [[0,3],[1],[2]]}),
    'WML018': ({'bend_values': [8192,9216], 'lsb_msb': [[0,64],[0,72]], 'conflict_pairs': [['A','B']]}, {'bend_values': [8192,9216], 'lsb_msb': [[0,64],[0,72]], 'conflict_pairs': []}),
    'WML019': ({'base_onsets': [0,2,5], 'rotated_onsets': [1,3,6], 'cyclic_gaps': [2,3,3], 'balanced': True}, {'base_onsets': [0,1,2], 'rotated_onsets': [1,2,3], 'cyclic_gaps': [1,1,6], 'balanced': False}),
}
# Fraction is used for derivation, JSON observations contain ordinary numbers.
FIXED['GTR019'][0]['length'][1] = float(FIXED['GTR019'][0]['length'][1])
SCOPE = {
    'AUD019': 'Memoryless symmetric clip; exact finite real sample orders, no reconstruction or listening.',
    'AUD020': 'Circular unchanged frames; one window, weight sums only, no FFT or finite-edge claim.',
    'AUD021': 'Zero-state positive integer delay and constant real gain; finite impulse plus analytic geometric tail.',
    'GAS018': 'Normally incident pressure waves, positive real impedances, lossless stateless junction; power fractions normalized by incident power.',
    'GAS019': 'Authored Lorentzian POWER, exact half-power edges and defined center/full-bandwidth quotient, no pole conversion.',
    'GAS020': 'Ideal signed sine displacement averaged over a uniform normalized aperture wholly on the string; no electromagnetic response.',
    'GTR018': 'String 1 highest; D moves toward smaller numbers; continuous equal-stroke sweep only, no air reset or comfort proof.',
    'GTR019': 'Constant-wave-speed continuous ideal length; explicitly selected length or log-frequency trajectory, no fret contact.',
    'GTR020': 'Fixed mm positions, positive mm/s speed and extreme origin; muted crossings retained in geometry only.',
    'GAA017': 'Authored Boolean outcomes, fixed unbounded tempo steps, zero-based reversals and pre-update mean after stopping.',
    'GAA018': 'Unique immutable attempt ids, at most one Boolean feedback each; exact identity join, no transport or duplicate policy.',
    'GAA019': 'Exact contiguous directed integer semitone motifs; zero-based interval starts, all overlaps; no theme recognition.',
    'MCL018': 'Instantaneous pivot duration equality; each pivot in its own quarter coordinates, seconds and quarter BPM.',
    'MCL019': 'Main start, finite positive count, equal durations and no terminal turn; no historical realization.',
    'MCL020': 'Teaching F-only octave-specific state, reset at measure boundary, no tied notes; not MusicXML pitch decoding.',
    'WML017': 'Exact positive rational ratios, rational period above one and half-open canonical interval; no culture/perception claim.',
    'WML018': 'Authored interior 14-bit bend mapping and conventional channel scope; half-open notes, equal receiver sensitivity, no tails/device.',
    'WML019': 'Integer floor lattice or explicit onsets, declared rotation, all cyclic gaps; local max-min criterion only.',
}


def emit(code, case, observed, expected):
    print('\nOBSERVATION '+json.dumps(dict(code=code,case=case,observed=observed,expected=expected,scope=SCOPE[code]),ensure_ascii=False,allow_nan=False),flush=True)


def require(condition, code, case, diagnostic):
    if not condition:
        emit(code,case,{'input_diagnostic':diagnostic},{'declared_assumptions':True})
        raise AssertionError(f'{code}: {diagnostic}')


def observe(code, v, case='model'):
    def need(condition, diagnostic): require(condition,code,case,diagnostic)
    if code=='AUD019':
        t,g=v['threshold'],v['gain']; need(t>0,'threshold must be positive')
        def clip(x): return min(t,max(-t,x))
        a=[clip(g*x) for x in v['samples']]; b=[g*clip(x) for x in v['samples']]
        residual=[a[i]-b[i] for i in range(len(a))]
        return dict(A=a,B=b,residual=residual,commutes=all(x==0 for x in residual))
    if code=='AUD020':
        x,w,starts=v['samples'],v['window'],v['circular_starts']; n=len(x)
        need(n>0 and n==len(w),{'samples_length':n,'window_length':len(w)})
        need(all(type(i) is int for i in starts),'circular starts must be integers')
        weights=[sum(w[(i-start)%n] for start in starts) for i in range(n)]
        return dict(weight=weights,output=[x[i]*weights[i] for i in range(n)],perfect=all(a==1 for a in weights))
    if code=='AUD021':
        m,n,g=v['delay_samples'],v['count'],v['gain']; x=v['impulse']
        need(type(m) is int and m>0 and type(n) is int and n>0 and n==len(x),{'delay':m,'count':n,'impulse_length':len(x)})
        need(x==[1]+[0]*(n-1),'analytic tail requires a unit impulse')
        y=[]
        for i in range(n): y.append(x[i]+(g*y[i-m] if i>=m else 0))
        stable=abs(g)<1
        return dict(output=y,stable=stable,absolute_sum_infinite=1/(1-abs(g)) if stable else None)
    if code=='GAS018':
        z1,z2,p=v['impedance_left'],v['impedance_right'],v['incident_pressure']
        need(z1>0 and z2>0 and p!=0,'positive impedances and nonzero reference pressure required')
        # Solve continuity p+r=t and (p-r)/Z1=t/Z2, then normalize.
        reflected=p*(z2-z1)/(z1+z2); transmitted=p+reflected
        rf=(reflected*reflected/z1)/(p*p/z1); tf=(transmitted*transmitted/z2)/(p*p/z1)
        return dict(pressure_reflection=reflected/p,pressure_transmission=transmitted/p,reflected_fraction=rf,transmitted_fraction=tf,total=rf+tf)
    if code=='GAS019':
        f,b=v['center_hz'],v['halfwidth_hz']; need(f>0 and b>0,'positive center and halfwidth required')
        return dict(relative_power=[b*b/(b*b+(x-f)**2) for x in v['frequencies_hz']],half_power_edges_hz=[f-b,f+b],bandwidth_hz=2*b,Q=f/(2*b))
    if code=='GAS020':
        c,w=v['center_fraction'],v['width_fraction']; modes=v['modes']
        need(w>=0 and 0<=c-w/2<=c+w/2<=1,'aperture must remain inside normalized string')
        need(all(type(n) is int and n>0 for n in modes),'positive integer sine modes required')
        point=[math.sin(n*math.pi*c) for n in modes]
        # Independent antiderivative of sin(n*pi*x), normalized by aperture width.
        averaged=[point[i] if w==0 else (math.cos(n*math.pi*(c-w/2))-math.cos(n*math.pi*(c+w/2)))/(n*math.pi*w) for i,n in enumerate(modes)]
        return dict(point=point,aperture=averaged)
    if code=='GTR018':
        strings,strokes=v['strings'],v['strokes']
        need(len(strings)==len(strokes),{'strings_length':len(strings),'strokes_length':len(strokes)})
        need(all(s in ('D','U') for s in strokes),{'unsupported_strokes':[s for s in strokes if s not in ('D','U')]})
        need(all(type(s) is int and s>0 for s in strings),'positive string numbers required')
        legal=[]
        for i in range(1,len(strings)):
            repeated=strokes[i]==strokes[i-1] and strings[i]!=strings[i-1]
            legal.append(not repeated or (strings[i]<strings[i-1] if strokes[i]=='D' else strings[i]>strings[i-1]))
        return dict(transition_legal=legal,plan_legal=all(legal))
    if code=='GTR019':
        a,b,f,d=v['start_length'],v['end_length'],v['start_frequency_hz'],v['duration_s']; policy=v['policy']
        need(min(a,b,f,d)>0 and all(0<=t<=d for t in v['times_s']),'positive parameters and times within trajectory required')
        need(policy in ('linear_length','linear_log_frequency'),{'unsupported_policy':policy})
        lengths=[]; frequencies=[]
        for t in v['times_s']:
            u=t/d
            if policy=='linear_length': length=a+(b-a)*u; frequency=f*a/length
            elif policy=='linear_log_frequency': frequency=math.exp(math.log(f)+u*math.log(a/b)); length=f*a/frequency
            lengths.append(length); frequencies.append(frequency)
        return dict(length=lengths,frequency_hz=frequencies)
    if code=='GTR020':
        p,indices,speed,direction=v['positions_mm'],v['sounding_indices'],v['speed_mm_s'],v['direction']
        need(bool(p) and speed>0 and direction in (-1,1),'nonempty positions, positive speed and signed direction required')
        need(bool(indices) and len(set(indices))==len(indices) and all(type(i) is int and 0<=i<len(p) for i in indices),'sounding indices must be distinct and in range')
        origin=min(p) if direction==1 else max(p)
        events=sorted([[abs(p[i]-origin)/speed,i] for i in indices])
        return dict(events_time_s_and_index=events,spread_s=events[-1][0]-events[0][0])
    if code=='GAA017':
        tempo,step,required=v['initial_tempo'],v['step'],v['required_reversals']; passes=v['passes']
        need(step>0 and type(required) is int and required>0 and all(type(p) is bool for p in passes),'positive step/reversal count and complete Boolean outcomes required')
        before=[]; after=[]; reversals=[]; previous=None; stop=None
        for i,passed in enumerate(passes):
            before.append(tempo); direction=1 if passed else -1
            if previous is not None and direction!=previous: reversals.append(i)
            tempo+=step*direction; after.append(tempo); previous=direction
            if len(reversals)==required: stop=i; break
        estimate=sum(before[i] for i in reversals)/len(reversals) if stop is not None else None
        return dict(pre_update_tempo=before,post_update_tempo=after,reversal_indices=reversals,stop_index=stop,estimate_tempo=estimate)
    if code=='GAA018':
        ids=v['attempt_ids']; feedback=v['feedback']
        need(len(set(ids))==len(ids),'attempt identities must be unique')
        incoming=[f['attempt_id'] for f in feedback]
        need(len(set(incoming))==len(incoming) and all(type(f['pass']) is bool for f in feedback),'at most one Boolean feedback per identity required')
        ledger=dict.fromkeys(ids); rejected=[]
        for f in feedback:
            if f['attempt_id'] in ledger: ledger[f['attempt_id']]=f['pass']
            else: rejected.append(f['attempt_id'])
        return dict(ledger=[{'attempt_id':i,'pass':ledger[i]} for i in ids],rejected_ids=rejected,unresolved_ids=[i for i in ids if ledger[i] is None])
    if code=='GAA019':
        stream,motif=v['interval_stream'],v['motif']; need(bool(motif) and all(type(n) is int for n in stream+motif),'nonempty integer directed motif required')
        starts=[i for i in range(len(stream)-len(motif)+1) if stream[i:i+len(motif)]==motif]
        return dict(match_starts=starts,count=len(starts),stream_multiset={str(k):n for k,n in Counter(stream).items()})
    if code=='MCL018':
        bpm,old,new=v['old_quarter_bpm'],v['old_pivot_quarters'],v['new_pivot_quarters']; need(min(bpm,old,new)>0,'positive tempo and pivot lengths required')
        quarter=60/bpm; pivot=quarter*old; destination=pivot/new
        return dict(old_quarter_s=quarter,pivot_s=pivot,new_quarter_s=destination,new_quarter_bpm=60/destination)
    if code=='MCL019':
        n,d=v['note_count'],v['duration_s']; need(type(n) is int and n>0 and d>0,'positive integer count and total duration required')
        duration=Fraction(str(d))/n; pitches=[v['main_pitch'] if i%2==0 else v['alternate_pitch'] for i in range(n)]
        return dict(pitches=pitches,onsets_s=[float(i*duration) for i in range(n)],duration_each_s=float(duration),terminal_pitch=pitches[-1])
    if code=='MCL020':
        state={}; previous=None; alters=[]; pitches=[]; events=v['events']
        need(type(v['reset_at_bar']) is bool,'reset policy must be Boolean')
        need(all(e['octave'] in (4,5) for e in events),'teaching fixture supports only F4 and F5')
        need(all(events[i]['measure']>=events[i-1]['measure'] for i in range(1,len(events))),'measure events must be chronological')
        for event in events:
            if event['measure']!=previous and v['reset_at_bar']: state.clear()
            octave=event['octave']; explicit=event['explicit_alter']
            if explicit is not None: state[octave]=explicit
            alter=state.get(octave,v['key_F_alter']); alters.append(alter); pitches.append(12*(octave+1)+5+alter); previous=event['measure']
        return dict(effective_alters=alters,pitches=pitches)
    if code=='WML017':
        period=Fraction(v['period_ratio']); ratios=list(map(Fraction,v['ratios'])); need(period>1 and all(r>0 for r in ratios),'positive ratios and period strictly above one required')
        counts=[]; canonical=[]; groups={}
        for i,ratio in enumerate(ratios):
            count=0
            while ratio>=period: ratio/=period; count+=1
            while ratio<1: ratio*=period; count-=1
            counts.append(count); canonical.append(str(ratio)); groups.setdefault(ratio,[]).append(i)
        return dict(period_counts=counts,canonical_ratios=canonical,equivalence_groups=list(groups.values()))
    if code=='WML018':
        sensitivity=v['sensitivity_cents']; notes=v['notes']; need(sensitivity>0,'positive receiver sensitivity required')
        need(len({n['id'] for n in notes})==len(notes),'note identities must be unique')
        need(all(type(n['channel']) is int and 0<=n['channel']<16 and n['start']<n['end'] for n in notes),'channels 0..15 and positive half-open supports required')
        bends=[8192+math.floor(8192*n['offset_cents']/sensitivity+.5) for n in notes]
        need(all(0<=b<16384 for b in bends),{'out_of_14_bit_range':bends})
        conflicts=[]
        for i,a in enumerate(notes):
            for j in range(i+1,len(notes)):
                b=notes[j]
                if a['channel']==b['channel'] and max(a['start'],b['start'])<min(a['end'],b['end']) and bends[i]!=bends[j]: conflicts.append([a['id'],b['id']])
        return dict(bend_values=bends,lsb_msb=[[b%128,b//128] for b in bends],conflict_pairs=conflicts)
    if code=='WML019':
        n,k,rotation,policy=v['pulse_count'],v['onset_count'],v['rotation'],v['policy']
        need(type(n) is int and type(k) is int and 0<k<=n and type(rotation) is int,'integer pulse/onset counts and rotation required')
        need(policy in ('floor_lattice','supplied'),{'unsupported_policy':policy})
        if policy=='floor_lattice': base=[i*n//k for i in range(k)]
        elif policy=='supplied': base=v['supplied_onsets']
        need(len(base)==k and len(set(base))==k and all(type(i) is int and 0<=i<n for i in base),'onsets must be distinct, in range and match declared count')
        rotated=sorted((i+rotation)%n for i in base)
        gaps=[rotated[i+1]-rotated[i] for i in range(k-1)]+[n+rotated[0]-rotated[-1]]
        return dict(base_onsets=base,rotated_onsets=rotated,cyclic_gaps=gaps,balanced=max(gaps)-min(gaps)<=1)
    require(False,code,case,{'unsupported_course':code})


class UnitA(unittest.TestCase):
    def same(self, actual, expected, path='result'):
        if isinstance(expected,dict):
            self.assertIsInstance(actual,dict,path); self.assertEqual(set(actual),set(expected),path)
            for key,value in expected.items(): self.same(actual[key],value,path+'.'+key)
        elif isinstance(expected,list):
            self.assertIsInstance(actual,list,path); self.assertEqual(len(actual),len(expected),path)
            for i,value in enumerate(expected): self.same(actual[i],value,f'{path}[{i}]')
        elif isinstance(expected,bool): self.assertIs(actual,expected,path)
        elif isinstance(expected,(int,float)):
            self.assertNotIsInstance(actual,bool,path)
            self.assertTrue(math.isfinite(actual) and math.isclose(actual,expected,rel_tol=1e-11,abs_tol=1e-11),f'{path}: {actual!r} != {expected!r}')
        else: self.assertEqual(actual,expected,path)

    def check_course(self, code):
        model=COURSES[code]['authored_model']
        for index,case in enumerate(('model','negative')):
            entry=model if case=='model' else model['negative_control']
            result=observe(code,entry['values'],case)
            emit(code,case,result,FIXED[code][index])
            self.same(result,FIXED[code][index])
            self.same(result,entry['expected'])


def course_test(code):
    def test(self): self.check_course(code)
    return test


for _code in FIXED: setattr(UnitA,'test_'+_code,course_test(_code))

if __name__=='__main__': unittest.main(verbosity=2)
