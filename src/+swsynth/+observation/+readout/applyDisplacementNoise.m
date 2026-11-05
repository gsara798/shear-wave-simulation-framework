function [Umeasured,D] = applyDisplacementNoise(Uin,cfg,spacing,z_m,frequency_hz,seed)
%APPLYDISPLACEMENTNOISE Boukraa-like temporal displacement-readout disturbance.
% Uin is the already projected complex mechanical phasor (z-x or z-y-x).
% This phenomenological model is NOT an IQ/Loupas or RF tracking simulation.
% A real harmonic displacement is reconstructed frame by frame, independent
% additive/multiplicative correlated noise is applied, and the complex phasor
% is recovered by a cosine/sine least-squares projection.
arguments
    Uin {mustBeNumeric}
    cfg (1,1) struct
    spacing (1,:) double {mustBePositive}
    z_m {mustBeNumeric}
    frequency_hz (1,1) double {mustBePositive}
    seed (1,1) double
end
Umeasured=Uin;
D=struct("enabled",false,"model","none","seed",seed, ...
    "snr_db",Inf,"relative_perturbation_norm",0);
if ~isfield(cfg,"enabled") || ~logical(cfg.enabled)
    return
end
swsynth.observation.readout.validateConfig(cfg);
if ndims(Uin)~=numel(spacing) || ~ismember(ndims(Uin),[2,3])
    error("swsynth:InvalidReadoutNoise", ...
        "Readout expects z-x or z-y-x arrays with matching grid spacings.");
end
if numel(z_m)~=size(Uin,1) || any(~isfinite(z_m(:))) || ...
        any(~isfinite(real(Uin(:)))) || any(~isfinite(imag(Uin(:))))
    error("swsynth:InvalidReadoutNoise", ...
        "Readout requires finite data and one depth coordinate per z row.");
end
nt=getf(cfg,"nt",32);
prf=getf(cfg,"prf_hz",4000);
if prf<=2*frequency_hz
    error("swsynth:InvalidReadoutNoise", ...
        "readout_noise.prf_hz must exceed twice harmonic.frequency_hz.");
end
strength=getf(cfg,"strength",1);
level=lower(string(gets(cfg,"level","medium")));
[baseA,baseM]=levelSigmas(level);
frequencyGain=getf(cfg,"frequency_noise_gain",1);
noiseGain=sqrt(nt/2)*frequencyGain;
sigmaA=baseA*noiseGain*strength;
sigmaM=baseM*noiseGain*strength;
scale=amplitudeScale(Uin,cfg);

D.enabled=true;
D.model="boukraa_like_temporal_displacement_readout";
D.level=level;
D.strength=strength;
D.nt=nt;
D.prf_hz=prf;
D.correlation_m=getf(cfg,"correlation_m",0);
D.amplitude_normalization=string(gets(cfg,"amplitude_normalization","max_abs"));
D.reference_amplitude=scale;
D.additive_sigma=scale*sigmaA;
D.multiplicative_sigma=sigmaM;
D.frequency_noise_gain=frequencyGain;
if strength==0
    return
end

% SimCore's depth term. Acoustic-echo weighting is intentionally absent:
% swsynth V2 does not simulate ultrasound backscatter or beamforming.
depth=double(z_m(:));
zn=(depth-min(depth))/max(max(depth)-min(depth),eps);
power=getf(cfg,"depth_weight_power",3);
profile=lower(string(gets(cfg,"depth_profile","exponential_0_to_1")));
switch profile
    case "none"
        wz=ones(size(zn));
    case "linear_0_to_1"
        wz=zn;
    case "exponential_0_to_1"
        if power==0
            wz=zn;
        else
            wz=(exp(power*zn)-1)/max(exp(power)-1,eps);
        end
end
wz=min(getf(cfg,"depth_noise_floor",0.12)+wz, ...
    getf(cfg,"max_weight",8));
shape=ones(1,ndims(Uin)); shape(1)=numel(wz);
repetitions=size(Uin); repetitions(1)=1;
W=repmat(reshape(wz,shape),repetitions);
D.depth_weight_z=wz;
D.min_weight=min(wz);
D.max_weight=max(wz);

stream=RandStream("mt19937ar","Seed",seed);
omega=2*pi*frequency_hz;
t=(0:nt-1)/prf;
c=cos(omega*t); s=sin(omega*t);
C=sum(c.^2); S=sum(s.^2); CS=sum(c.*s);
den=C*S-CS^2;
if den<=1e-10*max(C*S,eps)
    error("swsynth:InvalidReadoutNoise", ...
        "Temporal harmonic basis is singular for this PRF/Nt/frequency.");
end
Uwork=Uin/scale;
rhsC=zeros(size(Uwork)); rhsS=zeros(size(Uwork));
for it=1:nt
    uExact=real(Uwork.*exp(1i*omega*t(it)));
    xiA=correlatedRealNoise(size(Uin),spacing,D.correlation_m,stream);
    xiM=correlatedRealNoise(size(Uin),spacing,D.correlation_m,stream);
    uNoisy=uExact+W.*sigmaA.*xiA+W.*sigmaM.*xiM.*uExact;
    rhsC=rhsC+c(it).*uNoisy;
    rhsS=rhsS+s(it).*uNoisy;
end
a=(S.*rhsC-CS.*rhsS)./den;
b=(CS.*rhsC-C.*rhsS)./den;
Umeasured=scale.*complex(a,b);
difference=Umeasured-Uin;
D.relative_perturbation_norm=norm(difference(:))/max(norm(Uin(:)),eps);
D.snr_db=20*log10(norm(Uin(:))/max(norm(difference(:)),eps));
end

function [additive,multiplicative]=levelSigmas(level)
switch level
    case {"low","soft"}
        additive=0.010; multiplicative=0.005;
    case {"medium","moderate"}
        additive=0.030; multiplicative=0.010;
    case {"high","hard"}
        additive=0.080; multiplicative=0.035;
end
end

function scale=amplitudeScale(U,cfg)
mode=lower(string(gets(cfg,"amplitude_normalization","max_abs")));
amp=abs(U(:));
switch mode
    case "max_abs"
        scale=max(amp);
    case "rms"
        scale=sqrt(mean(amp.^2));
    case "fixed_reference"
        scale=getf(cfg,"reference_amplitude",NaN);
    case "none"
        scale=1;
end
if ~isfinite(scale) || scale<=0
    scale=1;
end
end

function xi=correlatedRealNoise(sz,spacing,correlation,stream)
xi=randn(stream,sz);
if correlation>0
    for d=1:numel(spacing)
        sig=correlation/spacing(d);
        if sig<=0,continue,end
        radius=max(1,ceil(3*sig));
        q=-radius:radius;
        k=exp(-0.5*(q./sig).^2);
        k=k/sum(k);
        sh=ones(1,numel(spacing)); sh(d)=numel(k);
        xi=convn(xi,reshape(k,sh),"same");
    end
end
xi=xi/max(std(xi(:)),eps);
end

function v=getf(s,key,default)
if isfield(s,key),v=double(s.(key));else,v=default;end
end

function v=gets(s,key,default)
if isfield(s,key),v=string(s.(key));else,v=string(default);end
end
