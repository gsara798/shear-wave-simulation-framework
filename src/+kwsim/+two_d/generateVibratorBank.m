function bank = generateVibratorBank(cfg)
%GENERATEVIBRATORBANK Resolve reproducible external vibrator definitions.
%
% bank = kwsim.two_d.generateVibratorBank(cfg)
%
% Physical vibrators are placed near the domain perimeter. A point vibrator
% owns one solver channel; a finite segment owns several non-adjacent solver
% channels with a common phase and polarization but spatially tapered peak
% velocities. Separating physical-vibrator IDs from solver labels permits a
% smooth finite contact without pretending that every active node is a
% separate experimental actuator.
%
% Public geometry and vectors use [x,z]. The normalized prescribed drive is
%
%   sum_j sum_n (A_j*w_jn)^2/2  [m^2/s^2],
%
% where A_j is the center peak velocity and w_jn is the spatial weight at
% contact node n. This is an imposed RMS-squared velocity proxy, not power in
% watts, because the corresponding contact stress is not prescribed.

arguments
    cfg struct
end

regime = lower(string(cfg.source.regime));
valid_regimes = ["directional", "partially_diffuse", "diffuse"];
if ~any(regime == valid_regimes)
    error('kwsim:InvalidSourceRegime', ...
        'A vibrator bank requires directional, partially_diffuse, or diffuse.');
end

count = cfg.source.vibrator_count;
if count < 1 || count ~= round(count)
    error('kwsim:InvalidVibratorCount', ...
        'source.vibrator_count must be a positive integer.');
end

radius_x = max(1, round(cfg.source.contact_radius_m / cfg.grid.dx_m));
radius_z = max(1, round(cfg.source.contact_radius_m / cfg.grid.dz_m));
inset_x = radius_x + 2;
inset_z = radius_z + 2;
margin_x = max(radius_x + 2, round(cfg.source.perimeter_margin_m / cfg.grid.dx_m));
margin_z = max(radius_z + 2, round(cfg.source.perimeter_margin_m / cfg.grid.dz_m));

candidates = makeCandidates(cfg, inset_x, inset_z, margin_x, margin_z, ...
    radius_x, radius_z);
if numel(candidates) < count
    error('kwsim:InsufficientPerimeterSpace', ...
        'Only %d non-overlapping perimeter contacts fit; %d were requested.', ...
        numel(candidates), count);
end

target_angle_rad = deg2rad(cfg.source.target_angle_deg);
target_direction = [cos(target_angle_rad), sin(target_angle_rad)];
coherent_side = directionToSourceSide(target_direction);

switch regime
    case "directional"
        coherent_count = count;
    case "partially_diffuse"
        coherent_count = max(1, round(count/2));
    otherwise
        coherent_count = 0;
end
diffuse_count = count - coherent_count;

selected = repmat(emptyCandidate(), 0, 1);
if coherent_count > 0
    side_candidates = candidates([candidates.side] == coherent_side);
    if numel(side_candidates) < coherent_count
        error('kwsim:InsufficientDirectionalAperture', ...
            'The selected perimeter side cannot hold %d coherent contacts.', ...
            coherent_count);
    end
    indices = round(linspace(1, numel(side_candidates), coherent_count));
    selected = side_candidates(indices);
end

stream = RandStream('mt19937ar', 'Seed', cfg.seed);
if diffuse_count > 0
    available = removeOverlappingCandidates(candidates, selected);
    if numel(available) < diffuse_count
        error('kwsim:InsufficientDiffusePerimeter', ...
            'Only %d contacts remain after placing the coherent aperture.', ...
            numel(available));
    end
    order = randperm(stream, numel(available));
    selected = [selected; available(order(1:diffuse_count))];
end

physical_id_mask = zeros(cfg.grid.Nx, cfg.grid.Nz, 'uint16');
solver_label_mask = zeros(cfg.grid.Nx, cfg.grid.Nz, 'uint16');
vibrators = repmat(emptyVibrator(), count, 1);
channels = repmat(emptyChannel(), 0, 1);
wave_number_rad_m = 2*pi*cfg.source.f0_hz / cfg.medium.cs_m_s;
random_phases = 2*pi*rand(stream, diffuse_count, 1);
power_weights = allocatePowerWeights(cfg, regime, coherent_count, diffuse_count);

