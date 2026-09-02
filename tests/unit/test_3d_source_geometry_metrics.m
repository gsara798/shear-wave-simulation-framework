function tests = test_3d_source_geometry_metrics
%TEST_3D_SOURCE_GEOMETRY_METRICS Test objective angular-coverage metrics.
tests = functiontests(localfunctions);
end

function setupOnce(~)
addpath(fullfile(findRepositoryRoot(), "src"));
end

function testSingleDirectionHasDimensionOne(testCase)
metrics = kwsim.analysis.summarizeSourceGeometry3D( ...
    makeSyntheticConfig([1 0 0], "x_min"));
verifyEqual(testCase, metrics.effective_angular_dimension, 1, "AbsTol", 1e-12);
verifyEqual(testCase, metrics.directional_bias, 1, "AbsTol", 1e-12);
verifyEqual(testCase, metrics.angular_eigenvalues_descending, [1;0;0], "AbsTol", 1e-12);
end

function testOppositeDirectionsRemainLineLike(testCase)
metrics = kwsim.analysis.summarizeSourceGeometry3D( ...
    makeSyntheticConfig([1 0 0; -1 0 0], ["x_min"; "x_max"]));
verifyEqual(testCase, metrics.effective_angular_dimension, 1, "AbsTol", 1e-12);
verifyEqual(testCase, metrics.directional_bias, 0, "AbsTol", 1e-12);
verifyEqual(testCase, metrics.pairwise_direction_angle_max_deg, 180, "AbsTol", 1e-12);
verifyEqual(testCase, metrics.pairwise_axis_angle_max_deg, 0, "AbsTol", 1e-12);
end

function testPlanarDirectionsHaveDimensionTwo(testCase)
directions = [1 0 0; -1 0 0; 0 0 1; 0 0 -1];
faces = ["x_min"; "x_max"; "z_min"; "z_max"];
metrics = kwsim.analysis.summarizeSourceGeometry3D(makeSyntheticConfig(directions, faces));
verifyEqual(testCase, metrics.effective_angular_dimension, 2, "AbsTol", 1e-12);
verifyEqual(testCase, metrics.directional_bias, 0, "AbsTol", 1e-12);
verifyEqual(testCase, metrics.angular_eigenvalues_descending, [0.5;0.5;0], "AbsTol", 1e-12);
verifyEqual(testCase, metrics.weighted_mean_plane_deviation_deg, 0, "AbsTol", 1e-12);
end

function testIsotropicAxesHaveDimensionThree(testCase)
directions = [1 0 0; -1 0 0; 0 1 0; 0 -1 0; 0 0 1; 0 0 -1];
faces = ["x_min"; "x_max"; "y_min"; "y_max"; "z_min"; "z_max"];
metrics = kwsim.analysis.summarizeSourceGeometry3D(makeSyntheticConfig(directions, faces));
verifyEqual(testCase, metrics.effective_angular_dimension, 3, "AbsTol", 1e-12);
verifyEqual(testCase, metrics.directional_bias, 0, "AbsTol", 1e-12);
verifyEqual(testCase, metrics.angular_eigenvalues_descending, ones(3,1)/3, "AbsTol", 1e-12);
verifyEqual(testCase, metrics.unique_face_count, 6);
end

function testCanonicalGeometriesResolveMetrics(testCase)
root = findRepositoryRoot();
names = ["homogeneous_directional_cli.json"; ...
    "homogeneous_partial_diffuse8.json"; ...
    "homogeneous_partial_3d_n8_p2.json"];
resolved = cell(3,1);
for idx = 1:3
    file = fullfile(root, "configs", "kwsim", "three_d", names(idx));
    [requested, ~] = kwsim.io.loadConfigJson(file);
    requested.grid.minimum_shear_ppw = 1;
    [resolved{idx}, ~] = kwsim.three_d.validateConfig(requested);
end

directional = resolved{1}.source.geometry_metrics;
single_face_n8 = resolved{2}.source.geometry_metrics;
multiface_n8_p2 = resolved{3}.source.geometry_metrics;
verifyEqual(testCase, directional.source_count, 1);
verifyEqual(testCase, directional.unique_face_count, 1);
verifyEqual(testCase, directional.effective_angular_dimension, 1, "AbsTol", 1e-12);
verifyEqual(testCase, single_face_n8.source_count, 8);
verifyEqual(testCase, single_face_n8.unique_face_count, 1);
verifyGreaterThanOrEqual(testCase, single_face_n8.effective_angular_dimension, 1);
verifyLessThanOrEqual(testCase, single_face_n8.effective_angular_dimension, 3);
verifyEqual(testCase, multiface_n8_p2.source_count, 8);
verifyEqual(testCase, multiface_n8_p2.unique_face_count, 6);
verifyEqual(testCase, multiface_n8_p2.in_plane_contact_count, 2);
verifyEqual(testCase, multiface_n8_p2.out_of_plane_contact_count, 6);
end

function cfg = makeSyntheticConfig(directions_xyz, faces)
directions_xyz = double(directions_xyz);
n = size(directions_xyz,1);
faces = string(faces(:));
if isscalar(faces) && n > 1
    faces = repmat(faces,n,1);
end
cfg.grid = struct("Nx",20,"Ny",20,"Nz",20,"dx_m",0.5e-3,"dy_m",0.5e-3,"dz_m",0.5e-3);
cfg.sensor = struct("acquisition_y_index_full",10);
cfg.source = struct("layout","vibrator_bank","side","multiface", ...
    "boundary_margin_m",2e-3,"acquisition_plane_y_index_full",10);
template = struct("face","","center_index_xyz",[NaN NaN NaN], ...
    "nominal_propagation_xyz",[NaN NaN NaN],"node_linear_indices",[], ...
    "velocity_amplitude_m_s",1,"intersects_acquisition_plane",true);
vibrators = repmat(template,n,1);
for idx = 1:n
    direction = directions_xyz(idx,:) / norm(directions_xyz(idx,:));
    center = [2+idx,10,10];
    vibrators(idx).face = faces(idx);
    vibrators(idx).center_index_xyz = center;
    vibrators(idx).nominal_propagation_xyz = direction;
    vibrators(idx).node_linear_indices = sub2ind([20 20 20],center(1),center(2),center(3));
end
cfg.source.vibrators = vibrators;
end

function root = findRepositoryRoot()
root = fileparts(fileparts(fileparts(mfilename("fullpath"))));
end
