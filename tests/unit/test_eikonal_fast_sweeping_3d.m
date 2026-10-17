function tests = test_eikonal_fast_sweeping_3d
%TEST_EIKONAL_FAST_SWEEPING_3D Unit tests for the 3D fast-sweeping kernel.

tests = functiontests(localfunctions);
end

function setupOnce(~)
root = fileparts(fileparts(fileparts(mfilename("fullpath"))));
addpath(fullfile(root, "src"));
end

function testHomogeneousPlaneBoundaryMatchesExactTravelTime(testCase)
Nz = 5; Ny = 4; Nx = 6;
dx = 1e-3; dy = 1.5e-3; dz = 2e-3;
cs = 2.0;
slowness = (1/cs) * ones(Nz,Ny,Nx);
initial = Inf(Nz,Ny,Nx);
fixed = false(Nz,Ny,Nx);
fixed(:,:,1) = true;
initial(:,:,1) = 0;
[T, diag] = swsynth.numerics.eikonal.solveFastSweeping3D( ...
    slowness, dx, dy, dz, initial, fixed);
x = reshape((0:Nx-1)*dx/cs, 1,1,Nx);
expected = repmat(x, Nz,Ny,1);
verifyEqual(testCase, T, expected, AbsTol=5e-13);
verifyTrue(testCase, diag.converged);
verifyEqual(testCase, diag.method, "fast_sweeping_3d");
end

function testFasterRegionDoesNotIncreaseTravelTime(testCase)
Nz = 7; Ny = 7; Nx = 9;
d = 1e-3;
base = 0.5 * ones(Nz,Ny,Nx);
initial = Inf(Nz,Ny,Nx);
fixed = false(Nz,Ny,Nx);
fixed(:,:,1) = true;
initial(:,:,1) = 0;
[Tbase, ~] = swsynth.numerics.eikonal.solveFastSweeping3D( ...
    base,d,d,d,initial,fixed);
fast = base;
fast(3:5,3:5,4:7) = 1/3;
[Tfast, ~] = swsynth.numerics.eikonal.solveFastSweeping3D( ...
    fast,d,d,d,initial,fixed);
verifyLessThanOrEqual(testCase, Tfast, Tbase + 1e-12);
verifyLessThan(testCase, Tfast(4,4,end), Tbase(4,4,end));
end

function testRequiresBoundaryCondition(testCase)
slowness = ones(3,3,3);
initial = Inf(3,3,3);
fixed = false(3,3,3);
verifyError(testCase, @() swsynth.numerics.eikonal.solveFastSweeping3D( ...
    slowness,1,1,1,initial,fixed), ...
    "swsynth:Eikonal3DMissingBoundaryCondition");
end

function testSecondOrderPlaneAndDiagnostics(testCase)
Nz=5;Ny=5;Nx=12;
dx=.001;cs=2;
slowness=ones(Nz,Ny,Nx)/cs;
initial=inf(Nz,Ny,Nx);fixed=false(Nz,Ny,Nx);
fixed(:,:,1)=true;initial(:,:,1)=0;
[T,d]=swsynth.numerics.eikonal.solveFastSweeping3D( ...
    slowness,dx,dx,dx,initial,fixed, ...
    struct("SpatialOrder",2,"MaximumIterations",200));
[~,~,X]=ndgrid(1:Nz,1:Ny,0:Nx-1);
expected=X*dx/cs;
verifyTrue(testCase,d.converged);
verifyEqual(testCase,d.spatial_order,2);
verifyEqual(testCase,T,expected,"AbsTol",1e-10);
end

function testSecondOrderPointSourceFinite(testCase)
n=13;h=.001;
slowness=ones(n,n,n)/2;
fixed=false(n,n,n);fixed(7,7,7)=true;
initial=inf(n,n,n);initial(7,7,7)=0;
[T,d]=swsynth.numerics.eikonal.solveFastSweeping3D( ...
    slowness,h,h,h,initial,fixed,struct("SpatialOrder",2));
verifyTrue(testCase,d.converged);
verifyTrue(testCase,all(isfinite(T(:))));
verifyEqual(testCase,T(7,7,7),0);
verifyGreaterThan(testCase,T(7,7,10),0);
end

function testDefaultIsSecondOrderAndExplicitFirstOrderPreserved(testCase)
n=9;h=.001;
slow=ones(n,n,n)/2;
initial=inf(n,n,n);fixed=false(n,n,n);
fixed(:,:,1)=true;initial(:,:,1)=0;
[Tdefault,ddefault]=swsynth.numerics.eikonal.solveFastSweeping3D( ...
    slow,h,h,h,initial,fixed);
[Tsecond,dsecond]=swsynth.numerics.eikonal.solveFastSweeping3D( ...
    slow,h,h,h,initial,fixed,struct("SpatialOrder",2));
[Tfirst,dfirst]=swsynth.numerics.eikonal.solveFastSweeping3D( ...
    slow,h,h,h,initial,fixed,struct("SpatialOrder",1));
verifyEqual(testCase,ddefault.spatial_order,2);
verifyEqual(testCase,dsecond.spatial_order,2);
verifyEqual(testCase,dfirst.spatial_order,1);
verifyEqual(testCase,Tdefault,Tsecond,"AbsTol",1e-12);
verifyTrue(testCase,all(isfinite(Tfirst(:))));
end
