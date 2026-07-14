function OUT = run_controlled_2d(CFG)
%RUN_CONTROLLED_2D Run a small, reproducible 2D elastic k-Wave simulation.
%
% This is a project-native wrapper around pstdElastic2D. It is deliberately
% explicit rather than clever: build material maps, build source locations,
% record the selected shear component, extract the f0 phasor, and return both k-Wave
% orientation (x,z) and adaptive_req orientation (z,x).

arguments
    CFG struct
end

if ~isfield(CFG, 'KWavePath')
    CFG.KWavePath = "";
end
kwave_root = adaptive_req.kwave.locate_kwave_toolbox(CFG.KWavePath);
rng(CFG.Seed, 'twister');

MAT = adaptive_req.kwave.make_material_map_2d(CFG);

kgrid = kWaveGrid(CFG.Nx, CFG.dx, CFG.Nz, CFG.dz);
c_max = max(MAT.cp_xz(:));
kgrid.makeTime(c_max, CFG.CFL, CFG.t_end);

medium = struct();
medium.sound_speed_compression = MAT.cp_xz;
medium.sound_speed_shear = MAT.cs_xz;
medium.density = MAT.rho_xz;
medium.alpha_coeff_compression = CFG.alpha_compression;
medium.alpha_coeff_shear = CFG.alpha_shear;

source = build_source(CFG, kgrid);

sensor = struct();
sensor.mask = true(CFG.Nx, CFG.Nz);
sensor.record = {'u_split_field'};

input_args = {'PMLInside', CFG.PMLInside, 'PMLSize', CFG.PMLSize, ...
    'DataCast', CFG.DataCast, 'PlotSim', CFG.PlotSim};

t0 = tic;
sensor_data = pstdElastic2D(kgrid, medium, source, sensor, input_args{:});
runtime_s = toc(t0);

shear_component = select_shear_component(sensor_data, sensor.mask, CFG);

H = adaptive_req.kwave.extract_harmonic_field( ...
    shear_component.field_xzt, kgrid.dt, CFG.f0, 'Cycles', 8, 'DiscardCycles', 2);

ROI = analysis_roi_indices(CFG);
Uxz_full = H.Uxz;
source_mask_zx_full = source.u_mask.';

OUT = struct();
OUT.CFG = CFG;
OUT.kwave_root = kwave_root;
OUT.kgrid_dt = kgrid.dt;
OUT.kgrid_t_array = kgrid.t_array;
OUT.runtime_s = runtime_s;
OUT.material = MAT;
OUT.source_mask_xz = source.u_mask;
OUT.source_mask_zx_full = source_mask_zx_full;
OUT.source_points_xz = source_points_from_mask(source.u_mask, CFG);
OUT.source_mode = CFG.SourceMode;
OUT.velocity_component = CFG.VelocityComponent;
OUT.velocity_component_label = shear_component.label;
OUT.sensor_data_fields = fieldnames(sensor_data);
OUT.selected_shear_time_xzt = shear_component.field_xzt;
OUT.harmonic = H;
OUT.full_Uxz = Uxz_full;
OUT.full_cs_map = MAT.cs_map_zx;
OUT.full_material_id = MAT.material_id_zx;
OUT.analysis_roi = ROI;
OUT.analysis_origin_m = [(ROI.x_idx(1) - 1) * CFG.dx, (ROI.z_idx(1) - 1) * CFG.dz];
OUT.Uxz = Uxz_full(ROI.z_idx, ROI.x_idx);
OUT.x_m = CFG.x_m(ROI.x_idx);
OUT.z_m = CFG.z_m(ROI.z_idx);
OUT.cs_map = MAT.cs_map_zx(ROI.z_idx, ROI.x_idx);
OUT.material_id = MAT.material_id_zx(ROI.z_idx, ROI.x_idx);
OUT.source_mask_zx = source_mask_zx_full(ROI.z_idx, ROI.x_idx);
OUT.diag = struct('runtime_s', runtime_s, 'n_time_samples', numel(kgrid.t_array), ...
    'dt', kgrid.dt, 'kwave_root', kwave_root);

end

function ROI = analysis_roi_indices(CFG)

mode = lower(string(CFG.AnalysisROIMode));
margin_x = max(0, round(CFG.AnalysisMarginM / CFG.dx));
margin_z = max(0, round(CFG.AnalysisMarginM / CFG.dz));
buffer_x = max(0, round(CFG.AnalysisBufferM / CFG.dx));
buffer_z = max(0, round(CFG.AnalysisBufferM / CFG.dz));

x1 = 1 + margin_x;
x2 = CFG.Nx - margin_x;
z1 = 1 + margin_z;
z2 = CFG.Nz - margin_z;

