function tests=test_3d_validation_scenario_dispatch
tests=functiontests(localfunctions);
end

function testPreservesExistingScenarioFamilies(testCase)
verifyEqual(testCase,classify("homogeneous_generated_angular_n16"), ...
    "multi_source_homogeneous");
verifyEqual(testCase,classify("homogeneous_partial_3d_n8_p2"), ...
    "multi_source_homogeneous");
verifyEqual(testCase,classify("homogeneous_directional_3d"), ...
    "directional_homogeneous");
verifyEqual(testCase,classify("heterogeneous_large_sphere"), ...
    "heterogeneous_harmonic");
end

function testRegistersAllV2ExternalScenarios(testCase)
verifyEqual(testCase,classify("reqml_q0_v2_external_kwave_homogeneous"), ...
    "multi_source_homogeneous");
verifyEqual(testCase,classify("reqml_q0_v2_external_kwave_sphere"), ...
    "heterogeneous_harmonic");
verifyEqual(testCase,classify("reqml_q0_v2_external_kwave_bilayer"), ...
    "heterogeneous_harmonic");
end

function testUnknownScenarioRemainsRejected(testCase)
verifyEqual(testCase,classify("unregistered_scientific_case"),"unsupported");
end

function value=classify(scenario)
value=kwsim.validation.classify3DValidationScenario(scenario);
end
