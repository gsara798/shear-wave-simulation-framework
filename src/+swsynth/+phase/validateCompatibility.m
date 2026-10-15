function solver = validateCompatibility(model, phaseModel, geometry, hasHeterogeneity)
%VALIDATECOMPATIBILITY Validate requested phase solver without changing physics.
% Supported automatic routing is currently limited to plane waves.
% Legacy spherical and legacy projected3d_eikonal paths keep their
% established validators until their dedicated migration.
arguments
    model (1,1) string
    phaseModel (1,1) string
    geometry (1,1) string
    hasHeterogeneity (1,1) logical
end
solver = swsynth.phase.resolveSolver(model,phaseModel,geometry);
if hasHeterogeneity && startsWith(solver,"homogeneous_")
    if geometry == "volumetric3d"
        error("swsynth:HomogeneousAnalytic3DRequiresUniformMedium", ...
            "Analytical phase requires a homogeneous volumetric medium.");
    else
        error("swsynth:PlaneWaveRequiresHomogeneousMedium", ...
            "Analytical plane-wave phase requires a homogeneous medium.");
    end
end
end
