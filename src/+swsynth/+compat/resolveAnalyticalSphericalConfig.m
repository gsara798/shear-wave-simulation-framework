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
if isfield(requested.sources,"force_direction_xyz")
    f=double(requested.sources.force_direction_xyz(:)');
elseif isfield(requested.sources,"excitation") && ...
        isfield(requested.sources.excitation,"force_direction_xyz")
    forceRows=double(requested.sources.excitation.force_direction_xyz);
    if size(forceRows,2)~=3 || isempty(forceRows)
        error("swsynth:InvalidForceDirection", ...
            "excitation.force_direction_xyz must contain 3-vector rows.");
    end
    f=forceRows(1,:);
elseif isfield(requested.sources,"excitation") && ...
        isfield(requested.sources.excitation,"force")
    f=[0 0 1]; % Placeholder; resolved force overrides it below.
else
    error("swsynth:MissingForceDirection", ...
        "Provide shared force_direction_xyz or excitation.force_direction_xyz.");
end
if numel(f)~=3 || any(~isfinite(f)) || norm(f)<=0
    error("swsynth:InvalidForceDirection", ...
        "Force direction must be a finite nonzero 3-vector.");
end
if isfield(requested.sources,"position_xyz_m") && ...
        ~isempty(requested.sources.position_xyz_m)
    pos=double(requested.sources.position_xyz_m);
    if isvector(pos) && numel(pos)==3
        pos=reshape(pos,1,3);
    end
    if ~ismatrix(pos) || size(pos,2)~=3 || ...
            any(~isfinite(pos),"all")
        error("swsynth:InvalidSourcePosition", ...
            "sources.position_xyz_m must be a finite N-by-3 matrix in metres.");
    end
else
    pos=[];
end
% New mutually exclusive source-placement interface (legacy path still supported).
if isfield(requested.sources,"placement")
    placement=requested.sources.placement;
    if ~isstruct(placement) || ~isfield(placement,"method")
        error("swsynth:InvalidSourcePlacement", ...
            "sources.placement.method is required.");
    end
    method=lower(string(placement.method));
    if isfield(requested.sources,"position_xyz_m") && ...
            ~isempty(requested.sources.position_xyz_m)
        error("swsynth:ConflictingSourcePlacement", ...
            "Use placement.position_xyz_m, not both placement and top-level positions.");
    end
    if ~isfield(requested.sources,"count") || ...
            ~isscalar(requested.sources.count) || ...
            requested.sources.count < 1 || ...
            requested.sources.count ~= floor(requested.sources.count)
        error("swsynth:InvalidSourceCount", ...
            "sources.count must be a positive integer with sources.placement.");
    end
    count=double(requested.sources.count);
    if isfield(requested,"directions") && ...
            isfield(requested.directions,"count") && ...
            requested.directions.count ~= count
        error("swsynth:ConflictingDirectionCount", ...
            "sources.count and directions.count must agree.");
    end
    if method=="explicit"
        if ~isfield(placement,"position_xyz_m")
            error("swsynth:MissingSourcePositions", ...
                "Explicit placement requires position_xyz_m.");
        end
        positions=double(placement.position_xyz_m);
        if isvector(positions) && numel(positions)==3
            positions=reshape(positions,1,3);
        end
        if ~ismatrix(positions) || size(positions,1)~=count || ...
                size(positions,2)~=3 || any(~isfinite(positions),"all")
            error("swsynth:InvalidSourcePosition", ...
                "Explicit placement requires finite N-by-3 coordinates.");
        end
        if isfield(placement,"radius_m") || isfield(placement,"support")
            error("swsynth:ConflictingSourcePlacement", ...
                "Explicit placement cannot also set radius or angular support.");
        end
    elseif method=="random" || method=="fibonacci"
        if isfield(placement,"position_xyz_m")
            error("swsynth:ConflictingSourcePlacement", ...
                "Radial placement must not specify explicit XYZ positions.");
        end
        if ~isfield(placement,"radius_m")
            error("swsynth:MissingSourceRadius", ...
                "Radial placement requires radius_m.");
        end
        radius=double(placement.radius_m);
        if ~isscalar(radius) || ~isfinite(radius) || radius<=0
            error("swsynth:InvalidSourceRadius", ...
                "placement.radius_m must be positive and finite.");
        end
        if isfield(placement,"center_xyz_m")
            center=double(placement.center_xyz_m);
            if ~isvector(center) || numel(center)~=3 || ...
                    any(~isfinite(center))
                error("swsynth:InvalidSourceCenter", ...
                    "center_xyz_m must be a finite 3-vector.");
            end
            % Non-default centers need a separate source-position builder.
            error("swsynth:CustomPlacementCenterNotImplemented", ...
                "Custom placement.center_xyz_m is not implemented yet.");
        end
    else
        error("swsynth:InvalidSourcePlacement", ...
            "placement.method must be explicit, random or fibonacci.");
    end
end
legacy=requested;
legacy=rmfield(legacy,["simulation","observation"]);
legacy.propagation=rmfield(legacy.propagation,"wave_type");
legacy.propagation.model="spherical_wave";
legacy.sources=rmfield(legacy.sources,"geometry");
if isfield(legacy.sources,"force_direction_xyz")
    legacy.sources=rmfield(legacy.sources,"force_direction_xyz");
end
if isfield(requested.sources,"placement")
    placement=requested.sources.placement;
    method=lower(string(placement.method));
    legacy.sources=rmfield(legacy.sources,["placement","count"]);
    legacy.directions.count=count;
    legacy.directions.space="three_dimensional";
    if method=="explicit"
        legacy.sources.position_xyz_m=positions;
        % Explicit placement does not require any angular sampling.
        % Existing generator is retained temporarily for RNG compatibility.
        legacy.directions.sampling_method="fibonacci";
        legacy.directions.support=struct("type","full_sphere");
        legacy.directions.explicit_xyz=zeros(0,3);
    else
        legacy.sources.position_xyz_m=[];
        legacy.sources.radius_range_m=[radius radius];
        legacy.directions.sampling_method=method;
        legacy.directions.explicit_xyz=zeros(0,3);
        if isfield(placement,"support")
            legacy.directions.support=placement.support;
        else
            legacy.directions.support=struct("type","full_sphere");
        end
    end
end
if ~isempty(pos)
    legacy.sources.position_xyz_m=pos;
end
legacy.sources.radiation=struct( ...
    "model","point_force_shear_far_field", ...
    "force_direction_xyz",f/norm(f));
if isfield(requested.sources,"excitation") && ...
        isfield(requested.sources.excitation,"force")
    if isfield(requested.sources.excitation,"force_direction_xyz") || ...
            isfield(requested.sources.excitation,"relative_amplitude") || ...
            isfield(requested.sources.excitation,"phase_rad")
        error("swsynth:MixedExcitationSchemas", ...
            "Do not mix excitation modes with legacy excitation arrays.");
    end
    legacy.sources.excitation=swsynth.compat.resolveExcitationModes( ...
        requested.sources.excitation,legacy.directions.count,requested.seed);
    legacy.sources.radiation.force_direction_xyz= ...
        legacy.sources.excitation.force_direction_xyz(1,:);
end
legacy.sources.aperture=struct("model","point", ...
    "span_m",0,"axis_xyz",[0 0 1],"node_spacing_m",0.0005);
% Preserve provided legacy/default fields and standard result contract.
end
