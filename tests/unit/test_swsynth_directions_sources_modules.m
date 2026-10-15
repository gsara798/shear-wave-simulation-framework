function tests = test_swsynth_directions_sources_modules
tests=functiontests(localfunctions);
end

function testDirectionsRetainExistingSampler(testCase)
cfg=fixture();
expected=swsynth.generateDirections(cfg);
actual=swsynth.directions.generate(cfg);
verifyEqual(testCase,actual,expected);
end

function testSourcePlacementPreservesPlanarLegacyDraws(testCase)
cfg=fixture();
[cfg,~]=swsynth.validateConfig(cfg);
directions=swsynth.directions.generate(cfg);
% generateDirections resets the seed, and leaves the stream at its
% established post-direction state.
r=single(cfg.sources.radius_range_m);
rho=rand(1,cfg.directions.count,"single");
radius=((r(2)^3-r(1)^3).*rho+r(1)^3).^(1/3);
expected=double([ ...
    (radius.*single(directions.ux)+single(cfg.domain.Lx_m/2)).', ...
    (radius.*single(directions.uy)+single(cfg.domain.observation_y_m)).', ...
    (radius.*single(directions.uz)+single(cfg.domain.Lz_m/2)).' ]);
directions=swsynth.directions.generate(cfg);
actual=swsynth.sources.prepare(cfg,directions);
verifyEqual(testCase,actual.parent_xyz_m,expected);
verifyEqual(testCase,actual.sampled_radius_m,double(radius(:)));
end

function testExplicitPositionsPreserveRngConsumption(testCase)
cfg=fixture();
cfg.propagation.model="spherical_wave";
cfg.propagation.phase_model="local_k_distance";
cfg.sources.radiation.model="point_force_shear_far_field";
cfg.sources.position_xyz_m=[.01 0 .02; .02 0 .03];
directions=swsynth.directions.generate(cfg);
actual=swsynth.sources.prepare(cfg,directions);
observedNext=rand(1,"single");
directions=swsynth.directions.generate(cfg);
rand(1,cfg.directions.count,"single");
expectedNext=rand(1,"single");
verifyEqual(testCase,actual.parent_xyz_m,double(single(cfg.sources.position_xyz_m)));
verifyEqual(testCase,observedNext,expectedNext);
end

function cfg=fixture()
cfg=swsynth.defaultConfig();
cfg.propagation.model="plane_wave";
cfg.propagation.phase_model="analytical";
cfg.directions.count=2;
cfg.directions.space="three_dimensional";
cfg.directions.sampling_method="explicit";
cfg.directions.explicit_xyz=[1 0 0; 0 0 1];
cfg.sources.aperture.model="point";
end
