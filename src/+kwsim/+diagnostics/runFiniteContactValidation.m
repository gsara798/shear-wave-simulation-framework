function validation = runFiniteContactValidation()
%RUNFINITECONTACTVALIDATION Run the three Stage 3B finite-contact regimes.
%
% The directional, partially diffuse, and diffuse simulations are fully
% independent. Every physical vibrator is a raised-cosine perimeter segment
% with the validated node spacing from finiteContactConfig.

configurations = struct();
configurations.directional = ...
    kwsim.two_d.finiteContactConfig("directional");
configurations.partially_diffuse = ...
    kwsim.two_d.finiteContactConfig("partially_diffuse");
configurations.diffuse = kwsim.two_d.finiteContactConfig("diffuse");
validation = kwsim.diagnostics.runStage3Validation(configurations);
validation.substage = "3B";
validation.contact_model = "finite_segment";

end
