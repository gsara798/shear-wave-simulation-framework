function validation = runStage3Validation(configurations)
%RUNSTAGE3VALIDATION Run all three Stage 3 field-regime benchmarks.
%
% validation = kwsim.diagnostics.runStage3Validation()
% validation = kwsim.diagnostics.runStage3Validation(configurations)
%
% configurations must contain directional, partially_diffuse, and diffuse
% configuration structs. Each simulation is independent and monofrequency.
% Failed single-run diagnostics are retained and propagated to the cross-run
% report instead of aborting the remaining benchmarks.

arguments
    configurations struct = struct()
end

if isempty(fieldnames(configurations))
    configurations.directional = kwsim.two_d.stage3Config("directional");
    configurations.partially_diffuse = ...
        kwsim.two_d.stage3Config("partially_diffuse");
    configurations.diffuse = kwsim.two_d.stage3Config("diffuse");
end

required = ["directional", "partially_diffuse", "diffuse"];
for name = required
    if ~isfield(configurations, name)
        error('kwsim:MissingStage3Configuration', ...
            'Stage 3 validation requires configurations.%s.', name);
    end
end

results = struct();
reports = struct();
for name = required
    cfg = configurations.(name);
    cfg.output.directory = "";
    cfg.output.save_time_series = false;
    cfg.diagnostics.fail_on_invalid = false;
    [results.(name), reports.(name)] = kwsim.two_d.run(cfg);
end

validation = kwsim.diagnostics.evaluateStage3Results( ...
    results, reports, configurations);

end
