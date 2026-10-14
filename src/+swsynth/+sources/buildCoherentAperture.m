function aperture = buildCoherentAperture(parentSourceXYZ, apertureConfig)
%BUILDCOHERENTAPERTURE Resolve one coherent point or line source geometry.
%
% The helper is purely geometric: it creates uniformly weighted point-force
% elements centered on the supplied physical parent source. Phase, amplitude,
% force direction, propagation, and spreading remain responsibilities of the
% wavefield synthesizer.

arguments
    parentSourceXYZ (1,3) double {mustBeFinite}
    apertureConfig (1,1) struct
end

required = ["model", "span_m", "axis_xyz", "node_spacing_m"];
for index = 1:numel(required)
    if ~isfield(apertureConfig, required(index))
        error("swsynth:MissingApertureField", ...
            "apertureConfig.%s is required.", required(index));
    end
end

model = string(apertureConfig.model);
axisXYZ = double(apertureConfig.axis_xyz(:).');
spanM = double(apertureConfig.span_m);
spacingM = double(apertureConfig.node_spacing_m);

if numel(axisXYZ) ~= 3 || any(~isfinite(axisXYZ)) || norm(axisXYZ) <= eps
    error("swsynth:InvalidApertureAxis", ...
        "apertureConfig.axis_xyz must be a finite nonzero three-vector.");
end
axisXYZ = axisXYZ / norm(axisXYZ);

switch model
    case "point"
        if ~isfinite(spanM) || spanM ~= 0
            error("swsynth:PointApertureRequiresZeroSpan", ...
                "A point aperture requires span_m = 0.");
        end
        offsetsM = 0;

    case "line_segment"
        if ~isfinite(spanM) || spanM <= 0 || ...
                ~isfinite(spacingM) || spacingM <= 0
            error("swsynth:InvalidLineAperture", ...
                "A line aperture requires positive finite span and spacing.");
        end
        intervalCount = spanM / spacingM;
        roundedIntervalCount = round(intervalCount);
        tolerance = 100 * eps(max(1, abs(intervalCount)));
        if abs(intervalCount - roundedIntervalCount) > tolerance || ...
                mod(roundedIntervalCount, 2) ~= 0
            error("swsynth:UnrepresentableApertureDiscretization", ...
                ["span_m/node_spacing_m must be an even integer so the " + ...
                 "line contains both endpoints and its center element."]);
        end
        offsetsM = ...
            (-roundedIntervalCount/2:roundedIntervalCount/2) * spacingM;

    otherwise
        error("swsynth:InvalidApertureModel", ...
            "Unsupported aperture model: %s", model);
end

nodeXYZ = parentSourceXYZ + offsetsM(:) .* axisXYZ;
weights = ones(1, numel(offsetsM)) / numel(offsetsM);

aperture = struct();
aperture.model = model;
aperture.parent_source_xyz_m = parentSourceXYZ;
aperture.axis_xyz = axisXYZ;
aperture.requested_span_m = spanM;
aperture.realized_span_m = offsetsM(end) - offsetsM(1);
aperture.node_spacing_m = spacingM;
aperture.node_count = numel(offsetsM);
aperture.node_offsets_m = offsetsM;
aperture.node_weights = weights;
aperture.node_xyz_m = nodeXYZ;

end
