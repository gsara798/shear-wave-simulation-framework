function out = validate(request)
%VALIDATE Source-level excitation: force orientation, amplitude and phase.
% Amplitude is nonnegative; force_direction_xyz is normalized separately.
arguments
    request (1,1) struct
end
required=["count","force_direction_xyz","relative_amplitude","phase_rad"];
for name=required
    if ~isfield(request,name)
        error("swsynth:ExcitationMissingField","Missing excitation field %s.",name);
    end
end
n=double(request.count);
if ~isscalar(n)||~isfinite(n)||n<1||n~=floor(n)
    error("swsynth:InvalidExcitationCount","count must be a positive integer.");
end
f=double(request.force_direction_xyz);
if ~isequal(size(f),[n 3]) || any(~isfinite(f(:))) || ...
        any(vecnorm(f,2,2)<=0)
    error("swsynth:InvalidExcitationDirections", ...
        "force_direction_xyz must be N-by-3 finite nonzero vectors.");
end
a=double(request.relative_amplitude(:));
p=double(request.phase_rad(:));
if numel(a)~=n || any(~isfinite(a)) || any(a<0)
    error("swsynth:InvalidExcitationAmplitude", ...
        "relative_amplitude must be N nonnegative finite values.");
end
if numel(p)~=n || any(~isfinite(p))
    error("swsynth:InvalidExcitationPhase", ...
        "phase_rad must contain N finite values.");
end
out=struct("count",n,"force_direction_xyz",f./vecnorm(f,2,2), ...
    "relative_amplitude",a,"phase_rad",p);
end
