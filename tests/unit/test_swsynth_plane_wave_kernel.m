function tests = test_swsynth_plane_wave_kernel
%TEST_SWSYNTH_PLANE_WAVE_KERNEL Analytic kernel unit/regression checks.
tests = functiontests(localfunctions);
end

function testExactSingleWaveOnGrid(testCase)
x = [-0.002,0,0.002]; z = [0,0.002];
k = 2*pi/0.004;
field = swsynth.propagation.plane_wave.synthesizeHomogeneousFieldXZ( ...
    k*ones(2,3),x,z,single(1),single(0),single(0), ...
    single(0),single(1),false);
expected = complex(zeros(3,2));
for iz=1:2
    expected(:,iz) = exp(1i*k*single(x(:)));
end
verifyEqual(testCase,double(field),double(expected),'AbsTol',1e-4);
end

function testRejectsHeterogeneousK(testCase)
k = [10,10;10,12];
verifyError(testCase,@() ...
    swsynth.propagation.plane_wave.synthesizeHomogeneousFieldXZ( ...
       k,[0,1],[0,1],single(1),single(0),single(0), ...
       single(0),single(1),false), ...
    "swsynth:PlaneWaveRequiresHomogeneousMedium");
end

function testFullRunIsReproducibleAfterExtraction(testCase)
cfg = swsynth.defaultConfig();
cfg.domain.Lx_m=0.006; cfg.domain.Lz_m=0.006;
cfg.domain.dx_m=0.002; cfg.domain.dz_m=0.002;
cfg.propagation.model="plane_wave";
cfg.directions.count=3;
cfg.noise.snr_db=20;
cfg.execution.use_parallel=false;
a=swsynth.run(cfg); b=swsynth.run(cfg);
verifyEqual(testCase,a.wavefield.U_zx,b.wavefield.U_zx);
verifyEqual(testCase,a.wavefield.weights,b.wavefield.weights);
end
