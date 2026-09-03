function cfg = config()
%CONFIG circular-inclusion benchmark reference with one central circular inclusion.
%
% The background has cs=2 m/s and rho=1000 kg/m^3. The 8 mm-radius
% inclusion has cs=3 m/s and rho=1020 kg/m^3. In reduced-cp mode, validation
% resolves one constant cp=10*max(cs)=30 m/s across both materials.

cfg = kwsim.two_d.defaultConfig();
cfg.scenario = "circular_inclusion";

% Use an odd axial grid so the source, inclusion, and two exterior PMLs share
% an exact grid-node symmetry plane. Nx remains 96; the homogeneous reference retains its
% original 96-by-96 reference grid.
cfg.grid.Nz = 95;

% Choose the grid node nearest the physical domain centre. Aligning the
% inclusion with the source depth makes the expected axial symmetry exactly
% testable on the discrete grid.
center_x_m = 0.5 * (cfg.grid.Nx - 1) * cfg.grid.dx_m;
center_z_m = 0.5 * (cfg.grid.Nz - 1) * cfg.grid.dz_m;
cfg.geometry.objects = kwsim.geometry.two_d.makeCircleObject( ...
    [center_x_m, center_z_m], 8e-3, 2, 3.0, 1020, "central_inclusion");

end