domain_center_m = [0.5*(cfg.grid.Nx - 1)*cfg.grid.dx_m, ...
    0.5*(cfg.grid.Nz - 1)*cfg.grid.dz_m];
for index = 1:count
    candidate = selected(index);
    node_indices = candidate.contact_node_indices;
    node_weights = candidate.contact_node_weights;
    if any(physical_id_mask(node_indices) ~= 0)
        error('kwsim:OverlappingVibrators', ...
            'Vibrator contacts overlap after candidate selection.');
    end
    physical_id_mask(node_indices) = uint16(index);

    position_m = [(candidate.center_index_xz(1) - 1)*cfg.grid.dx_m, ...
        (candidate.center_index_xz(2) - 1)*cfg.grid.dz_m];
    if index <= coherent_count
        propagation = target_direction;
        phase_rad = -wave_number_rad_m * dot(target_direction, position_m);
        group = "coherent";
    else
        propagation = domain_center_m - position_m;
        propagation = propagation / norm(propagation);
        phase_rad = random_phases(index - coherent_count);
        group = "diffuse";
    end
    polarization = [-propagation(2), propagation(1)];
    weight_square_sum = sum(node_weights.^2);
    center_amplitude = sqrt(2*cfg.source.total_drive_rms_squared_m2_s2 * ...
        power_weights(index) / weight_square_sum);

    channel_labels = zeros(numel(node_indices), 1, 'uint16');
    for node_index = 1:numel(node_indices)
        label = numel(channels) + 1;
        if label > intmax('uint16')
            error('kwsim:TooManySourceChannels', ...
                'The source bank exceeds the uint16 labelled-mask capacity.');
        end
        solver_label_mask(node_indices(node_index)) = uint16(label);
        channel_labels(node_index) = uint16(label);
        channel = emptyChannel();
        channel.label = label;
        channel.vibrator_id = index;
        channel.node_linear_index = node_indices(node_index);
        [node_x, node_z] = ind2sub( ...
            [cfg.grid.Nx, cfg.grid.Nz], node_indices(node_index));
        channel.node_index_xz = [node_x, node_z];
        channel.spatial_weight = node_weights(node_index);
        channel.peak_velocity_m_s = center_amplitude*node_weights(node_index);
        channels(end + 1, 1) = channel; %#ok<AGROW>
    end

    vibrator = emptyVibrator();
    vibrator.id = index;
    vibrator.group = group;
    vibrator.side = candidate.side;
    vibrator.center_index_xz = candidate.center_index_xz;
    vibrator.center_m_xz = position_m;
    vibrator.contact_tangent_xz = candidate.tangent_xz;
    vibrator.contact_node_indices = node_indices;
    vibrator.contact_node_weights = node_weights;
    vibrator.contact_node_count = numel(node_indices);
    vibrator.effective_contact_node_count = weight_square_sum;
    vibrator.solver_channel_labels = channel_labels;
    vibrator.realized_contact_span_m = candidate.realized_span_points * ...
        min(cfg.grid.dx_m, cfg.grid.dz_m);
    vibrator.propagation_xz = propagation;
    vibrator.polarization_xz = polarization;
    vibrator.phase_rad = wrapToPiLocal(phase_rad);
    vibrator.peak_velocity_m_s = center_amplitude;
    vibrator.contact_node_peak_velocities_m_s = center_amplitude*node_weights;
    vibrator.drive_power_weight = power_weights(index);
    vibrator.prescribed_drive_rms_squared_m2_s2 = ...
        center_amplitude^2*weight_square_sum/2;
    vibrators(index) = vibrator;
end

