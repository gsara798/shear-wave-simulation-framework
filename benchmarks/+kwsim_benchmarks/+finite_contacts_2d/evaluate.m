function validation = evaluate(results, reports, configurations)
%EVALUATE Evaluate the finite-contact field-regimes benchmark.

arguments
    results struct
    reports struct
    configurations struct
end

validation = kwsim_benchmarks.support.evaluateRegimeSuite( ...
    results, reports, configurations, "finite_contacts_2d");

validation.contact_model = "finite_segment";

end
