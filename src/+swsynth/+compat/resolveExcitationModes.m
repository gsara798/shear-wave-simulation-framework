function e = resolveExcitationModes(spec,n,seed)
%RESOLVEEXCITATIONMODES Materialize per-source force/amplitude/phase modes.
% All random draws use a private seeded stream and do not alter global RNG.
arguments
    spec (1,1) struct
    n (1,1) double {mustBeInteger,mustBePositive}
    seed (1,1) double {mustBeFinite}
end
if ~isfield(spec,"force") || ~isstruct(spec.force)
    error("swsynth:MissingForceMode","excitation.force.mode is required.");
end
state=rng;
cleanup=onCleanup(@()rng(state));
rng(mod(double(seed)+9973,2^32-1),"twister");
f=spec.force;
switch choice(f,["fixed","explicit","random_isotropic"],"force")
    case "fixed"
        dirs=repmat(vector3(f,"direction_xyz"),n,1);
    case "explicit"
        dirs=double(require(f,"directions_xyz"));
    case "random_isotropic"
        dirs=randn(n,3);
end
if isvector(dirs) && n==1 && numel(dirs)==3,dirs=reshape(dirs,1,3);end
if ~isequal(size(dirs),[n 3]) || any(~isfinite(dirs),"all") || any(vecnorm(dirs,2,2)==0)
    error("swsynth:InvalidExcitationDirections","Force vectors must be finite, nonzero N-by-3.");
end
e.force_direction_xyz=dirs./vecnorm(dirs,2,2);
if ~isfield(spec,"amplitude")
    spec.amplitude=struct("mode","fixed","value",1);
end
a=spec.amplitude;
switch choice(a,["fixed","explicit","random_uniform"],"amplitude")
    case "fixed"
        values=repmat(double(require(a,"value")),n,1);
    case "explicit"
        values=double(require(a,"values"));
        values=values(:);
    case "random_uniform"
        bounds=double(require(a,"range"));
        if numel(bounds)~=2 || any(~isfinite(bounds)) || bounds(1)<0 || bounds(2)<bounds(1)
            error("swsynth:InvalidExcitationAmplitude","amplitude.range must be increasing nonnegative [min,max].");
        end
        values=bounds(1)+(bounds(2)-bounds(1))*rand(n,1);
end
if numel(values)~=n || any(~isfinite(values)) || any(values<0)
    error("swsynth:InvalidExcitationAmplitude","Amplitude must be N finite nonnegative values.");
end
e.relative_amplitude=values(:);
if ~isfield(spec,"phase")
    spec.phase=struct("mode","random_uniform");
end
p=spec.phase;
switch choice(p,["in_phase","alternating","fixed","explicit","random_uniform"],"phase")
    case "in_phase"
        phases=zeros(n,1);
    case "alternating"
        phases=pi*mod((0:n-1)',2);
    case "fixed"
        phases=repmat(double(require(p,"value_rad")),n,1);
    case "explicit"
        phases=double(require(p,"values_rad"));
        phases=phases(:);
    case "random_uniform"
        phases=2*pi*rand(n,1);
end
if numel(phases)~=n || any(~isfinite(phases))
    error("swsynth:InvalidExcitationPhase","Phase must be N finite radians.");
end
e.phase_rad=phases(:);
end
function mode=choice(s,allowed,label)
if ~isfield(s,"mode")
    error("swsynth:MissingExcitationMode","excitation.%s.mode is required.",label);
end
mode=lower(string(s.mode));
if ~isscalar(mode) || ~ismember(mode,allowed)
    error("swsynth:InvalidExcitationMode","Unsupported %s mode.",label);
end
end
function v=require(s,name)
if ~isfield(s,name)
    error("swsynth:MissingExcitationParameter","Missing excitation parameter %s.",name);
end
v=s.(name);
end
function v=vector3(s,name)
v=double(require(s,name));
if ~isvector(v) || numel(v)~=3
    error("swsynth:InvalidExcitationDirections","Force direction must be a 3-vector.");
end
v=reshape(v,1,3);
end
