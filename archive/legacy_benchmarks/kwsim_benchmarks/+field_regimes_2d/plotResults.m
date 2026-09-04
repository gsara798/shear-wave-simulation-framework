function [figure_handle, output_file] = plotResults(validation, output_file)
%PLOTRESULTS Plot point-contact source banks, fields, and spectra.

arguments
    validation struct
    output_file {mustBeTextScalar} = ""
end

[figure_handle, output_file] = ...
    kwsim_benchmarks.support.plotRegimeSuite( ...
        validation, output_file);

end
