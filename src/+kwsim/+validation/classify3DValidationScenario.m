function validation_kind = classify3DValidationScenario(scenario)
%CLASSIFY3DVALIDATIONSCENARIO Select the physical 3D validation contract.

arguments
    scenario {mustBeTextScalar}
end

scenario = lower(string(scenario));

if startsWith(scenario, "homogeneous_generated_angular_") || ...
        scenario == "homogeneous_partial_diffuse8_3d" || ...
        scenario == "homogeneous_partial_3d_n8_p2"
    validation_kind = "multi_source_homogeneous";
elseif startsWith(scenario, "heterogeneous_")
    validation_kind = "heterogeneous_harmonic";
elseif scenario == "homogeneous_directional_3d"
    validation_kind = "directional_homogeneous";
else
    validation_kind = "unsupported";
end

end
