function validation = run(configurations)
%RUN Run the directional, partially diffuse, and diffuse field regimes.
%
% validation = kwsim_benchmarks.field_regimes_2d.run()
% validation = kwsim_benchmarks.field_regimes_2d.run(configurations)
%
% configurations must contain directional, partially_diffuse, and diffuse
% configuration structs. Each simulation is independent and monofrequency.
% Failed single-run diagnostics are retained and propagated to the cross-run
% report instead of aborting the remaining benchmarks.

arguments
    configurations struct = struct()
end

if isempty(fieldnames(configurations))
    configurations.directional = kwsim_benchmarks.field_regimes_2d.config("directional");
    configurations.partially_diffuse = ...
        kwsim_benchmarks.field_regimes_2d.config("partially_diffuse");
    configurations.diffuse = kwsim_benchmarks.field_regimes_2d.config("diffuse");
end

required = ["directional", "partially_diffuse", "diffuse"];
for name = required
    if ~isfield(configurations, name)
        error('kwsim:MissingFieldRegimeConfiguration', ...
            'Field-regimes benchmark requires configurations.%s.', name);
    end
end

[results, reports] = ...
    kwsim_benchmarks.support.runRegimeSuite(configurations);

validation = kwsim_benchmarks.field_regimes_2d.evaluate( ...
    results, reports, configurations);

end
