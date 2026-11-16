"""Independent finite-case characterization, without engine or learner execution."""
import cmath
import json
import math
import unittest
from fractions import Fraction
from pathlib import Path

EVIDENCE = Path(__file__).resolve().parents[1]
PACKET = json.loads((EVIDENCE / 'unit-a.json').read_text(encoding='utf-8'))
COURSES = {c['code']: c for c in PACKET['courses']}

# Reviewer derivations: polynomial products, unit-circle division, inverse maps,
# sine integral, characteristic polynomial, normal equations and finite ledgers.
# These oracles are intentionally independent of the packet expected fields.
FIXED = {
    'AUD022': ({'full':[1,2.5,1.25,.5], 'emitted':[1,2.5,1.25,.5], 'lost':[], 'complete':True, 'phases':['input','input','flush','flush'], 'final_history':[0,0], 'pending_flush_frames':0}, {'full':[1,2.5,1.25,.5], 'emitted':[1,2.5], 'lost':[1.25,.5], 'complete':False, 'phases':['input','input'], 'final_history':[2,1], 'pending_flush_frames':2}),
    'AUD023': ({'H_real':4/5,'H_imag':-3/5,'magnitude':1,'identity':False}, {'H_real':8/5,'H_imag':-6/5,'magnitude':2,'identity':False}),
    'AUD024': ({'analog_rad_s':16,'achieved_hz':2,'error_hz':0}, {'analog_rad_s':4*math.pi,'achieved_hz':8*math.atan(math.pi/4)/math.pi,'error_hz':8*math.atan(math.pi/4)/math.pi-2}),
    'AUD025': ({'encoded':[0,0,0,0],'decoded':[3/8,1/8,-1/8,-3/8],'errors':[3/8,1/8,-1/8,-3/8],'mean':0,'mse':5/64}, {'encoded':[0,0,0,1],'decoded':[0,0,0,1],'errors':[-1/4,-1/4,-1/4,3/4],'mean':0,'mse':3/16}),
    'GAS021': ({'modal_mass':3,'mass_normalized_amplitude':math.sqrt(3)/2,'energy':6,'reported_energy':6}, {'modal_mass':3,'mass_normalized_amplitude':math.sqrt(3)/2,'energy':6,'reported_energy':12}),
    'GAS022': ({'frequency_ratio':.5}, {'frequency_ratio':1/math.sqrt(2)}),
    'GAS023': ({'omega':18,'phase_speed':6,'group_speed':12}, {'omega':6,'phase_speed':2,'group_speed':2}),
    'GAS024': ({'lower':[10-math.sqrt(13),8,10-math.sqrt(13)],'upper':[10+math.sqrt(13),12,10+math.sqrt(13)],'gaps':[2*math.sqrt(13),4,2*math.sqrt(13)],'minimum_gap':4}, {'lower':[7,10,7],'upper':[13,10,13],'gaps':[6,0,6],'minimum_gap':0}),
    'GAS025': ({'complex_power':[0,-1],'active':0,'reactive':-1}, {'complex_power':[1,0],'active':1,'reactive':0}),
    'GTR021': ({'intervals':[[-1,7],[8,11]],'gap':1,'clear':True}, {'intervals':[[-1,9],[8,11]],'gap':-1,'clear':False}),
    'GTR022': ({'positions':[300,350],'slope':5}, {'positions':[300,320],'slope':2}),
    'GTR023': ({'intercept':3,'slope':1,'residuals':[0,0,0],'fits':True}, {'intercept':17/6,'slope':3/2,'residuals':[1/6,-1/3,1/6],'fits':False}),
    'GTR024': ({'ready':[True,True,True],'violations':[]}, {'ready':[True,True,False],'violations':[2]}),
    'GTR025': ({'join_ab':[2,3,4],'join_abc':[2,3,4],'commutative':True,'associative':True,'idempotent':True,'alternate_join':[2,3,2],'aggregate_distinguishes':True}, {'join_ab':[2,3,4],'join_abc':[2,3,4],'commutative':True,'associative':True,'idempotent':True,'alternate_join':[2,3,4],'aggregate_distinguishes':False}),
    'WML020': ({'occupancy':[1,1,1,1],'collisions':[],'gaps':[],'exclusive_complete':True}, {'occupancy':[1,0,2,1],'collisions':[2],'gaps':[1],'exclusive_complete':False}),
    'WML021': ({'common':[[300,3,2]]}, {'common':[]}),
    'WML022': ({'shifts':[2],'unique':True}, {'shifts':[0,2],'unique':False}),
    'WML023': ({'witness':[0,2,4],'consumed':3,'accepted':True}, {'witness':[4],'consumed':1,'accepted':False}),
}
KEYS = {
    'AUD022':'x h emit_count', 'AUD023':'a omega_over_pi numerator_scale',
    'AUD024':'sample_rate_hz target_hz prewarp', 'AUD025':'x dither subtract',
    'GAS021':'linear_density length omega amplitude assumed_modal_mass',
    'GAS022':'area_ratio volume_ratio effective_length_ratio',
    'GAS023':'coefficient wavenumber power', 'GAS024':'center detunings coupling',
    'GAS025':'pressure volume_velocity phasor_kind',
    'GTR021':'centers radii displacements',
    'GTR022':'nuts scales transverse fret use_common_scale',
    'GTR023':'transverse targets tolerance', 'GTR024':'attacks recovery held_support',
    'GTR025':'a b c alternate_a', 'WML020':'slots voices',
    'WML021':'fundamentals_hz max_partial', 'WML022':'source target',
    'WML023':'landmarks events',
}
SCOPE = {
    'AUD022':'Causal finite real convolution, zero history, bounded input/flush schedule; no streaming engine or export.',
    'AUD023':'Stable real first-order steady complex response at one frequency; no transient or audibility claim.',
    'AUD024':'Bilinear frequency map with factor 2*fs and principal atan; one target below Nyquist, no coefficients generated.',
    'AUD025':'Unbounded unit quantizer, floor(v+0.5), fixed deterministic ensemble; no stochastic independence or audio export.',
    'GAS021':'Uniform ideal integer sine mode, peak normalization and turning-point mechanical energy in SI units.',
    'GAS022':'Same sound speed and compact small-motion Helmholtz cavity; positive dimensionless ratios and effective neck length.',
    'GAS023':'Positive-k ideal power-law dispersion; local narrow-band derivative, no material or broadband pulse model.',
    'GAS024':'Positive real symmetric squared-frequency eigenvalues over supplied finite detunings, no damping or physical fit.',
    'GAS025':'Same-port pressure and volume velocity, peak exp(j*omega*t) phasors, flow into port; no intensity field.',
    'GTR021':'Two independent lateral swept intervals in one slice and common length units; touching is not clear.',
    'GTR022':'Two parallel ideal string axes, per-string nut/scale and equal temperament; no compensation or manufactured fret.',
    'GTR023':'Unweighted physical-length least squares for a rigid affine bar; maximum residual policy, no pitch optimization.',
    'GTR024':'Sorted stipulated finger deadlines, equality allowed; held support validated separately and not a recovery resource.',
    'GTR025':'Equal nonnegative integer stop maps, component maximum and retained device distinction; no physical capo fit.',
    'WML020':'Unique integer onsets per voice on a finite grid; exactly one voice at every declared slot, no duration/cultural claim.',
    'WML021':'Two positive integer fundamentals, exact harmonic inventory intersection at bounded indices, no near matches.',
    'WML022':'Equal nonempty exact directed label cycles; all shifts target[i]=source[(i+s)%N], no accent/timing equivalence.',
    'WML023':'Finite ordered-subsequence scan, extra events ignored and repeated landmarks consume distinct events; no style claim.',
}


