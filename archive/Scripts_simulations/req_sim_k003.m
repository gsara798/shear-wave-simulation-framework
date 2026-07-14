% EXP ID: REQ-SIM-K003
% Author:   Gilmer A. Flores Barrera
% Date:   2026-02-20
% Description:
% 	Version inicial: 
%   Simulation Oestreicher: Multiple Spheres oscillating on homogeneous phantom 
%   w/ reflections, free boundary, random phase, random direction, random
%   position and customizable inclusion 

clc; clear; close all;

% Path with k-wave library (functions) 
addpath("C:\Users\gflor10\OneDrive - University of Rochester\" + ...
    "Desktop\University of Rochester\Research\Simulations\k-Wave");

%Path with vol3d.m
addpath("C:\Users\gflor10\OneDrive - University of Rochester\" + ...
    "Desktop\University of Rochester\Research\OCE experiments\OCE_codes");

format compact;
set(0,'DefaultFigureVisible','on');   % key line
set(0,'defaultAxesFontSize',20);
set(0,'defaultAxesFontName','Cambria')
% set(groot, 'defaultAxesTickLabelInterpreter','tex'); 
% set(groot, 'defaultLegendInterpreter','tex');
% set(0,'defaulttextInterpreter','tex');

% -----------------------------
% DataCast: try GPU, fallback to CPU
% -----------------------------
USE_GPU = true;
if USE_GPU
    DATA_CAST = 'gpuArray-single';
else
    DATA_CAST = 'single';
end

%% Create the computational grid
Nx = 200;           % number of grid points in the x direction
Ny = 200;           % number of grid points in the y direction
dx = 0.5e-3;          % grid spacing in x [m]
dy = 0.5e-3;          % grid spacing in y [m]
kgrid = kWaveGrid(Nx, dx, Ny, dy);

%% Define medium properties
medium.sound_speed_compression = 1540 * ones(Nx, Ny);   % [m/s] realistic compressional speed
medium.sound_speed_shear = 2 * ones(Nx, Ny);            % [m/s] for gelatin-like shear
medium.density = 1000 * ones(Nx, Ny);                   % [kg/m^3]

% Attenuation
medium.alpha_coeff_compression = 0.05;    % [dB/(MHz^2 cm)]
medium.alpha_coeff_shear = 100;           % [dB/(MHz^2 cm)]
% medium.alpha_power_shear = 1.3;

% % Add boundary
 boundary.thickness = 0;
% boundary.density = 1.2;
% boundary.sws = 0.1;
% boundary.pws= 30;
% 
% %AIR/Rigid Boundary
% medium.density(:,1:boundary.thickness) = boundary.density;
% medium.density(:,end-boundary.thickness:end) = boundary.density;
% medium.density(1:boundary.thickness,:) = boundary.density;
% medium.density(end-boundary.thickness:end,:) = boundary.density;
% 
% medium.sound_speed_shear(:, 1:boundary.thickness) = boundary.sws;
% medium.sound_speed_shear(:,end-boundary.thickness:end) = boundary.sws;
% medium.sound_speed_shear(1:boundary.thickness,:) = boundary.sws;
% medium.sound_speed_shear(end-boundary.thickness:end,:) = boundary.sws;
% 
% medium.sound_speed_compression(:, 1:boundary.thickness) = boundary.pws;
% medium.sound_speed_compression(:,end-boundary.thickness:end) = boundary.pws;
% medium.sound_speed_compression(1:boundary.thickness,:) = boundary.pws;
% medium.sound_speed_compression(end-boundary.thickness:end,:) = boundary.pws;

%TX
% medium.density(1:boundary.thickness,40:60) = 12; 
% medium.sound_speed_shear(1:boundary.thickness,40:60) = 1000; 
% medium.sound_speed_compression(1:boundary.thickness,40:60) = 1500;

% %% Define Inclusion
% letter_size=60;
% letter='R';
% BW = createInclusionLetter(letter_size,letter);
% % Crear máscara global del dominio
% inclusion_mask = zeros(Nx, Ny);
% % Centro donde colocar la letra
% cx = round(Nx/2);
% cy = round(Ny/2);
% % Índices de inserción
% xs = cx - floor(letter_size/2);
% ys = cy - floor(letter_size/2);
% inclusion_mask(xs:xs+letter_size-1, ys:ys+letter_size-1) = BW;

%% --- Inclusion parameters (grid points) ---
inc_radius = 12;                  % radius in grid points
inc_cx = round(Nx/2);
inc_cy = round(Ny/2);

% Binary mask for the inclusion
inc_mask = makeDisc(Nx, Ny, inc_cx, inc_cy, inc_radius);
inc_mask = inc_mask > 0;          % make logical

