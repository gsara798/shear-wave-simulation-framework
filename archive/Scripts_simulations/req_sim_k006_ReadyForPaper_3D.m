% EXP ID: REQ-SIM-K006-ReadyForPaper-3D Rev
% Author: Gilmer A. Flores Barrera
% Date:   2026-03-13
% Description:
% 	Version inicial: 
%   Simulation Oestreicher: Multiple Spheres oscillating on homogeneous phantom 
%   w/ reflections, free boundary, random phase, random direction, random
%   position and customizable inclusion 

clc; clear; close all;

% Path with k-wave library (functions) 
addpath("C:\Users\gflor10\Box\REQ Estimator\Simulations\k-Wave");

%Path with vol3d.m
% addpath("C:\Users\gflor10\OneDrive - University of Rochester\" + ...
%     "Desktop\University of Rochester\Research\OCE experiments\OCE_codes");

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
Nx = 160;           % number of grid points in the x direction
Ny = 160;           % number of grid points in the y direction
Nz = 160;      % or 80, 100, etc.

dx = 0.5e-3;          % grid spacing in x [m]
dy = 0.5e-3;          % grid spacing in y [m]
dz = 0.5e-3;

kgrid = kWaveGrid(Nx, dx, Ny, dy, Nz, dz);

%% Define medium properties
medium.sound_speed_compression = 2 * ones(Nx, Ny, Nz);   % [m/s] realistic compressional speed
medium.sound_speed_shear = 2 * ones(Nx, Ny, Nz);            % [m/s] for gelatin-like shear
medium.density = 1000 * ones(Nx, Ny, Nz);                   % [kg/m^3]

% Attenuation
medium.alpha_coeff_compression = 0.05;    % [dB/(MHz^2 cm)]
medium.alpha_coeff_shear = 100;           % [dB/(MHz^2 cm)]
% medium.alpha_power_shear = 1.3;

boundary.thickness=0;

%% --- Inclusion parameters (grid points) ---
inc_radius = 20;                  % radius in grid points
inc_cx = round(Nx/2);
inc_cy = round(Ny/2);
inc_cz = round(Nz/2);

% Binary mask for the inclusion
inc_mask = makeBall(Nx, Ny, Nz, inc_cx, inc_cy, inc_cz, inc_radius);
inc_mask = inc_mask>0;

% --- Modify medium inside inclusion ---
% Example: stiffer + slightly denser inclusion
medium.sound_speed_shear(inc_mask)       = 3;     % m/s (background was 3)
medium.sound_speed_compression(inc_mask) = 3;  % m/s (background 1500)
medium.density(inc_mask)                = 1020;  % kg/m^3 (background 1000)

% Optional: change attenuation inside inclusion
% medium.alpha_coeff_shear(inc_mask) = 200;

% Propiedades de la inclusión
% medium.sound_speed_compression(inclusion_mask == 1)  = 1500;   % [m/s] realistic compressional speed
% medium.sound_speed_shear(inclusion_mask == 1) = 3;    % más rígida
% medium.density(inclusion_mask == 1) = 1000;   

%% Plotting Medium (imaging plane)
z_sensor = round(Nz/2);

sws = medium.sound_speed_shear(:,:,z_sensor);   % take 2D slice

x = (0:Nx-1) * dx;
y = (0:Ny-1) * dy;

