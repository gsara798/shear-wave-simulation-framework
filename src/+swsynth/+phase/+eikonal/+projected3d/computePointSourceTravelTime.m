function [T,diagnostics]=computePointSourceTravelTime(cs,x,z,source,options)
%COMPUTEPOINTSOURCETRAVELTIME First-arrival 2D Eikonal from internal point.
% Source must lie on the observed x-z plane and inside the simulated FOV.
arguments
    cs (:,:) double
    x (1,:) double
    z (:,1) double
    source (1,3) double
    options (1,1) struct = struct()
end
if ~isequal(size(cs),[numel(z),numel(x)]) || ...
        any(~isfinite(cs(:)) | cs(:)<=0) || ...
        any(diff(x)<=0) || any(diff(z)<=0)
    error("swsynth:InvalidPointSourceEikonal","Invalid phase-speed grid.");
end
if abs(source(2))>1e-12 || source(1)<x(1) || source(1)>x(end) || ...
        source(3)<z(1) || source(3)>z(end)
    error("swsynth:UnsupportedPointSourceEikonal", ...
        "The source must be inside the FOV and on observation plane y=0.");
end
[~,ix]=min(abs(x-source(1)));
[~,iz]=min(abs(z-source(3)));
dx=mean(diff(x));dz=mean(diff(z));
initial=inf(size(cs));
fixed=false(size(cs));
fixed(iz,ix)=true;
initial(iz,ix)=hypot(x(ix)-source(1),z(iz)-source(3))/cs(iz,ix);
[T,diagnostics]=swsynth.numerics.eikonal.solveFastSweeping2D( ...
    1./cs,dx,dz,initial,fixed,options);
if ~diagnostics.converged
    error("swsynth:PointSourceEikonalDidNotConverge", ...
        "Point-source Eikonal solver did not converge.");
end
diagnostics.fixed_mask=fixed;
diagnostics.source_grid_index_zx=[iz ix];
diagnostics.source_position_xyz_m=source;
diagnostics.model="internal_point_source_first_arrival_2d";
end
