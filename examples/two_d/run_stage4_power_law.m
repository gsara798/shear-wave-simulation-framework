function sweep = run_stage4_power_law(output_directory)
%RUN_STAGE4_POWER_LAW Execute and save the reference Stage 4 frequency sweep.

arguments
    output_directory {mustBeTextScalar} = ...
        fullfile(kwsim.common.projectRoot(), "outputs", "stage4_power_law")
end

cfg = kwsim.two_d.stage4Config();
frequencies_hz = [300, 400, 500];
sweep = kwsim.two_d.runFrequencySweep( ...
    cfg, frequencies_hz, output_directory);
fprintf('%s\n', sweep.summary);

end
