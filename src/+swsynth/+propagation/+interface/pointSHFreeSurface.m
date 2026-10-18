function out=pointSHFreeSurface(request)
%POINTSHFREESURFACE 2D antiplane SH line-source Green function + image.
% x<=interface_x_m is elastic half-space, free traction at x=interface.
% This is a cylindrical 2D SH line source, NOT a 3D spherical point-force
% Green tensor. For a stress-free boundary the image has the same sign.
% Convention exp(-i omega t); outgoing H0^(1)(k*r).
arguments
    request (1,1) struct
end
fields=["x_m","z_m","source_xz_m","interface_x_m", ...
    "frequency_hz","cs_m_s"];
if ~all(isfield(request,cellstr(fields)))
    error("swsynth:SHFreeSurfaceMissingField","Missing free-surface SH parameter.");
end
x=double(request.x_m(:).');z=double(request.z_m(:));
src=double(request.source_xz_m(:).');
xi=double(request.interface_x_m);f=double(request.frequency_hz);
cs=double(request.cs_m_s);
if ~isequal(size(src),[1 2]) || any(~isfinite(src)) || ...
        ~isscalar(xi)||~isfinite(xi)||src(1)>=xi || ...
        any(x>xi) || numel(x)<2 || numel(z)<2 || ...
        any(diff(x)<=0)||any(diff(z)<=0)|| ...
        any(~isfinite([x(:);z(:)])) || ...
        ~isscalar(f)||~isfinite(f)||f<=0 || ...
        ~isscalar(cs)||~isfinite(cs)||cs<=0
    error("swsynth:SHFreeSurfaceInvalidParameter", ...
        "Require finite left-half-space grid and valid source, frequency, speed.");
end
on=true;
if isfield(request,"reflection_enabled")
    if ~islogical(request.reflection_enabled)||~isscalar(request.reflection_enabled)
        error("swsynth:SHFreeSurfaceInvalidSwitch","reflection_enabled must be logical.");
    end
    on=request.reflection_enabled;
end
amplitude=1;
if isfield(request,"amplitude")
    amplitude=double(request.amplitude);
end
if ~isscalar(amplitude)||~isfinite(amplitude)||~isreal(amplitude)
    error("swsynth:SHFreeSurfaceInvalidAmplitude","Amplitude must be finite real scalar.");
end
[Z,X]=ndgrid(z,x);
r=hypot(X-src(1),Z-src(2));
mirror=[2*xi-src(1),src(2)];
ri=hypot(X-mirror(1),Z-mirror(2));
if any(r(:)<1e-12)
    error("swsynth:SHFreeSurfaceSingularSource", ...
        "Exclude the line-source singularity from sampled points.");
end
k=2*pi*f/cs;
scale=1i/4;
incident=amplitude*scale*besselh(0,1,k*r);
reflected=complex(zeros(size(incident)));
if on
    reflected=amplitude*scale*besselh(0,1,k*ri);
end
out=struct("model","elastic_antiplane_SH_line_source_free_surface", ...
    "reflection_enabled",on,"x_m",x,"z_m",z, ...
    "source_xz_m",src,"image_source_xz_m",mirror, ...
    "incident_uy_zx",incident,"reflected_uy_zx",reflected, ...
    "total_uy_zx",incident+reflected, ...
    "wavenumber_rad_m",k,"phase_convention","exp(-i*omega*t)");
end