switch mode
    case "full"
        x1 = 1; x2 = CFG.Nx; z1 = 1; z2 = CFG.Nz;

    case {"exclude_source_buffer", "source_buffer", "cropped"}
        switch lower(string(CFG.SourceSide))
            case "left"
                x1 = max(x1, 1 + buffer_x);
            case "right"
                x2 = min(x2, CFG.Nx - buffer_x);
            case "top"
                z1 = max(z1, 1 + buffer_z);
            case "bottom"
                z2 = min(z2, CFG.Nz - buffer_z);
        end

    otherwise
        error('Unknown AnalysisROIMode: %s. Use full or exclude_source_buffer.', mode);
end

if x2 <= x1 || z2 <= z1
    error(['Analysis ROI is empty. Reduce AnalysisBufferM/AnalysisMarginM ', ...
        'or increase Nx/Nz. Current x=[%d,%d], z=[%d,%d].'], x1, x2, z1, z2);
end

ROI = struct();
ROI.mode = mode;
ROI.x_idx = x1:x2;
ROI.z_idx = z1:z2;
ROI.xlim_m = [(x1 - 1) * CFG.dx, (x2 - 1) * CFG.dx];
ROI.zlim_m = [(z1 - 1) * CFG.dz, (z2 - 1) * CFG.dz];
ROI.origin_m = [ROI.xlim_m(1), ROI.zlim_m(1)];
ROI.size_px = [numel(ROI.z_idx), numel(ROI.x_idx)];

end

function C = select_shear_component(sensor_data, mask, CFG)

component = lower(string(CFG.VelocityComponent));
ux = [];
uz = [];

if isfield(sensor_data, 'ux_split_s')
    ux = reshape_sensor_field(sensor_data.ux_split_s, mask, CFG);
elseif isfield(sensor_data, 'ux_s')
    ux = reshape_sensor_field(sensor_data.ux_s, mask, CFG);
end

if isfield(sensor_data, 'uy_split_s')
    uz = reshape_sensor_field(sensor_data.uy_split_s, mask, CFG);
elseif isfield(sensor_data, 'uy_s')
    uz = reshape_sensor_field(sensor_data.uy_s, mask, CFG);
end

switch component
    case {"axial_shear", "uz", "uy", "depth_shear"}
        if isempty(uz)
            error('Requested axial shear component, but uy_split_s/uy_s was not returned by k-Wave.');
        end
        C.field_xzt = uz;
        C.label = "axial shear velocity (u_z / k-Wave uy)";

    case {"lateral_shear", "ux"}
        if isempty(ux)
            error('Requested lateral shear component, but ux_split_s/ux_s was not returned by k-Wave.');
        end
        C.field_xzt = ux;
        C.label = "lateral shear velocity (u_x)";

    case {"shear_magnitude", "magnitude"}
        if isempty(ux) || isempty(uz)
            error('Requested shear magnitude, but both ux and uy shear components are required.');
        end
        C.field_xzt = hypot(ux, uz);
        C.label = "shear velocity magnitude";

    otherwise
        error('Unknown VelocityComponent: %s. Use axial_shear, lateral_shear, or shear_magnitude.', component);
end

end

function U = reshape_sensor_field(raw, mask, CFG)

if ndims(raw) == 3 && isequal(size(raw, 1), CFG.Nx) && ...
        isequal(size(raw, 2), CFG.Nz)
    U = raw;
    return;
end

n_sensor = nnz(mask);
if ismatrix(raw) && size(raw, 1) == n_sensor
    U = reshape(raw, CFG.Nx, CFG.Nz, []);
