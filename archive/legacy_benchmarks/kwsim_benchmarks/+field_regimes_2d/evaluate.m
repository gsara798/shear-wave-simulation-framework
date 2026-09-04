function validation = evaluate(results, reports, configurations)
%EVALUATE Evaluate the point-contact field-regimes benchmark.

arguments
    results struct
    reports struct
    configurations struct
end

validation = kwsim_benchmarks.support.evaluateRegimeSuite( ...
    results, reports, configurations, "field_regimes_2d");

end
