function tests = test_stage3b_run
%TEST_STAGE3B_RUN Integration test for compact finite-contact field regimes.
tests = functiontests(localfunctions);
end

function setupOnce(~)
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(root, 'src'));
end

function testCompactFiniteContactSuitePasses(testCase)
configs = struct();
configs.directional = ...
    kwsim.diagnostics.compactFiniteContactConfig("directional");
configs.partially_diffuse = ...
    kwsim.diagnostics.compactFiniteContactConfig("partially_diffuse");
configs.diffuse = kwsim.diagnostics.compactFiniteContactConfig("diffuse");
validation = kwsim.diagnostics.runStage3Validation(configs);
verifyTrue(testCase, validation.valid, validation.summary);
verifyEqual(testCase, validation.metrics.solver_channel_count, [12, 24, 24]);
verifyEqual(testCase, validation.metrics.contact_span_m, 4e-3*ones(1,3), ...
    'AbsTol', 1e-14);
end
