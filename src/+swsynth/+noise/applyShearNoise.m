function [U,D] = applyShearNoise(Uclean,cfg,spacing,seed)
%APPLYSHEARNOISE Stochastic shear-field perturbation before observation readout.
% This is a field-level phenomenological disturbance, not ultrasound noise.
% Does not change clean travel times or implement attenuation/scattering.
arguments
    Uclean {mustBeNumeric}
    cfg (1,1) struct
    spacing (1,:) double
    seed (1,1) double
end
D=struct("enabled",false,"model","none","relative_perturbation_norm",0, ...
    "snr_db",Inf,"seed",seed);
U=Uclean;
if ~isfield(cfg,"enabled") || ~logical(cfg.enabled)
    return
end
swsynth.noise.validateConfig(cfg);
stream=RandStream("mt19937ar","Seed",seed);
ampStd=getf(cfg,"source_amplitude_jitter_std",0);
phaseStd=getf(cfg,"source_phase_jitter_cycles_std",0);
% The global jitter below describes variation of a whole acquisition.
% Per-source jitter is controlled separately by sources.excitation.
factor=max(0,1+ampStd*randn(stream))* ...
    exp(1i*2*pi*phaseStd*randn(stream));
U=Uclean.*factor;
base=getf(cfg,"propagation_relative_std",0);
if base>0
    correlation=getf(cfg,"correlation_m",0);
    R=randn(stream,size(Uclean));
    I=randn(stream,size(Uclean));
    if correlation>0
        R=correlate(R,spacing,correlation);
        I=correlate(I,spacing,correlation);
    end
    R=R./max(std(R(:)),eps);
    I=I./max(std(I(:)),eps);
    floorFrac=getf(cfg,"amplitude_floor_fraction",0.05);
    a=abs(Uclean);
    positive=a(a>0 & isfinite(a));
    reference=0;
    if ~isempty(positive)
        reference=median(positive);
    end
    sigma=base.*max(a,floorFrac*reference);
    U=U+sigma.*complex(R,I)./sqrt(2);
end
difference=U-Uclean;
D.enabled=true;
D.model="source_global_jitter_plus_correlated_shear_disturbance";
D.relative_perturbation_norm=norm(difference(:))/max(norm(Uclean(:)),eps);
D.snr_db=20*log10(norm(Uclean(:))/max(norm(difference(:)),eps));
D.source_amplitude_jitter_std=ampStd;
D.source_phase_jitter_cycles_std=phaseStd;
D.propagation_relative_std=base;
D.correlation_m=getf(cfg,"correlation_m",0);
end

function X=correlate(X,spacing,correlation)
% Array order is z-x for 2D, z-y-x for 3D.
for d=1:ndims(X)
    sigma=correlation/spacing(d);
    if sigma<=0,continue,end
    radius=max(1,ceil(3*sigma));
    q=-radius:radius;
    k=exp(-0.5*(q./sigma).^2);
    k=k./sum(k);
    sh=ones(1,ndims(X)); sh(d)=numel(k);
    X=convn(X,reshape(k,sh),"same");
end
end

function v=getf(s,key,default)
if isfield(s,key),v=double(s.(key));else,v=default;end
end
