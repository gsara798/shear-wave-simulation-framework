function tests = test_swsynth_volumetric_eikonal_physics
%TEST_SWSYNTH_VOLUMETRIC_EIKONAL_PHYSICS Physical validation for 3D Eikonal.
%
% These tests go beyond contract/shape checks. They verify that an oblique
% plane wave crossing a planar isotropic interface conserves tangential
% slowness and refracts according to Snell's law.

tests = functiontests(localfunctions);

end

function testObliquePlanarInterfaceFollowsSnellLaw(testCase)

c1 = 2.0;
c2 = 2.5;
theta1Deg = 20;
direction = [cosd(theta1Deg), sind(theta1Deg), 0];

x = 0:5e-4:0.012;
y = 0:5e-4:0.012;
z = 0:1e-3:0.004;
dx = x(2)-x(1);
dy = y(2)-y(1);

[~, ~, X] = ndgrid(z, y, x);
interfaceX = 0.006;
cs = c1 * ones(numel(z), numel(y), numel(x));
cs(X >= interfaceX) = c2;

[tau, diagnostics] = ...
    swsynth.propagation.volumetric3d.computeDirectionalTravelTime( ...
        cs, x, y, z, direction, c1, ...
        struct("MaximumIterations", 250, "ToleranceS", 1e-11));

verifyTrue(testCase, diagnostics.solver.converged);
verifyEqual(testCase, diagnostics.boundary.incident_face, "x_min");

% Sample the transmitted region away from the interface and all boundaries.
iz = ceil(numel(z)/2);
ixCandidates = find(x >= 0.008 & x <= 0.010);
iyCandidates = find(y >= 0.003 & y <= 0.009);

px = zeros(0,1);
py = zeros(0,1);
for ix = ixCandidates
    if ix <= 1 || ix >= numel(x), continue; end
    for iy = iyCandidates
        if iy <= 1 || iy >= numel(y), continue; end
        px(end+1,1) = (tau(iz,iy,ix+1) - tau(iz,iy,ix-1)) / (2*dx); %#ok<AGROW>
        py(end+1,1) = (tau(iz,iy+1,ix) - tau(iz,iy-1,ix)) / (2*dy); %#ok<AGROW>
    end
end

verifyNotEmpty(testCase, px);

pxMeasured = median(px);
pyMeasured = median(py);
theta2MeasuredDeg = atan2d(abs(pyMeasured), abs(pxMeasured));

% For an isotropic interface with normal +x:
%   sin(theta1)/c1 = sin(theta2)/c2.
expectedTangentialSlowness = sind(theta1Deg) / c1;
theta2ExpectedDeg = asind((c2/c1) * sind(theta1Deg));

verifyEqual(testCase, pyMeasured, expectedTangentialSlowness, RelTol=0.12);
verifyEqual(testCase, theta2MeasuredDeg, theta2ExpectedDeg, AbsTol=4.0);

% Local Eikonal magnitude in material 2 should remain approximately 1/c2.
slownessMagnitude = hypot(pxMeasured, pyMeasured);
verifyEqual(testCase, slownessMagnitude, 1/c2, RelTol=0.12);

end

function testNormalIncidenceChangesNormalSlownessOnly(testCase)

c1 = 2.0;
c2 = 3.0;
x = 0:5e-4:0.010;
y = 0:1e-3:0.004;
z = 0:1e-3:0.004;

[~, ~, X] = ndgrid(z, y, x);
cs = c1 * ones(numel(z), numel(y), numel(x));
cs(X >= 0.005) = c2;

[tau, diagnostics] = ...
    swsynth.propagation.volumetric3d.computeDirectionalTravelTime( ...
        cs, x, y, z, [1 0 0], c1, ...
        struct("MaximumIterations", 200, "ToleranceS", 1e-11));

verifyTrue(testCase, diagnostics.solver.converged);
verifyEqual(testCase, diagnostics.boundary.incident_face, "x_min");

iz = ceil(numel(z)/2);
iy = ceil(numel(y)/2);
ix1 = find(x >= 0.002 & x <= 0.004, 1, "first");
ix2 = find(x >= 0.007 & x <= 0.009, 1, "first");

p1 = (tau(iz,iy,ix1+1)-tau(iz,iy,ix1-1)) / (2*(x(2)-x(1)));
p2 = (tau(iz,iy,ix2+1)-tau(iz,iy,ix2-1)) / (2*(x(2)-x(1)));

verifyEqual(testCase, p1, 1/c1, RelTol=0.05);
verifyEqual(testCase, p2, 1/c2, RelTol=0.05);

% At normal incidence the solution should be invariant along y and z in
% the central interior, apart from numerical roundoff.
verifyEqual(testCase, tau(iz,iy+1,ix2)-tau(iz,iy-1,ix2), 0, AbsTol=1e-10);
verifyEqual(testCase, tau(iz+1,iy,ix2)-tau(iz-1,iy,ix2), 0, AbsTol=1e-10);

end

function testBoundaryUsesSinglePrincipalIncidentFace(testCase)

x = 0:1e-3:0.004;
y = 0:1e-3:0.003;
z = 0:1e-3:0.002;
direction = [0.9 0.4 0.1];

[initialTime, fixedMask, diagnostics] = ...
    swsynth.propagation.volumetric3d.buildIncidentBoundaryCondition( ...
        x, y, z, direction, 2.0);

verifyEqual(testCase, diagnostics.incident_face, "x_min");
verifyEqual(testCase, nnz(fixedMask), numel(y)*numel(z));
verifyTrue(testCase, all(fixedMask(:,:,1), "all"));
verifyFalse(testCase, any(fixedMask(:,:,2:end), "all"));
verifyTrue(testCase, all(isfinite(initialTime(fixedMask))));
verifyTrue(testCase, all(isinf(initialTime(~fixedMask))));

end