figure
imagesc(x*100, y*100, sws', [1 4])
axis image
set(gca,'YDir','reverse')

xlabel('Lateral (cm)')
ylabel('Depth (cm)')
title(['Shear Wave Speed Slice (z = ' num2str(z_sensor) ')'])
colorbar
colormap(turbo)
%%
[X,Y,Z] = ndgrid((0:Nx-1)*dx*100, (0:Ny-1)*dy*100, (0:Nz-1)*dz*100);

figure
p = patch(isosurface(X,Y,Z,medium.sound_speed_shear,2.5));
set(p,'FaceColor','red','EdgeColor','none','FaceAlpha',0.5)

daspect([1 1 1])
view(3)
camlight
lighting gouraud
xlabel('Lateral (cm)')
ylabel('Depth (cm)')
zlabel('Elevation (cm)')
title('3D isosurface of shear wave speed')
grid on
%% Time array (safe dt based on c_max)
t_end = 0.1;  % [s] to allow steady-state observation
c_max = max([max(medium.sound_speed_compression(:)), ...
             max(medium.sound_speed_shear(:))]);
cfl = 0.3;
kgrid.makeTime(c_max, cfl, t_end);

%% --- Multiple spherical actuators with random direction + random phase ---
% One actuator is forced to lie in the transducer plane and oscillate in-plane

% rng(0);   % uncomment for reproducibility

num_act    = 128;      % total actuators
radius_pts = 14;     % sphere radius in grid points
margin     = 15;     % safety margin from boundaries
%min_sep    = 2*radius_pts + 1;   % minimum center-to-center separation
min_sep    = radius_pts;
max_trials = 500;

% Transducer imaging plane (x-y plane at fixed z)
z_sensor = round(Nz/2);

% Allowed face IDs:
% 1 = TOP    (y = small)
% 2 = BOTTOM (y = large)
% 3 = LEFT   (x = small)
% 4 = RIGHT  (x = large)
% 5 = FRONT  (z = small)
% 6 = BACK   (z = large)

face_id = randi(6, [num_act, 1]);   % random face for each actuator

% Safe coordinate limits so full sphere stays inside the domain
x_min = margin + radius_pts + 1;
x_max = Nx - margin - radius_pts;

y_min = margin + radius_pts + 1;
y_max = Ny - margin - radius_pts;

z_min = margin + radius_pts + 1;
z_max = Nz - margin - radius_pts;

% Actuator centers
cx_list = zeros(num_act,1);
cy_list = zeros(num_act,1);
cz_list = zeros(num_act,1);

placed_centers = [];   % each row = [cx cy cz]

for k = 1:num_act
    placed = false;

    for trial = 1:max_trials

        if k == 1
            % ----------------------------------------------------------
            % FORCE actuator 1:
            % - on the TOP surface
            % - in the same elevation plane as the transducer
            % ----------------------------------------------------------
            cx = round(Nx/2);
            cy = y_min;
            cz = z_sensor;

        else
            switch face_id(k)
                case 1   % TOP
                    cx = randi([x_min, x_max]);
                    cy = y_min;
                    cz = randi([z_min, z_max]);

                case 2   % BOTTOM
                    cx = randi([x_min, x_max]);
                    cy = y_max;
                    cz = randi([z_min, z_max]);

                case 3   % LEFT
                    cx = x_min;
                    cy = randi([y_min, y_max]);
                    cz = randi([z_min, z_max]);

                case 4   % RIGHT
                    cx = x_max;
                    cy = randi([y_min, y_max]);
                    cz = randi([z_min, z_max]);

                case 5   % FRONT
                    cx = randi([x_min, x_max]);
                    cy = randi([y_min, y_max]);
                    cz = z_min;

                case 6   % BACK
                    cx = randi([x_min, x_max]);
                    cy = randi([y_min, y_max]);
                    cz = z_max;
            end
        end

        % Enforce minimum separation
        if isempty(placed_centers)
            ok = true;
        else
            d = sqrt(sum((placed_centers - [cx cy cz]).^2, 2));
            ok = all(d >= min_sep);
        end

        if ok
            cx_list(k) = cx;
            cy_list(k) = cy;
            cz_list(k) = cz;
            placed_centers = [placed_centers; cx cy cz];
            placed = true;
            break;
        end
    end

    if ~placed
        error('Could not place actuator %d without overlap. Reduce num_act, radius_pts, or min_sep.', k);
    end
end

% Build mask_total and label map
mask_total     = zeros(Nx, Ny, Nz, 'uint8');
actuator_label = zeros(Nx, Ny, Nz, 'uint16');

for k = 1:num_act
    sph = makeBall(Nx, Ny, Nz, cx_list(k), cy_list(k), cz_list(k), radius_pts);
    sph = uint8(sph > 0);

    % Only add non-overlapping voxels
    new_vox = (sph == 1) & (mask_total == 0);

    mask_total(new_vox) = 1;
    actuator_label(new_vox) = uint16(k);
end

source.u_mask = mask_total;

% Sizes
t  = kgrid.t_array(:);
Nt = numel(t);
Ns = nnz(source.u_mask);

% Random temporal phase per actuator
phase0 = 2*pi*rand(num_act,1);

% Random 3D directions for all actuators
theta_dir = 2*pi*rand(num_act,1);          % azimuth
phi_dir   = acos(2*rand(num_act,1)-1);     % polar angle

dir_x = sin(phi_dir).*cos(theta_dir);
dir_y = cos(phi_dir);
dir_z = sin(phi_dir).*sin(theta_dir);

% ----------------------------------------------------------
% FORCE actuator 1 to oscillate IN the transducer plane
% Transducer plane = x-y plane => dz = 0
% ----------------------------------------------------------
theta_plane = 2*pi*rand;   % arbitrary in-plane direction

dir_x(1) = cos(theta_plane);
dir_y(1) = sin(theta_plane);
dir_z(1) = 0;

% Optional alternative if you want pure axial motion in the image plane:
% dir_x(1) = 0;
% dir_y(1) = 1;
% dir_z(1) = 0;

source_freq = 500;
source_mag  = 1e-6;

% Map each source voxel -> actuator label
src_lin = find(source.u_mask);
k_id    = double(actuator_label(src_lin));

if any(k_id == 0)
    error('Some source voxels have actuator_label == 0.');
end

% Build Nt x Ns signals
S = sin(2*pi*source_freq*t + phase0(k_id).');

% Convert to Ns x Nt for k-Wave
source.ux = (single(source_mag) .* single(S) .* single(dir_x(k_id).')).';
source.uy = (single(source_mag) .* single(S) .* single(dir_y(k_id).')).';
source.uz = (single(source_mag) .* single(S) .* single(dir_z(k_id).')).';

% Sanity checks
assert(size(source.ux,1)==Ns && size(source.ux,2)==Nt, 'ux mismatch');
assert(size(source.uy,1)==Ns && size(source.uy,2)==Nt, 'uy mismatch');
assert(size(source.uz,1)==Ns && size(source.uz,2)==Nt, 'uz mismatch');

% Debug print
disp(table((1:num_act)', face_id, cx_list, cy_list, cz_list, dir_x, dir_y, dir_z, ...
    'VariableNames', {'Actuator','Face','cx','cy','cz','dx','dy','dz'}));
fprintf('Actuator 1 forced into transducer plane: cz = %d, z_sensor = %d, dz = %.3f\n', ...
    cz_list(1), z_sensor, dir_z(1));
%%
figure
plot3(cx_list, cy_list, cz_list, 'ro', 'MarkerSize', 10, 'LineWidth', 2)
grid on
axis equal
xlim([1 Nx]); ylim([1 Ny]); zlim([1 Nz]);
xlabel('x'); ylabel('y'); zlabel('z');
title('Actuator centers')
view(3)
%% Define sensor ROI like a Linear Transducer image (rectangular ROI)
% --- ROI settings (in GRID POINTS) ---
roi_lat_pts   = 100;   % lateral width (# points)
roi_depth_pts = 100;   % axial depth (# points)
depth_offset  = 0;    % additional offset (points) to go deeper if needed
boundary.thickness=0;

% --- "TX" location at top, centered on sphere axis ---
tx_x = Nx/2;                                % lateral center
tx_y = ceil((Ny-roi_lat_pts)/2);                    % just below air boundary (top)

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
z_sensor = round(Nz/2);

% Build mask
sensor.mask = zeros(Nx, Ny, Nz);
sensor.mask(x_idx, y_idx, z_sensor) = 1;
sensor.record = {'u_split_field'};

%% Run simulation
input_args = {'PMLAlpha',2, 'PlotPML', false, 'PMLInside', false, ...
              'DisplayMask', 'off', 'PlotSim', true, 'DataCast', DATA_CAST};

if USE_GPU
    sensor_data = pstdElastic3D(kgrid, medium, source, sensor, input_args{:});
end 

%% Gather outputs (handles both gpuArray + cpu)
if USE_GPU
    ux_s = gather(reshape(sensor_data.ux_split_s, numel(x_idx), numel(y_idx), []));
    ux_p = gather(reshape(sensor_data.ux_split_p, numel(x_idx), numel(y_idx), []));
    %ux_total = gather(reshape(sensor_data.ux, numel(x_idx), numel(y_idx), []));
else
    ux_s = sensor_data.ux_split_s;
    ux_p = sensor_data.ux_split_p;
    %ux_total = sensor_data.ux;
end

dinf.dx = dx;
dinf.dy = dy;
dinf.dt = kgrid.dt;
dinf.freq=source_freq;
dinf.SAVE_FIGS=0;

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

% Nt = size(ux_s,3);
% Nt_target = min(10/dinf.dt, Nt);
% 
% t_idx = round(linspace(1, Nt, Nt_target));   % uniform sampling indices (length ~1000)
% t_idx = unique(t_idx, 'stable');             % just in case rounding duplicates
% 
% ux_s     = ux_s(:,:,t_idx);
% ux_p     = ux_p(:,:,t_idx);
% %ux_total = ux_total(:,:,t_idx);
% 
% % Update time info
% t_ds = kgrid.t_array(t_idx);
% dinf.dt = mean(diff(t_ds));   % effective dt after downsampling
% Optional: save
filename = ['req_sim_k006_rfp_3DDiff_' num2str(source_freq) 'Hz'];
%save(filename, "ux_total", "ux_p", "ux_s", "dinf", "source_freq", '-v7.3');
save(filename, "ux_s", "dinf", "source_freq", '-v7.3');

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
energy_t = zeros(1, size(ux_s,2));  % depends on sensor geometry
for ii = 1:size(ux_s,2)
    frame = ux_s(:,ii);
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
for ii = 1:10:size(ux_s,3)
    im = real(squeeze(ux_s(:,:,ii)));  % amplitude of shear wave
    imagesc(yy(1:end),xx, im);
    xlabel('x (m)'); ylabel('y (m)');
    axis image;
    clim(1e-5*[-1 1]);
    title(['Frame ' num2str(ii)]);
    grid on;
    colormap('jet');
    colorbar;
    drawnow
    pause(0.1)
end