bank = struct();
bank.regime = regime;
bank.contact_model = lower(string(cfg.source.contact_model));
bank.contact_profile = lower(string(cfg.source.contact_profile));
bank.vibrators = vibrators;
bank.solver_channels = channels;
bank.solver_channel_count = numel(channels);
bank.vibrator_id_mask_xz = physical_id_mask;
bank.vibrator_id_mask_zx = physical_id_mask.';
bank.solver_label_mask_xz = solver_label_mask;
bank.solver_label_mask_zx = solver_label_mask.';
% Retain the established name as a solver-facing compatibility alias.
bank.label_mask_xz = solver_label_mask;
bank.label_mask_zx = solver_label_mask.';
bank.vibrator_count = count;
bank.coherent_count = coherent_count;
bank.diffuse_count = diffuse_count;
bank.target_angle_deg = cfg.source.target_angle_deg;
bank.target_direction_xz = target_direction;
bank.total_drive_rms_squared_m2_s2 = sum( ...
    [vibrators.prescribed_drive_rms_squared_m2_s2]);
bank.requested_drive_rms_squared_m2_s2 = ...
    cfg.source.total_drive_rms_squared_m2_s2;
bank.drive_power_relative_error = abs( ...
    bank.total_drive_rms_squared_m2_s2 - ...
    bank.requested_drive_rms_squared_m2_s2) / ...
    bank.requested_drive_rms_squared_m2_s2;
bank.ordering = "Physical vibrators: coherent first, seeded diffuse second. " + ...
    "Solver labels: vibrator order, then tangential contact-node order.";

end

function power_weights = allocatePowerWeights(cfg, regime, coherent_count, diffuse_count)
if coherent_count > 0
    coherent_weights = repmat( ...
        cfg.source.coherent_power_fraction/coherent_count, coherent_count, 1);
else
    coherent_weights = zeros(0, 1);
end
if diffuse_count > 0
    diffuse_weights = repmat( ...
        (1-cfg.source.coherent_power_fraction)/diffuse_count, diffuse_count, 1);
else
    diffuse_weights = zeros(0, 1);
end
power_weights = [coherent_weights; diffuse_weights];
if regime == "directional" || regime == "diffuse"
    power_weights(:) = 1/(coherent_count + diffuse_count);
end
end

function candidates = makeCandidates(cfg, inset_x, inset_z, margin_x, margin_z, radius_x, radius_z)
spacing_x = 2*radius_x + 3;
spacing_z = 2*radius_z + 3;
x_centres = (1 + margin_x):spacing_x:(cfg.grid.Nx - margin_x);
z_centres = (1 + margin_z):spacing_z:(cfg.grid.Nz - margin_z);
candidates = repmat(emptyCandidate(), 0, 1);

for side = ["left", "right"]
    for z_index = z_centres
        if side == "left"
            x_index = inset_x;
        else
            x_index = cfg.grid.Nx - inset_x + 1;
        end
        [offsets, weights] = contactProfile(cfg, radius_z);
        z_nodes = z_index + offsets;
        node_indices = sub2ind([cfg.grid.Nx, cfg.grid.Nz], ...
            repmat(x_index, size(z_nodes)), z_nodes);
        candidates(end + 1, 1) = makeCandidate(side, ...
            [x_index, z_index], node_indices, weights, [0, 1], cfg); %#ok<AGROW>
    end
end
for side = ["top", "bottom"]
    for x_index = x_centres
        if side == "top"
            z_index = inset_z;
        else
            z_index = cfg.grid.Nz - inset_z + 1;
        end
        [offsets, weights] = contactProfile(cfg, radius_x);
        x_nodes = x_index + offsets;
        node_indices = sub2ind([cfg.grid.Nx, cfg.grid.Nz], ...
            x_nodes, repmat(z_index, size(x_nodes)));
        candidates(end + 1, 1) = makeCandidate(side, ...
            [x_index, z_index], node_indices, weights, [1, 0], cfg); %#ok<AGROW>
    end
end
end

function [offsets, weights] = contactProfile(cfg, radius_points)
model = lower(string(cfg.source.contact_model));
if model == "point"
    offsets = 0;
    weights = 1;
    return;
end

