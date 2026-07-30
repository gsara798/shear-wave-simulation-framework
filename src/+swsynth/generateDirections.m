function directions = generateDirections(cfg)
%GENERATEDIRECTIONS Generate propagation directions for one configuration.
%
% Usage:
%   cfg = swsynth.defaultConfig();
%   cfg.seed = 10;
%   [cfg, ~] = swsynth.validateConfig(cfg);
%   directions = swsynth.generateDirections(cfg);
%
% Output fields:
%   ux, uy, uz       row vectors in single precision
%   count            number of directions
%   space            two_dimensional or three_dimensional
%   sampling_method  random or fibonacci
%   support_type     configured angular support type

arguments
    cfg (1,1) struct
end

[cfg, ~] = swsynth.validateConfig(cfg);

rng(cfg.seed);

N = cfg.directions.count;
space = cfg.directions.space;
method = cfg.directions.sampling_method;
support = cfg.directions.support;

solidAngleDiagnostics = struct();

if space == "two_dimensional"
    [ux, uy, uz] = generate2D(N, method, support);

elseif support.type == "solid_angle_cap"
    [directionsXYZ, solidAngleDiagnostics] = ...
        swsynth.sampleSolidAngleDirections( ...
            N, ...
            support.solid_angle_sr, ...
            support.axis_xyz, ...
            cfg.directions.in_plane_count);

    ux = directionsXYZ(:, 1).';
    uy = directionsXYZ(:, 2).';
    uz = directionsXYZ(:, 3).';

else
    [ux, uy, uz] = generate3D(N, method, support);

    % Legacy support types retain the former one-direction behavior.
    if cfg.directions.in_plane_count == 1
        [ux, uy, uz] = forceInPlaneDirection(ux, uy, uz, cfg);
    end
end

