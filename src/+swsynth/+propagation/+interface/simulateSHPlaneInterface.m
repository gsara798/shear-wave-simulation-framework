function out=simulateSHPlaneInterface(request)
%SIMULATESHPLANEINTERFACE Controlled scalar SH harmonic interface field.
% Geometry: interface x=interface_x_m, SH displacement is along y.
% Incident complex wave travels toward +x in medium 1; total field is
% incident+reflected for x<interface, transmitted for x>=interface.
% exp(i*(k.r-omega*t)); each component is returned separately.
% Optional source-reference amplitude is set at (reference_x_m,reference_z_m).
arguments
    request (1,1) struct
end
required=["x_m","z_m","interface_x_m","frequency_hz", ...
    "incidence_angle_rad","mu1_pa","eta1_pa_s","rho1_kg_m3", ...
    "mu2_pa","eta2_pa_s","rho2_kg_m3"];
if ~all(isfield(request,cellstr(required)))
    error("swsynth:SHSimulationMissingField","Missing SH interface simulation field.");
end
x=double(request.x_m(:).');z=double(request.z_m(:));
if numel(x)<2 || numel(z)<2 || any(diff(x)<=0) || ...
        any(diff(z)<=0) || any(~isfinite([x(:);z(:)]))
    error("swsynth:SHSimulationInvalidGrid","x_m and z_m must increase and be finite.");
end
xi=double(request.interface_x_m);
if ~isscalar(xi)||~isfinite(xi)||xi<=x(1)||xi>=x(end)
    error("swsynth:SHSimulationInvalidInterface","Interface must lie inside the x axis.");
end
enabled=false;
if isfield(request,"interface_enabled")
    if ~islogical(request.interface_enabled) || ~isscalar(request.interface_enabled)
        error("swsynth:SHSimulationInvalidOption","interface_enabled must be a logical scalar.");
    end
    enabled=request.interface_enabled;
end
% 'off' retains the incident wave throughout as a no-interface reference.
excluded={'x_m','z_m','interface_x_m','interface_enabled', ...
    'reference_x_m','reference_z_m','reference_amplitude'};
p=rmfield(request,intersect(fieldnames(request),excluded));
coeff=swsynth.propagation.interface.shViscoelasticCoefficients(p);
referenceX=xi; referenceZ=0; referenceAmplitude=1;
if isfield(request,"reference_x_m"); referenceX=double(request.reference_x_m);end
if isfield(request,"reference_z_m"); referenceZ=double(request.reference_z_m);end
if isfield(request,"reference_amplitude"); referenceAmplitude=double(request.reference_amplitude);end
if ~isscalar(referenceX)||~isfinite(referenceX)||referenceX>xi || ...
        ~isscalar(referenceZ)||~isfinite(referenceZ)|| ...
        ~isscalar(referenceAmplitude)||~isreal(referenceAmplitude)|| ...
        ~isfinite(referenceAmplitude)||referenceAmplitude<0
    error("swsynth:SHSimulationInvalidReference", ...
        "Reference point must be on the incident side with nonnegative amplitude.");
end
% Fix the launched-wave complex amplitude at the reference point.
launch=referenceAmplitude*exp(-1i*( ...
    coeff.wavenumber_normal_1_rad_m*(referenceX-xi)+ ...
    coeff.wavenumber_tangential_rad_m*referenceZ));
[Z,X]=ndgrid(z,x);
d=X-xi;
incident=launch*exp(1i*(coeff.wavenumber_normal_1_rad_m*d + ...
    coeff.wavenumber_tangential_rad_m*Z));
reflected=complex(zeros(size(incident)));
transmitted=complex(zeros(size(incident)));
if enabled
    left=X<xi;right=~left;
    reflected(left)=launch*coeff.reflection_displacement * ...
        exp(1i*(-coeff.wavenumber_normal_1_rad_m*d(left) + ...
        coeff.wavenumber_tangential_rad_m*Z(left)));
    transmitted(right)=launch*coeff.transmission_displacement * ...
        exp(1i*(coeff.wavenumber_normal_2_rad_m*d(right)+ ...
        coeff.wavenumber_tangential_rad_m*Z(right)));
    incident(right)=0;
    total=incident+reflected+transmitted;
else
    total=incident;
end
out=struct("model","controlled_kelvin_voigt_plane_SH", ...
    "interface_enabled",enabled,"x_m",x,"z_m",z, ...
    "reference_x_m",referenceX,"reference_z_m",referenceZ, ...
    "reference_amplitude",referenceAmplitude, ...
    "interface_x_m",xi,"coefficients",coeff, ...
    "incident_uy_zx",incident,"reflected_uy_zx",reflected, ...
    "transmitted_uy_zx",transmitted,"total_uy_zx",total, ...
    "phase_convention","exp(i*(k.r-omega*t))");
end