elseif ismatrix(raw) && size(raw, 2) == n_sensor
    U = reshape(raw.', CFG.Nx, CFG.Nz, []);
else
    error('Cannot reshape k-Wave sensor field of size %s to %d-by-%d-by-Nt.', ...
        mat2str(size(raw)), CFG.Nx, CFG.Nz);
end

end

function source = build_source(CFG, kgrid)

source = struct();
[centers_x, centers_z, directions] = source_centers_and_directions(CFG);
radius_px = max(1, round(CFG.source_radius_m / CFG.dx));

mask = false(CFG.Nx, CFG.Nz);
label = zeros(CFG.Nx, CFG.Nz);
for i = 1:numel(centers_x)
    disc = makeDisc(CFG.Nx, CFG.Nz, centers_x(i), centers_z(i), radius_px);
    new_pixels = disc > 0 & ~mask;
    mask = mask | (disc > 0);
    label(new_pixels) = i;
end

source.u_mask = mask;
n_pixels = nnz(mask);
n_t = numel(kgrid.t_array);
ux = zeros(n_pixels, n_t);
uz = zeros(n_pixels, n_t);

pix_label = label(mask);
for i = 1:numel(centers_x)
    idx = pix_label == i;
    phase0 = 2*pi*rand();
    switch CFG.SourceMode
        case "single_square"
            waveform = sign(sin(2*pi*CFG.f0*kgrid.t_array + phase0));
            waveform(waveform == 0) = 1;
        otherwise
            waveform = sin(2*pi*CFG.f0*kgrid.t_array + phase0);
    end
    n_i = nnz(idx);
    ux(idx, :) = repmat(CFG.source_magnitude * directions(i, 1) * waveform, n_i, 1);
    uz(idx, :) = repmat(CFG.source_magnitude * directions(i, 2) * waveform, n_i, 1);
end

source.ux = ux;
source.uy = uz;

end

function [cx, cz, directions] = source_centers_and_directions(CFG)

mode = lower(string(CFG.SourceMode));
radius_px = max(1, round(CFG.source_radius_m / CFG.dx));
margin = radius_px + 2;

switch mode
    case {"single_sine", "single_square"}
        [cx, cz] = source_point_on_side(CFG.SourceSide, CFG, margin);
        directions = source_polarization(CFG.SourcePolarization, CFG.SourceSide, cx, cz, CFG);

    case {"sources8_sine", "sources128_sine"}
        n = CFG.num_sources;
        cx = zeros(n, 1);
        cz = zeros(n, 1);
        directions = zeros(n, 2);

        % Force one source in the requested canonical side. With axial
        % polarization and side placement, the main propagation is lateral
        % while the measured component is axial, matching an ultrasound-like
        % shear observation.
        [cx(1), cz(1)] = source_point_on_side(CFG.SourceSide, CFG, margin);
        directions(1, :) = source_polarization(CFG.SourcePolarization, ...
            CFG.SourceSide, cx(1), cz(1), CFG);

        for i = 2:n
            side = randi(4);
            switch side
                case 1 % top
                    cx(i) = randi([margin, CFG.Nx - margin]);
                    cz(i) = margin;
                    target = [CFG.Nx / 2 - cx(i), CFG.Nz / 2 - cz(i)];
                case 2 % bottom
                    cx(i) = randi([margin, CFG.Nx - margin]);
                    cz(i) = CFG.Nz - margin;
                    target = [CFG.Nx / 2 - cx(i), CFG.Nz / 2 - cz(i)];
                case 3 % left
                    cx(i) = margin;
                    cz(i) = randi([margin, CFG.Nz - margin]);
                    target = [CFG.Nx / 2 - cx(i), CFG.Nz / 2 - cz(i)];
                otherwise % right
                    cx(i) = CFG.Nx - margin;
                    cz(i) = randi([margin, CFG.Nz - margin]);
                    target = [CFG.Nx / 2 - cx(i), CFG.Nz / 2 - cz(i)];
            end
            if CFG.SourcePolarization == "radial"
                target = target + 0.15 * randn(1, 2) * norm(target);
                directions(i, :) = target / max(norm(target), eps);
            else
                directions(i, :) = source_polarization(CFG.SourcePolarization, ...
                    side_name(side), cx(i), cz(i), CFG);
            end
        end

    otherwise
        error('Unknown SourceMode: %s', mode);
end

cx = round(cx(:));
cz = round(cz(:));

end

function [cx, cz] = source_point_on_side(side, CFG, margin)

switch lower(string(side))
    case "left"
        cx = margin;
        cz = round(CFG.Nz / 2);
    case "right"
        cx = CFG.Nx - margin;
        cz = round(CFG.Nz / 2);
    case "top"
        cx = round(CFG.Nx / 2);
        cz = margin;
    case "bottom"
        cx = round(CFG.Nx / 2);
        cz = CFG.Nz - margin;
    otherwise
        error('Unknown SourceSide: %s. Use left, right, top, or bottom.', side);
end

end

function d = source_polarization(mode, side, cx, cz, CFG)

switch lower(string(mode))
    case {"axial", "axial_shear", "z"}
        d = [0, 1];
    case {"lateral", "x"}
        d = [1, 0];
    case "radial"
        target = [CFG.Nx / 2 - cx, CFG.Nz / 2 - cz];
        d = target / max(norm(target), eps);
    case "transverse"
        target = [CFG.Nx / 2 - cx, CFG.Nz / 2 - cz];
        radial = target / max(norm(target), eps);
        d = [-radial(2), radial(1)];
    otherwise
        error('Unknown SourcePolarization: %s.', mode);
end

% Keep sign convention predictable for side sources with axial measurement.
if any(lower(string(side)) == ["left", "right"]) && any(lower(string(mode)) == ["axial", "axial_shear", "z"])
    d = [0, 1];
end

end

function s = side_name(side_id)
switch side_id
    case 1, s = "top";
    case 2, s = "bottom";
    case 3, s = "left";
    otherwise, s = "right";
end
end

function P = source_points_from_mask(mask, CFG)

[ix, iz] = find(mask);
P = table();
P.ix = ix;
P.iz = iz;
P.x_m = (ix - 1) * CFG.dx;
P.z_m = (iz - 1) * CFG.dz;

end
