function excitation = generate(request)
%GENERATE Independently prepare forces, amplitudes and source phases.
% Request: count, optional force_direction_xyz, relative_amplitude,
% phase_rad; optional amplitude_policy (fixed/random_normal),
% phase_policy (fixed/random_uniform), force_policy (fixed/random_sphere).
% Optional stream is a RandStream; no global reseeding occurs.
arguments
    request (1,1) struct
end
if ~isfield(request,"count")
    error("swsynth:ExcitationMissingField","Missing count.");
end
n=double(request.count);
if ~isscalar(n)||~isfinite(n)||n<1||n~=floor(n)
    error("swsynth:InvalidExcitationCount","count must be positive integer.");
end
stream=[];
if isfield(request,"stream")
    stream=request.stream;
end
forcePolicy="fixed";
if isfield(request,"force_policy");forcePolicy=string(request.force_policy);end
amplitudePolicy="fixed";
if isfield(request,"amplitude_policy");amplitudePolicy=string(request.amplitude_policy);end
phasePolicy="fixed";
if isfield(request,"phase_policy");phasePolicy=string(request.phase_policy);end
switch forcePolicy
    case "fixed"
        if ~isfield(request,"force_direction_xyz")
            error("swsynth:ExcitationMissingField","Missing force_direction_xyz.");
        end
        f=double(request.force_direction_xyz);
        if isvector(f) && numel(f)==3
            f=repmat(reshape(f,1,3),n,1);
        end
    case "random_sphere"
        z=2*draw(stream,n,1)-1;
        phi=2*pi*draw(stream,n,1);
        xy=sqrt(max(0,1-z.^2));
        f=[xy.*cos(phi),xy.*sin(phi),z];
    otherwise
        error("swsynth:InvalidForcePolicy","Unsupported force_policy %s.",forcePolicy);
end
switch amplitudePolicy
    case "fixed"
        a=ones(n,1);
        if isfield(request,"relative_amplitude")
            a=double(request.relative_amplitude(:));
        end
    case "random_normal"
        jitter=0.1;
        if isfield(request,"amplitude_jitter_fraction")
            jitter=double(request.amplitude_jitter_fraction);
        end
        if ~isscalar(jitter)||~isfinite(jitter)||jitter<0
            error("swsynth:InvalidExcitationAmplitude","Invalid amplitude jitter.");
        end
        % Truncated at zero to preserve a nonnegative magnitude contract.
        a=max(0,1+jitter*drawn(stream,n,1));
    otherwise
        error("swsynth:InvalidAmplitudePolicy","Unsupported amplitude_policy %s.",amplitudePolicy);
end
switch phasePolicy
    case "fixed"
        p=zeros(n,1);
        if isfield(request,"phase_rad")
            p=double(request.phase_rad(:));
        end
    case "random_uniform"
        p=2*pi*draw(stream,n,1);
    otherwise
        error("swsynth:InvalidExcitationPhasePolicy","Unsupported phase_policy %s.",phasePolicy);
end
excitation=swsynth.sources.excitation.validate( ...
    struct("count",n,"force_direction_xyz",f, ...
    "relative_amplitude",a,"phase_rad",p));
end

function u=draw(stream,varargin)
if isempty(stream);u=rand(varargin{:});else;u=rand(stream,varargin{:});end
end

function u=drawn(stream,varargin)
if isempty(stream);u=randn(varargin{:});else;u=randn(stream,varargin{:});end
end
