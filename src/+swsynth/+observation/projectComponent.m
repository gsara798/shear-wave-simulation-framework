function observed = projectComponent(vectorXYZ, axisXYZ)
%PROJECTCOMPONENT Signed projection of true vector motion on a sensor axis.
% Works for N-by-3 or spatial arrays whose LAST dimension is xyz=3,
% e.g. Nz-by-Nx-by-3 or Nz-by-Ny-by-Nx-by-3 complex phasors.
% No ultrasound attenuation, speckle, noise, filtering or motion tracking.
arguments
    vectorXYZ {mustBeNumeric}
    axisXYZ (1,3) double {mustBeFinite}
end
if isempty(vectorXYZ) || ndims(vectorXYZ)<2 || ...
        size(vectorXYZ,ndims(vectorXYZ))~=3 || ...
        any(~isfinite(vectorXYZ(:)))
    error("swsynth:InvalidObservationVectors", ...
        "Vector field must be finite and have xyz in the last dimension (size 3).");
end
axisNorm=norm(axisXYZ);
if axisNorm<=eps
    error("swsynth:InvalidObservationAxis", ...
        "Observation axis must be a nonzero 3-vector.");
end
axisHat=axisXYZ/axisNorm;
shape=ones(1,ndims(vectorXYZ));
shape(end)=3;
observed=sum(vectorXYZ.*reshape(axisHat,shape),ndims(vectorXYZ));
end
