function paths = saveFiniteContactValidation(validation, output_directory)
%SAVEFINITECONTACTVALIDATION Save Stage 3B results with unambiguous names.

arguments
    validation struct
    output_directory {mustBeTextScalar}
end

paths = kwsim.diagnostics.saveStage3Validation( ...
    validation, output_directory, 'FilePrefix', "stage3b_finite_contact");

end