def emit(code, case, observed, expected):
    print('\nOBSERVATION '+json.dumps(dict(code=code, case=case, observed=observed,
          expected=expected, scope=SCOPE[code]), ensure_ascii=False, allow_nan=False), flush=True)


def observe(code, v, case='model'):
    """Compute only the requested teaching cases; expose them to an in-memory probe."""
    def need(condition, diagnostic):
        if not condition:
            emit(code, case, {'input_diagnostic':diagnostic}, {'declared_assumptions':True})
            raise AssertionError(f'{code}: {diagnostic}')
    need(code in KEYS, 'unsupported course')
    need(set(v)==set(KEYS[code].split()), {'actual_keys':sorted(v), 'required_keys':KEYS[code].split()})
    if code=='AUD022':
        x,h,count=v['x'],v['h'],v['emit_count']; size=len(x)+len(h)-1
        need(bool(x) and bool(h) and type(count) is int and 0<=count<=size, 'nonempty inputs and emission inside full support required')
        full=[0]*size
        for i,a in enumerate(x):
            for j,b in enumerate(h): full[i+j]+=a*b
        history=[0]*(len(h)-1); phases=[]
        for n in range(count):
            fed=x[n] if n<len(x) else 0; phases.append('input' if n<len(x) else 'flush')
            history=([fed]+history)[:len(h)-1]
        return dict(full=full,emitted=full[:count],lost=full[count:],complete=count==size,
                    phases=phases,final_history=history,pending_flush_frames=len(h)-1-max(0,count-len(x)))
    if code=='AUD023':
        a,f,scale=v['a'],v['omega_over_pi'],v['numerator_scale'];need(abs(a)<1,'stable real first-order coefficient required')
        z=cmath.exp(-1j*math.pi*f); response=scale*(a+z)/(1+a*z)
        return dict(H_real=response.real,H_imag=response.imag,magnitude=abs(response),identity=abs(response-1)<1e-12)
    if code=='AUD024':
        fs,f,pre=v['sample_rate_hz'],v['target_hz'],v['prewarp'];need(fs>0 and 0<f<fs/2 and type(pre) is bool,'positive clock, interior target and Boolean map policy required')
        angular=2*fs*math.tan(math.pi*f/fs) if pre else 2*math.pi*f
        achieved=fs*math.atan(angular/(2*fs))/math.pi
        return dict(analog_rad_s=angular,achieved_hz=achieved,error_hz=achieved-f)
    if code=='AUD025':
        x,offsets,subtract=v['x'],v['dither'],v['subtract'];need(bool(offsets) and type(subtract) is bool,'nonempty offsets and Boolean subtraction policy required')
        encoded=[math.floor(x+d+.5) for d in offsets]
        decoded=[encoded[i]-(d if subtract else 0) for i,d in enumerate(offsets)]
        errors=[y-x for y in decoded]
        return dict(encoded=encoded,decoded=decoded,errors=errors,mean=sum(errors)/len(errors),mse=sum(e*e for e in errors)/len(errors))
    if code=='GAS021':
        mu,length,w,a,mass=v['linear_density'],v['length'],v['omega'],v['amplitude'],v['assumed_modal_mass']
        need(mu>0 and length>0 and w>0 and (mass is None or mass>0),'positive density, length, frequency and used mass required')
        # Integral mu*sin(n*pi*x/L)^2 dx = mu*L/2 for any positive integer n.
        effective=mu*length/2; normalized=a*math.sqrt(effective)
        return dict(modal_mass=effective,mass_normalized_amplitude=normalized,energy=(w*normalized)**2/2,reported_energy=(effective if mass is None else mass)*w*w*a*a/2)
    if code=='GAS022':
        area,volume,length=v['area_ratio'],v['volume_ratio'],v['effective_length_ratio'];need(min(area,volume,length)>0,'positive geometric ratios required')
        return dict(frequency_ratio=math.sqrt(area)/math.sqrt(volume)/math.sqrt(length))
    if code=='GAS023':
        c,k,p=v['coefficient'],v['wavenumber'],v['power'];need(c>0 and k>0,'positive coefficient and wavenumber required')
        omega=c*k**p
        return dict(omega=omega,phase_speed=omega/k,group_speed=p*omega/k)
    if code=='GAS024':
        c,detunings,g=v['center'],v['detunings'],v['coupling'];need(bool(detunings),'nonempty supplied sweep required')
        lower=[];upper=[];gaps=[]
        for d in detunings:
            trace=2*c; determinant=(c+d)*(c-d)-g*g
            discriminant=trace*trace-4*determinant;need(discriminant>=0,'real symmetric roots required')
            lo=(trace-math.sqrt(discriminant))/2;hi=(trace+math.sqrt(discriminant))/2
            need(lo>0,'selected squared-frequency eigenvalues must be positive')
            lower.append(lo);upper.append(hi);gaps.append(hi-lo)
        return dict(lower=lower,upper=upper,gaps=gaps,minimum_gap=min(gaps))
    if code=='GAS025':
        need(v['phasor_kind']=='peak' and len(v['pressure'])==len(v['volume_velocity'])==2,'two real/imag components and peak normalization required')
        p=complex(*v['pressure']);u=complex(*v['volume_velocity']);power=p*u.conjugate()/2
        return dict(complex_power=[power.real,power.imag],active=power.real,reactive=power.imag)
    if code=='GTR021':
        centers,radii,ranges=v['centers'],v['radii'],v['displacements']
        need(len(centers)==len(radii)==len(ranges)==2,'exactly two paired string envelopes required')
        need(all(r>=0 for r in radii) and all(len(d)==2 and d[0]<=d[1] for d in ranges),'nonnegative radii and ordered min/max ranges required')
        intervals=[[centers[i]+ranges[i][0]-radii[i],centers[i]+ranges[i][1]+radii[i]] for i in range(2)]
        gap=intervals[1][0]-intervals[0][1]
        return dict(intervals=intervals,gap=gap,clear=gap>0)
    if code=='GTR022':
        nuts,scales,y,f,common=v['nuts'],v['scales'],v['transverse'],v['fret'],v['use_common_scale']
        need(len(nuts)==len(scales)==len(y)==2 and y[0]!=y[1],'two paired endpoints with distinct transverse coordinates required')
        need(all(s>0 for s in scales) and type(f) is int and f>=0 and type(common) is bool,'positive scales, nonnegative fret and Boolean common-scale policy required')
        positions=[nuts[i]+(scales[0] if common else scales[i])*(1-2**(-f/12)) for i in range(2)]
        return dict(positions=positions,slope=(positions[1]-positions[0])/(y[1]-y[0]))
    if code=='GTR023':
        y,x,tolerance=v['transverse'],v['targets'],v['tolerance'];n=len(y)
        need(n==len(x) and n>=2 and len(set(y))==n and tolerance>=0,'paired distinct transverse coordinates and nonnegative tolerance required')
        # Solve the two unweighted normal equations with exact decimal rationals.
        y=list(map(lambda z:Fraction(str(z)),y));x=list(map(lambda z:Fraction(str(z)),x))
        sy,sx,syy,syx=sum(y),sum(x),sum(z*z for z in y),sum(y[i]*x[i] for i in range(n))
        denominator=n*syy-sy*sy;b=(n*syx-sy*sx)/denominator;a=(sx-b*sy)/n
        residuals=[x[i]-a-b*y[i] for i in range(n)]
        return dict(intercept=float(a),slope=float(b),residuals=list(map(float,residuals)),fits=max(map(abs,residuals))<=Fraction(str(tolerance)))
    if code=='GTR024':
        attacks,recovery,support=v['attacks'],v['recovery'],v['held_support']
        need(all(len(a)==2 for a in attacks) and len(support)==2 and support[0]<=support[1],'paired attacks and ordered separate held support required')
        need(set(recovery)=={a[0] for a in attacks} and all(t>=0 for t in recovery.values()),'all and only attack resources need nonnegative recovery')
        need(all(attacks[i][1]>=attacks[i-1][1] for i in range(1,len(attacks))),'attacks must be chronological')
        deadlines={};ready=[]
        for finger,time in attacks:
            ready.append(finger not in deadlines or time>=deadlines[finger]);deadlines[finger]=time+recovery[finger]
        return dict(ready=ready,violations=[i for i,ok in enumerate(ready) if not ok])
    if code=='GTR025':
        arrays=[v[k] for k in ('a','b','c','alternate_a')];n=len(arrays[0])
        need(n>0 and all(len(a)==n and all(type(x) is int and x>=0 for x in a) for a in arrays),'equal nonempty nonnegative integer stop maps required')
        a,b,c,alternate=arrays
        def join(x,y): return [max(x[i],y[i]) for i in range(n)]
        ab=join(a,b);abc=join(ab,c);other=join(alternate,b)
        return dict(join_ab=ab,join_abc=abc,commutative=ab==join(b,a),associative=abc==join(a,join(b,c)),idempotent=join(a,a)==a,alternate_join=other,aggregate_distinguishes=ab!=other)
    if code=='WML020':
        slots,voices=v['slots'],v['voices'];need(type(slots) is int and slots>0,'positive finite slot count required')
        need(bool(voices) and all(len(set(a))==len(a) and all(type(i) is int and 0<=i<slots for i in a) for a in voices.values()),'voice slots must be unique integers inside the grid')
        occupancy=[0]*slots
        for onsets in voices.values():
            for t in onsets:occupancy[t]+=1
        return dict(occupancy=occupancy,collisions=[i for i,c in enumerate(occupancy) if c>1],gaps=[i for i,c in enumerate(occupancy) if c==0],exclusive_complete=all(c==1 for c in occupancy))
    if code=='WML021':
        f,n=v['fundamentals_hz'],v['max_partial'];need(len(f)==2 and all(type(x) is int and x>0 for x in f) and type(n) is int and n>0,'two positive integer fundamentals and finite positive index cap required')
        left={i*f[0]:i for i in range(1,n+1)};right={i*f[1]:i for i in range(1,n+1)}
        return dict(common=[[freq,left[freq],right[freq]] for freq in sorted(left.keys() & right.keys())])
    if code=='WML022':
        source,target=v['source'],v['target'];n=len(source);need(n>0 and n==len(target),'equal nonempty directed label cycles required')
        shifts=[s for s in range(n) if source[s:]+source[:s]==target]
        return dict(shifts=shifts,unique=len(shifts)==1)
    if code=='WML023':
        landmarks,events=v['landmarks'],v['events'];witness=[];cursor=0
        for i,label in enumerate(events):
            if cursor<len(landmarks) and label==landmarks[cursor]:witness.append(i);cursor+=1
        return dict(witness=witness,consumed=cursor,accepted=cursor==len(landmarks))


