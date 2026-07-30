function excitation = generateDirectionalExcitation( ...
        cfg, directionsXYZ)
%GENERATEDIRECTIONALEXCITATION Reproducible directional source weights.
%
% Canonical output shapes:
%
%   phase_rad          N-by-1
%   amplitude          N-by-1
%   polarization_xyz   N-by-3
%   polarization_z     N-by-1
%   weights            N-by-1

arguments
    cfg (1,1) struct
    directionsXYZ (:,3) double
end

[cfg, ~] = swsynth.validateConfig(cfg);

directionsXYZ = double(directionsXYZ);

directionNorms = vecnorm(directionsXYZ, 2, 2);

if any(directionNorms <= eps)
    error( ...
        "swsynth:InvalidDirection", ...
        "Every direction must have nonzero magnitude.");
end

directionsXYZ = directionsXYZ ./ directionNorms;
directionCount = size(directionsXYZ,1);

rng(double(cfg.seed), "twister");

% Preserve one deterministic RNG contract for every propagation backend.
polarizationXYZ = generatePolarization( ...
    directionsXYZ, ...
    cfg.polarization.model);

amplitudeJitter = ...
    double(cfg.sources.amplitude_jitter_fraction);

amplitude = ...
    1 + amplitudeJitter .* randn(directionCount,1);

phaseRad = ...
    2*pi .* rand(directionCount,1);

polarizationZ = polarizationXYZ(:,3);

weights = ...
    amplitude .* ...
    polarizationZ .* ...
    exp(1i .* phaseRad) ./ ...
    sqrt(directionCount);

excitation = struct();
excitation.phase_rad = phaseRad;
excitation.amplitude = amplitude;
excitation.polarization_xyz = polarizationXYZ;
excitation.polarization_z = polarizationZ;
excitation.weights = weights;

end

function polarizationXYZ = generatePolarization( ...
        directionsXYZ, model)

directionCount = size(directionsXYZ,1);

switch model
    case "transverse_random"
        polarizationXYZ = ...
            swsynth.propagation.projected3d. ...
                sampleTransversePolarization( ...
                    directionsXYZ);

    case "in_plane_sv"
        polarizationXYZ = zeros(directionCount,3);

        polarizationXYZ(:,1) = ...
            directionsXYZ(:,3);

        polarizationXYZ(:,3) = ...
            -directionsXYZ(:,1);

        polarizationNorm = ...
            vecnorm(polarizationXYZ,2,2);

        degenerateMask = polarizationNorm <= eps;

        polarizationXYZ(~degenerateMask,:) = ...
            polarizationXYZ(~degenerateMask,:) ./ ...
            polarizationNorm(~degenerateMask);

        polarizationXYZ(degenerateMask,1) = 1;

    otherwise
        error( ...
            "swsynth:UnsupportedPolarizationModel", ...
            "Unsupported polarization model: %s", ...
            model);
end

end
