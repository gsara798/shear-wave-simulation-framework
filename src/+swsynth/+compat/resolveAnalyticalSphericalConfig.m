function legacy = resolveAnalyticalSphericalConfig(requested)
%RESOLVEANALYTICALSPHERICALCONFIG Adapt high-level spherical config to v1 swsynth.
% This is a strict compatibility adapter: it does not implement new physics.
% Keep swsynth.run, run3D and old configurations unchanged.
arguments
    requested (1,1) struct
end
required=["simulation","propagation","observation","sources"];
for k=required
    if ~isfield(requested,k) || ~isstruct(requested.(k))
        error("swsynth:MissingAnalyticalContract", ...
            "The new analytical contract requires object %s.",k);
    end
end
if ~isfield(requested.simulation,"method") || ...
        lower(string(requested.simulation.method))~="analytical"
    error("swsynth:UnsupportedSimulationMethod", ...
        "This adapter currently supports simulation.method=analytical only.");
end
if ~isfield(requested.propagation,"wave_type") || ...
        lower(string(requested.propagation.wave_type))~="spherical"
    error("swsynth:UnsupportedWaveType", ...
        "This adapter supports propagation.wave_type=spherical only.");
end
if ~isfield(requested.propagation,"model") || ...
        lower(string(requested.propagation.model))~="point_force_shear_far_field"
    error("swsynth:UnsupportedRadiationModel", ...
        "Only point_force_shear_far_field is implemented; Green and Oestreicher are pending.");
end
if ~isfield(requested.observation,"geometry")
    error("swsynth:MissingObservationGeometry","observation.geometry is required.");
end
geometry=lower(string(requested.observation.geometry));
switch geometry
    case "2d"
        error("swsynth:Physical2DNotImplemented", ...
            "Physical 2D requires a distinct 2D Green formulation, not a 3D slice.");
    case "volumetric3d"
        error("swsynth:VolumetricPointForceNotImplemented", ...
            "Volumetric point-force shear evaluation is not implemented yet.");
    case "projected3d"
        % Supported by existing spherical wave synthesis: 3D source and x-z slice.
    otherwise
        error("swsynth:InvalidObservationGeometry", ...
            "Supported geometries: 2d, projected3d, volumetric3d.");
end
if ~isfield(requested.observation,"component") || ...
        lower(string(requested.observation.component))~="z"
    error("swsynth:UnsupportedObservationComponent", ...
        "Only observation.component=z is supported at present.");
end
if ~isfield(requested.sources,"geometry") || ...
        lower(string(requested.sources.geometry))~="point"
    error("swsynth:UnsupportedSourceGeometry", ...
        "This adapter currently supports sources.geometry=point only.");
end
if ~isfield(requested.sources,"force_direction_xyz")
    error("swsynth:MissingForceDirection", ...
        "sources.force_direction_xyz is required.");
end
f=double(requested.sources.force_direction_xyz(:)');
if numel(f)~=3 || any(~isfinite(f)) || norm(f)<=0
    error("swsynth:InvalidForceDirection", ...
        "sources.force_direction_xyz must be a finite nonzero 3-vector.");
end
legacy=requested;
legacy=rmfield(legacy,["simulation","observation"]);
legacy.propagation=rmfield(legacy.propagation,"wave_type");
legacy.propagation.model="spherical_wave";
legacy.sources=rmfield(legacy.sources,["geometry","force_direction_xyz"]);
legacy.sources.radiation=struct( ...
    "model","point_force_shear_far_field", ...
    "force_direction_xyz",f/norm(f));
legacy.sources.aperture=struct("model","point", ...
    "span_m",0,"axis_xyz",[0 0 1],"node_spacing_m",0.0005);
% Preserve provided legacy/default fields and standard result contract.
end
