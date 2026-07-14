function cfg = config()
%CONFIG Reference directional homogeneous 2D benchmark configuration.
%
% cfg = kwsim_benchmarks.directional_homogeneous_2d.config()
%
% The benchmark uses one finite prescribed-velocity contact on the left
% boundary of a homogeneous, lossless elastic medium.

cfg = kwsim.two_d.defaultConfig();

cfg.scenario = "directional_homogeneous_2d";

cfg = kwsim.sources.configureSingleContact( ...
    cfg, ...
    Side="left", ...
    VelocityAmplitudeMPerS=1e-6, ...
    PhaseRad=0);

% Finite uniformly driven contact on the 0.5 mm reference grid.
% Non-adjacent Dirichlet nodes avoid the validated elastic-solver
% instability associated with adjacent constrained nodes.
cfg = kwsim.sources.configureFiniteContact( ...
    cfg, ...
    ContactRadiusM=1e-3, ...
    NodeSpacingPoints=2, ...
    Profile="uniform");

end
