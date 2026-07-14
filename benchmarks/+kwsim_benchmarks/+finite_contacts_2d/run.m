function validation = run(configurations)
%RUN Execute and evaluate the three finite-contact field regimes.
%
% validation = kwsim_benchmarks.finite_contacts_2d.run()
% validation = kwsim_benchmarks.finite_contacts_2d.run(configurations)
%
% configurations must contain directional, partially_diffuse, and diffuse
% configuration structs. When omitted, the full reference configurations
% are used.

arguments
    configurations struct = struct()
end

if isempty(fieldnames(configurations))
    configurations.directional = ...
        kwsim_benchmarks.finite_contacts_2d.config("directional");

    configurations.partially_diffuse = ...
        kwsim_benchmarks.finite_contacts_2d.config("partially_diffuse");

    configurations.diffuse = ...
        kwsim_benchmarks.finite_contacts_2d.config("diffuse");
end

required = ["directional", "partially_diffuse", "diffuse"];

for name = required
    if ~isfield(configurations, name)
        error( ...
            'kwsim:MissingFiniteContactConfiguration', ...
            'Finite-contact benchmark requires configurations.%s.', ...
            name);
    end
end

[results, reports] = ...
    kwsim_benchmarks.support.runRegimeSuite(configurations);

validation = kwsim_benchmarks.finite_contacts_2d.evaluate( ...
    results, reports, configurations);

end