class UnitA(unittest.TestCase):
    def same(self, observed, expected, path='result'):
        if isinstance(expected,dict):
            self.assertIsInstance(observed,dict,path);self.assertEqual(set(observed),set(expected),path)
            for key,value in expected.items():self.same(observed[key],value,path+'.'+key)
        elif isinstance(expected,list):
            self.assertIsInstance(observed,list,path);self.assertEqual(len(observed),len(expected),path)
            for i,value in enumerate(expected):self.same(observed[i],value,f'{path}[{i}]')
        elif isinstance(expected,bool):self.assertIs(observed,expected,path)
        elif isinstance(expected,(int,float)):
            self.assertNotIsInstance(observed,bool,path)
            self.assertTrue(math.isfinite(observed) and math.isclose(observed,expected,rel_tol=1e-11,abs_tol=1e-11),f'{path}: {observed!r} != {expected!r}')
        else:self.assertEqual(observed,expected,path)

    def check_course(self, code):
        model=COURSES[code]['authored_model']
        for index,case in enumerate(('model','negative')):
            entry=model if case=='model' else model['negative_control']
            observed=observe(code,entry['values'],case)
            emit(code,case,observed,FIXED[code][index])
            self.same(observed,FIXED[code][index])
            self.same(observed,entry['expected'])

    def test_AUD022(self):self.check_course('AUD022')
    def test_AUD023(self):self.check_course('AUD023')
    def test_AUD024(self):self.check_course('AUD024')
    def test_AUD025(self):self.check_course('AUD025')
    def test_GAS021(self):self.check_course('GAS021')
    def test_GAS022(self):self.check_course('GAS022')
    def test_GAS023(self):self.check_course('GAS023')
    def test_GAS024(self):self.check_course('GAS024')
    def test_GAS025(self):self.check_course('GAS025')
    def test_GTR021(self):self.check_course('GTR021')
    def test_GTR022(self):self.check_course('GTR022')
    def test_GTR023(self):self.check_course('GTR023')
    def test_GTR024(self):self.check_course('GTR024')
    def test_GTR025(self):self.check_course('GTR025')
    def test_WML020(self):self.check_course('WML020')
    def test_WML021(self):self.check_course('WML021')
    def test_WML022(self):self.check_course('WML022')
    def test_WML023(self):self.check_course('WML023')


if __name__=='__main__':unittest.main(verbosity=2)