spacing = round(cfg.source.contact_node_spacing_points);
offsets = unique([-radius_points:spacing:radius_points, 0]);
switch lower(string(cfg.source.contact_profile))
    case "raised_cosine"
        % Adding one node spacing to the denominator keeps edge nodes
        % nonzero while tapering smoothly toward the unforced exterior.
        weights = 0.5*(1 + cos(pi*offsets/(radius_points + spacing)));
    case "gaussian"
        sigma_points = max(radius_points/2, 1);
        weights = exp(-0.5*(offsets/sigma_points).^2);
    case "uniform"
        weights = ones(size(offsets));
    otherwise
        error('kwsim:InvalidContactProfile', ...
            'Unsupported finite-contact profile: %s.', cfg.source.contact_profile);
end
weights = weights/max(weights);
end

function candidate = makeCandidate(side, center, node_indices, weights, tangent, cfg)
candidate = emptyCandidate();
candidate.side = string(side);
candidate.center_index_xz = center;
candidate.contact_node_indices = node_indices(:);
candidate.contact_node_weights = weights(:);
candidate.tangent_xz = tangent;
candidate.mask_xz = false(cfg.grid.Nx, cfg.grid.Nz);
candidate.mask_xz(node_indices) = true;
node_coordinates = zeros(numel(node_indices), 2);
[node_x, node_z] = ind2sub([cfg.grid.Nx, cfg.grid.Nz], node_indices);
node_coordinates(:,1) = node_x;
node_coordinates(:,2) = node_z;
candidate.realized_span_points = max(node_coordinates*tangent.') - ...
    min(node_coordinates*tangent.');
end

function remaining = removeOverlappingCandidates(candidates, selected)
occupied = false(size(candidates(1).mask_xz));
for index = 1:numel(selected)
    occupied = occupied | selected(index).mask_xz;
end
keep = true(numel(candidates), 1);
expanded = conv2(double(occupied), ones(3), 'same') > 0;
for index = 1:numel(candidates)
    keep(index) = ~any(expanded & candidates(index).mask_xz, 'all');
end
remaining = candidates(keep);
end

function side = directionToSourceSide(direction)
if abs(direction(1)) >= abs(direction(2))
    if direction(1) >= 0
        side = "left";
    else
        side = "right";
    end
else
    if direction(2) >= 0
        side = "top";
    else
        side = "bottom";
    end
end
end

function value = wrapToPiLocal(value)
value = mod(value + pi, 2*pi) - pi;
end

function candidate = emptyCandidate()
candidate = struct('side', "", 'center_index_xz', [NaN, NaN], ...
    'contact_node_indices', zeros(0, 1), ...
    'contact_node_weights', zeros(0, 1), 'tangent_xz', [NaN, NaN], ...
    'mask_xz', false(0, 0), 'realized_span_points', NaN);
end

function vibrator = emptyVibrator()
vibrator = struct('id', 0, 'group', "", 'side', "", ...
    'center_index_xz', [NaN, NaN], 'center_m_xz', [NaN, NaN], ...
    'contact_tangent_xz', [NaN, NaN], ...
    'contact_node_indices', zeros(0, 1), ...
    'contact_node_weights', zeros(0, 1), 'contact_node_count', 0, ...
    'effective_contact_node_count', NaN, ...
    'solver_channel_labels', zeros(0, 1, 'uint16'), ...
    'realized_contact_span_m', NaN, ...
    'propagation_xz', [NaN, NaN], 'polarization_xz', [NaN, NaN], ...
    'phase_rad', NaN, 'peak_velocity_m_s', NaN, ...
    'contact_node_peak_velocities_m_s', zeros(0, 1), ...
    'drive_power_weight', NaN, ...
    'prescribed_drive_rms_squared_m2_s2', NaN);
end

function channel = emptyChannel()
channel = struct('label', 0, 'vibrator_id', 0, ...
    'node_linear_index', 0, 'node_index_xz', [NaN, NaN], ...
    'spatial_weight', NaN, 'peak_velocity_m_s', NaN);
end
