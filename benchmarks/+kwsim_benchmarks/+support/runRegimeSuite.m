function [results, reports] = runRegimeSuite(configurations)
%RUNREGIMESUITE Run directional, partially diffuse, and diffuse cases.
%
% This internal benchmark helper executes three independently configured
% monofrequency simulations. Benchmark packages remain responsible for
% constructing configurations and evaluating acceptance criteria.

arguments
    configurations struct
end

names = ["directional", "partially_diffuse", "diffuse"];

results = struct();
reports = struct();

for name = names
    cfg = configurations.(name);
    cfg.output.directory = "";
    cfg.output.save_time_series = false;
    cfg.diagnostics.fail_on_invalid = false;

    [results.(name), reports.(name)] = kwsim.two_d.run(cfg);
end

end