% --- Modify medium inside inclusion ---
% Example: stiffer + slightly denser inclusion
medium.sound_speed_shear(inc_mask)       = 6;     % m/s (background was 3)
medium.sound_speed_compression(inc_mask) = 1600;  % m/s (background 1500)
medium.density(inc_mask)                = 1100;  % kg/m^3 (background 1000)

% Optional: change attenuation inside inclusion
% medium.alpha_coeff_shear(inc_mask) = 200;

% Propiedades de la inclusión
medium.sound_speed_compression(inclusion_mask == 1)  = 1500;   % [m/s] realistic compressional speed
medium.sound_speed_shear(inclusion_mask == 1) = 3;    % más rígida
medium.density(inclusion_mask == 1) = 1000;   

%% Plotting Medium 
% Extract shear wave speed map
sws = medium.sound_speed_compression;   % (Nx x Ny)

% Grid vectors (centers)
x = (0:Nx-1) * dx;   % lateral
z = (0:Ny-1) * dy;   % depth (use y as depth)

% Plot (transpose for correct orientation)
figure
imagesc(x, z, sws,[1450 1600])
axis image
set(gca,'YDir','reverse')   % depth increases downward (US style)

xlabel('Lateral (m)')
ylabel('Depth (m)')
title('Simulated Shear Wave Speed (m/s)')
colorbar
colormap(turbo)


%% Time array (safe dt based on c_max)
t_end = 0.3;  % [s] to allow steady-state observation
c_max = max([max(medium.sound_speed_compression(:)), max(medium.sound_speed_shear(:))]);
cfl = 0.3;
kgrid.makeTime(c_max, cfl, t_end);

%% --- Multiple disc actuators with random direction + random phase ---
%rng(0);
num_act     = 4;
radius_pts  = 7;
surf_offset = 2;

margin  = 10;
cx_list = round(linspace(1+margin, Nx-margin, num_act));
cy      = 1 + surf_offset;

% Build mask_total as 0/1 (uint8) + label map
mask_total     = zeros(Nx, Ny, 'uint8');      % 0/1 numeric
actuator_label = zeros(Nx, Ny, 'uint16');

for k = 1:num_act
    disc = makeDisc(Nx, Ny, cx_list(k), cy, radius_pts);  % numeric 0/1
    disc = uint8(disc > 0);                               % force 0/1

    mask_total = mask_total | disc;
    actuator_label(disc == 1) = uint16(k);
end

source.u_mask = mask_total;          % IMPORTANT: numeric 0/1 mask

% Sizes
t  = kgrid.t_array(:);
Nt = numel(t);
Ns = nnz(source.u_mask);             % number of source elements EXACT

% Random direction + random phase per actuator
theta = 2*pi*rand(num_act,1);
phi   = 2*pi*rand(num_act,1);
dir_x = cos(theta);
dir_y = sin(theta);

source_freq = 500;
source_mag  = 1e-6;

% Map each source element -> actuator id (same linear indexing order k-Wave uses)
src_lin = find(source.u_mask);                 % Ns×1 linear indices
k_id    = double(actuator_label(src_lin));     % Ns×1 in {1..num_act}

if any(k_id==0)
    error("Some source points have actuator_label==0 (labeling bug / overlap).");
end