directions = struct();
directions.ux = single(ux(:).');
directions.uy = single(uy(:).');
directions.uz = single(uz(:).');
directions.count = N;
directions.space = space;
directions.sampling_method = method;
directions.support_type = support.type;
directions.in_plane_count = ...
    nnz(abs(double(directions.uy)) <= 1e-12);
directions.requested_in_plane_count = ...
    cfg.directions.in_plane_count;

if support.type == "solid_angle_cap"
    directions.solid_angle_sr = ...
        support.solid_angle_sr;
    directions.support_axis_xyz = ...
        support.axis_xyz;
    directions.support_half_angle_deg = ...
        solidAngleDiagnostics.half_angle_deg;
else
    directions.solid_angle_sr = NaN;
    directions.support_axis_xyz = ...
        support.axis_xyz;
    directions.support_half_angle_deg = NaN;
end

end

function [ux, uy, uz] = generate2D(N, method, support)

switch support.type
    case "full_circle"
        angleRange = [0, 2*pi];
        alpha = sampleAngles(angleRange, N, method);

    case "angular_ranges"
        alpha = sampleAngles( ...
            support.angle_range_2d_rad, ...
            N, ...
            method);

    case "cone"
        axisXZ = single([support.axis_xyz(1), support.axis_xyz(3)]);
        axisMagnitude = norm(axisXZ);

        if axisMagnitude < 1e-12
            error("swsynth:InvalidConeAxis", ...
                "A 2D cone axis must have a nonzero x-z projection.");
        end

        axisXZ = axisXZ / axisMagnitude;
        center = atan2(axisXZ(2), axisXZ(1));
        halfAngle = deg2rad(single(support.half_angle_deg));

        switch method
            case "random"
                u = rand(1, N, "single");
                alpha = center + (2*u - 1) .* halfAngle;

            case "fibonacci"
                t = single(((0:N-1) + 0.5) / N);
                alpha = center + (-1 + 2*t) .* halfAngle;
        end

    case "band"
        axisXZ = single([support.axis_xyz(1), support.axis_xyz(3)]);
        axisMagnitude = norm(axisXZ);

        if axisMagnitude < 1e-12
            error("swsynth:InvalidBandAxis", ...
                "A 2D band axis must have a nonzero x-z projection.");
        end

        axisXZ = axisXZ / axisMagnitude;
        center = atan2(axisXZ(2), axisXZ(1));
        halfWidth = deg2rad(single(support.band_half_width_deg));
        center1 = center + pi/2;
        center2 = center - pi/2;

        alpha = zeros(1, N, "single");

        switch method
            case "random"
                u = rand(1, N, "single");
                side = rand(1, N, "single") > 0.5;
                alpha(~side) = center1 + ...
                    (-1 + 2*u(~side)) .* halfWidth;
                alpha(side) = center2 + ...
                    (-1 + 2*u(side)) .* halfWidth;

            case "fibonacci"
                t = single(((0:N-1) + 0.5) / N);
                idx1 = 1:2:N;
                idx2 = 2:2:N;
                alpha(idx1) = center1 + ...
                    (-1 + 2*t(idx1)) .* halfWidth;
                alpha(idx2) = center2 + ...
                    (-1 + 2*t(idx2)) .* halfWidth;
        end

    otherwise
        error("swsynth:Invalid2DSupport", ...
            "Support type %s is not valid in two-dimensional direction space.", ...
            support.type);
end

ux = cos(alpha);
uy = zeros(1, N, "single");
uz = sin(alpha);

end

function alpha = sampleAngles(angleRange, N, method)

a0 = single(angleRange(1));
a1 = single(angleRange(2));

switch method
    case "random"
        u = rand(1, N, "single");
        alpha = a0 + u .* (a1 - a0);

    case "fibonacci"
        alpha = linspace(a0, a1, N + 1);
        alpha(end) = [];
        alpha = single(alpha);
end

end

function [ux, uy, uz] = generate3D(N, method, support)

switch support.type
    case "full_sphere"
        if method == "fibonacci"
            [ux, uy, uz] = fibonacciSphere(N);
        else
            u1 = rand(1, N, "single");
            u2 = rand(1, N, "single");
            cosTheta = 1 - 2*u1;
            theta = acos(cosTheta);
            phi = 2*pi*u2;
            ux = sin(theta) .* cos(phi);
            uy = sin(theta) .* sin(phi);
            uz = cos(theta);
        end

    case "angular_ranges"
        thetaRange = support.theta_range_rad;
        phiRange = support.phi_range_rad;

        thetaMin = single(thetaRange(1));
        thetaMax = single(thetaRange(2));
        phiMin = single(phiRange(1));
        phiMax = single(phiRange(2));

        cosThetaMin = cos(thetaMin);
        cosThetaMax = cos(thetaMax);

        switch method
            case "random"
                u1 = rand(1, N, "single");
                u2 = rand(1, N, "single");
                cosTheta = cosThetaMin - ...
                    u1 .* (cosThetaMin - cosThetaMax);
                theta = acos(cosTheta);
                phi = phiMin + u2 .* (phiMax - phiMin);

            case "fibonacci"
                t = single(((0:N-1) + 0.5) / N);
                cosTheta = cosThetaMin - ...
                    t .* (cosThetaMin - cosThetaMax);
                theta = acos(cosTheta);

                goldenRatio = (1 + sqrt(5)) / 2;
                phiSpan = phiMax - phiMin;
                phi = phiMin + mod( ...
                    (0:N-1) * (2*pi / goldenRatio), ...
                    phiSpan);
                phi = single(phi);
        end

        ux = sin(theta) .* cos(phi);
        uy = sin(theta) .* sin(phi);
        uz = cos(theta);

    case "cone"
        axisHat = single(support.axis_xyz(:));
        halfAngle = deg2rad(single(support.half_angle_deg));

        if method == "random"
            [ux, uy, uz] = sampleCone(axisHat, halfAngle, N);
        else
            [ux, uy, uz] = fibonacciCap(axisHat, halfAngle, N);
        end

    case "band"
        axisHat = single(support.axis_xyz(:));
        halfWidth = deg2rad(single(support.band_half_width_deg));

        if method == "random"
            [ux, uy, uz] = sampleBand(axisHat, halfWidth, N);
        else
            [ux, uy, uz] = fibonacciBand(axisHat, halfWidth, N);
        end

    otherwise
        error("swsynth:Invalid3DSupport", ...
            "Support type %s is not valid in three-dimensional direction space.", ...
            support.type);
end

end

function [ux, uy, uz] = sampleCone(axisHat, halfAngle, N)

[e1, e2] = transverseBasis(axisHat);

u = rand(1, N, "single");
cosBeta = 1 - u .* (1 - cos(halfAngle));
sinBeta = sqrt(max(0, 1 - cosBeta.^2));
psi = 2*pi * rand(1, N, "single");

directions = axisHat * cosBeta + ...
    e1 * (sinBeta .* cos(psi)) + ...
    e2 * (sinBeta .* sin(psi));

ux = directions(1,:);
uy = directions(2,:);
uz = directions(3,:);

end

function [ux, uy, uz] = sampleBand(axisHat, halfWidth, N)

[e1, e2] = transverseBasis(axisHat);

u = rand(1, N, "single");
muMax = sin(halfWidth);
mu = -muMax + 2*muMax*u;
sinBeta = sqrt(max(0, 1 - mu.^2));
psi = 2*pi * rand(1, N, "single");

directions = axisHat * mu + ...
    e1 * (sinBeta .* cos(psi)) + ...
    e2 * (sinBeta .* sin(psi));

ux = directions(1,:);
uy = directions(2,:);
uz = directions(3,:);

end

function [ux, uy, uz] = fibonacciSphere(N)

goldenAngle = pi * (3 - sqrt(5));
index = 0:N-1;

z = 1 - 2*(index + 0.5)/N;
radius = sqrt(max(0, 1 - z.^2));
phi = goldenAngle * index;

ux = radius .* cos(phi);
uy = radius .* sin(phi);
uz = z;

end

function [ux, uy, uz] = fibonacciCap(axisHat, halfAngle, N)

[e1, e2] = transverseBasis(axisHat);

goldenAngle = pi * (3 - sqrt(5));
index = 0:N-1;
t = (index + 0.5) / N;

cosBeta = 1 - t .* (1 - cos(halfAngle));
sinBeta = sqrt(max(0, 1 - cosBeta.^2));
psi = goldenAngle * index;

directions = axisHat * cosBeta + ...
    e1 * (sinBeta .* cos(psi)) + ...
    e2 * (sinBeta .* sin(psi));

ux = directions(1,:);
uy = directions(2,:);
uz = directions(3,:);

end

function [ux, uy, uz] = fibonacciBand(axisHat, halfWidth, N)

[e1, e2] = transverseBasis(axisHat);

goldenAngle = pi * (3 - sqrt(5));
index = 0:N-1;
t = (index + 0.5) / N;

muMax = sin(halfWidth);
mu = -muMax + 2*muMax*t;
sinBeta = sqrt(max(0, 1 - mu.^2));
psi = goldenAngle * index;

directions = axisHat * mu + ...
    e1 * (sinBeta .* cos(psi)) + ...
    e2 * (sinBeta .* sin(psi));

ux = directions(1,:);
uy = directions(2,:);
uz = directions(3,:);

end

function [e1, e2] = transverseBasis(axisHat)

axisHat = axisHat(:);
axisHat = axisHat / norm(axisHat);

if abs(dot(axisHat, [0;0;1])) < 0.99
    temporary = [0;0;1];
else
    temporary = [0;1;0];
end

e1 = cross(temporary, axisHat);
e1 = e1 / norm(e1);

e2 = cross(axisHat, e1);
e2 = e2 / norm(e2);

end

function [ux, uy, uz] = forceInPlaneDirection(ux, uy, uz, cfg)

support = cfg.directions.support;

switch support.type
    case "cone"
        axisHat = double(support.axis_xyz(:));
        target = [axisHat(1); 0; axisHat(3)];

        if norm(target) < eps
            return;
        end

        target = target / norm(target);
        separation = acos(max(-1, min(1, dot(axisHat, target))));

        if separation > deg2rad(double(support.half_angle_deg)) + 1e-12
            warning("swsynth:NoPlaneIntersection", ...
                "The cone does not intersect the observation plane.");
            return;
        end

    case {"full_sphere", "angular_ranges"}
        target = [1; 0; 0];

    case "band"
        axisHat = double(support.axis_xyz(:));
        target = cross(axisHat, [0;1;0]);

        if norm(target) < eps
            target = [1;0;0];
        else
            target = target / norm(target);
        end

    otherwise
        return;
end

[~, index] = min(abs(double(uy)));
ux(index) = single(target(1));
uy(index) = single(0);
uz(index) = single(target(3));

end