% Build Nt×Ns signals (vectorized)
S = sin(2*pi*source_freq*t + phi(k_id).');     % Nt×Ns

source.ux = (single(source_mag) .* single(S) .* single(dir_x(k_id).'))';   % Nt×Ns
source.uy = (single(source_mag) .* single(S) .* single(dir_y(k_id).'))';   % Nt×Ns

% Hard checks (will stop here if anything is off)
assert(size(source.ux,1)==Ns && size(source.ux,2)==Nt, "ux mismatch");
assert(size(source.uy,1)==Ns && size(source.uy,2)==Nt, "uy mismatch");


%% Define sensor ROI like a Linear Transducer image (rectangular ROI)
% --- ROI settings (in GRID POINTS) ---
roi_lat_pts   = 40;   % lateral width (# points)
roi_depth_pts = 40;   % axial depth (# points)
depth_offset  = 0;    % additional offset (points) to go deeper if needed

% --- "TX" location at top, centered on sphere axis ---
tx_x = Nx/2;                                % lateral center
tx_y = boundary.thickness + 1;                    % just below air boundary (top)

% --- ROI indices (x = lateral, y = depth/axial in your grid) ---
x0 = tx_x - floor(roi_lat_pts/2);
x1r = x0 + roi_lat_pts - 1;

y0 = tx_y + depth_offset;                         % start depth
y1 = y0 + roi_depth_pts - 1;

% Clamp to stay inside the *phantom* (avoid air boundary zones)
x0 = max(x0, boundary.thickness + 1);
x1r = min(x1r, Nx - boundary.thickness);

y0 = max(y0, boundary.thickness + 1);
y1 = min(y1, Ny - boundary.thickness);

x_idx = x0:x1r;                                   % lateral
y_idx = y0:y1;                                    % axial (depth)

% Build mask
sensor.mask = zeros(Nx, Ny);
sensor.mask(x_idx, y_idx) = 1;
sensor.record = {'u', 'u_split_field'};

%% Run simulation
input_args = {'PMLAlpha',2, 'PlotPML', false, 'PMLInside', false, ...
              'DisplayMask', 'off', 'PlotSim', true, 'DataCast', DATA_CAST};

try
    fprintf("Ns(mask)=%d, Nt=%d, size(ux)=[%d %d], size(uy)=[%d %d]\n", ...
    nnz(source.u_mask), numel(kgrid.t_array), size(source.ux,1), size(source.ux,2), ...
    size(source.uy,1), size(source.uy,2));
    sensor_data = pstdElastic2D(kgrid, medium, source, sensor, input_args{:});
    E=MException('req_sim_k001','%s',pwd);
catch E
    % GPU fallback (common if CUDA/toolbox mismatch)
    if USE_GPU
        warning(E.identifier,'%s', E.message);
        input_args{end} = 'single';
        sensor_data = pstdElastic2D(kgrid, medium, source, sensor, input_args{:});
    else
        rethrow(ME);
    end
end

%% Gather outputs (handles both gpuArray + cpu)
if USE_GPU
    ux_s = gather(reshape(sensor_data.ux_split_s, numel(x_idx), numel(y_idx), []));
    ux_p = gather(reshape(sensor_data.ux_split_p, numel(x_idx), numel(y_idx), []));
    ux_total = gather(reshape(sensor_data.ux, numel(x_idx), numel(y_idx), []));
else
    ux_s = sensor_data.ux_split_s;
    ux_p = sensor_data.ux_split_p;
    ux_total = sensor_data.ux;
end

dinf.dx = dx;
dinf.dy = dy;
dinf.dt = kgrid.dt;

 %% Visualization
% figure
% xx = dinf.dx * (0:size(ux_total,1)-1);
% yy = dinf.dy * (0:size(ux_total,2)-1);
% for ii = 1:500:60000
%     im = real(squeeze(ux_total(:,:,ii)));  % amplitude of shear wave
%     imagesc(yy(10:end),xx, im);
%     xlabel('x (m)'); ylabel('y (m)');
%     axis image;
%     clim(6e-5*[-1 1]);
%     title(['Frame ' num2str(ii)]);
%     grid on;
%     colormap('jet');
%     colorbar;
%     drawnow
%     pause(0.1)
% end

 %%

Nt = size(ux_total,3);
Nt_target = min(1000, Nt);

t_idx = round(linspace(1, Nt, Nt_target));   % uniform sampling indices (length ~1000)
t_idx = unique(t_idx, 'stable');             % just in case rounding duplicates

ux_s     = ux_s(:,:,t_idx);
ux_p     = ux_p(:,:,t_idx);
ux_total = ux_total(:,:,t_idx);

% Update time info
t_ds = kgrid.t_array(t_idx);
dinf.dt = mean(diff(t_ds));   % effective dt after downsampling
% Optional: save
filename = ['req_sim_k003_' num2str(source_freq) 'Hz'];
save(filename, "ux_total", "ux_p", "ux_s", "dinf", "source_freq", '-v7.3');

%%
energy_t = zeros(1, size(ux_s,3));
for ii = 1:size(ux_s,3)
    frame = ux_s(:,:,ii);
    energy_t(ii) = sum(frame(:).^2);  % proportional to elastic energy
end

% 2. Difference between consecutive frames
diff_energy = zeros(1, size(ux_s,3)-1);
for ii = 1:(size(ux_s,3)-1)
    diff = ux_s(:,:,ii+1) - ux_s(:,:,ii);
    diff_energy(ii) = sum(diff(:).^2);
end

%% Optional: energy plots saved to disk (still no pop-up)
energy_t = zeros(1, size(ux_total,2));  % depends on sensor geometry
for ii = 1:size(ux_total,2)
    frame = ux_total(:,ii);
    energy_t(ii) = sum(frame(:).^2);
end

fig1 = figure('Visible','on');
plot(energy_t, 'LineWidth', 2);
xlabel('Time [s]'); ylabel('Total Energy (proxy)');
title('Recorded field energy vs time'); grid on;
exportgraphics(fig1, filename + "_energy.png", 'Resolution', 200);
close(fig1);

figure
xx = dinf.dx * (0:size(ux_s,1)-1);
yy = dinf.dy * (0:size(ux_s,2)-1);
for ii = 1:10:1000
    im = real(squeeze(ux_s(:,:,ii)));  % amplitude of shear wave
    imagesc(yy(1:end),xx, im);
    xlabel('x (m)'); ylabel('y (m)');
    axis image;
    clim(1e-4*[-1 1]);
    title(['Frame ' num2str(ii)]);
    grid on;
    colormap('jet');
    colorbar;
    drawnow
    pause(0.1)
end