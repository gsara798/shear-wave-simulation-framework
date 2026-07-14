function sweep = run(base_cfg, frequencies_hz, ...
        output_directory, options)
%RUN Execute independent matched attenuated/lossless simulations.
%
% sweep = kwsim_benchmarks.attenuation_power_law_2d.run( ...
%     cfg, frequencies_hz, output_directory)
%
% No field contains more than one frequency. For each f0 this function
% clones the requested configuration, runs a matched lossless reference,
% runs the calibrated Kelvin-Voigt case, evaluates attenuation, and then
% fits the requested power law across the independent results.

arguments
    base_cfg struct = ...
        kwsim_benchmarks.attenuation_power_law_2d.config()
    frequencies_hz (1,:) double = [300, 400, 500]
    output_directory {mustBeTextScalar} = ""
    options.Overwrite (1,1) logical = false
end

if numel(frequencies_hz) < 3 || any(~isfinite(frequencies_hz)) || ...
        any(frequencies_hz <= 0) || numel(unique(frequencies_hz)) ~= ...
        numel(frequencies_hz)
    error('kwsim:InvalidFrequencySweep', ...
        'Use at least three unique, finite, positive frequencies.');
end
if ~base_cfg.attenuation.enabled
    error('kwsim:AttenuationDisabled', ...
        'The benchmark base configuration must enable attenuation.');
end

strict = logical(base_cfg.diagnostics.fail_on_invalid);
frequencies_hz = sort(frequencies_hz);
pair_cells = cell(numel(frequencies_hz), 1);
for index = 1:numel(frequencies_hz)
    f0_hz = frequencies_hz(index);
    attenuated_cfg = base_cfg;
    attenuated_cfg.source.f0_hz = f0_hz;
    attenuated_cfg.scenario = base_cfg.scenario + sprintf('_%g_hz', f0_hz);
    attenuated_cfg.output.directory = "";
    attenuated_cfg.output.save_time_series = false;
    attenuated_cfg.diagnostics.fail_on_invalid = false;

    lossless_cfg = attenuated_cfg;
    lossless_cfg.attenuation.enabled = false;
    lossless_cfg.scenario = attenuated_cfg.scenario + "_lossless";

    [lossless, lossless_report] = kwsim.two_d.run(lossless_cfg);
    [attenuated, attenuated_report] = kwsim.two_d.run(attenuated_cfg);
    pair_cells{index} = ...
        kwsim_benchmarks.attenuation_power_law_2d.evaluatePair( ...
            attenuated, attenuated_report, ...
            lossless, lossless_report);

    if strlength(string(output_directory)) > 0
        frequency_directory = fullfile(string(output_directory), ...
            sprintf('f_%06g_hz', f0_hz));
        kwsim.io.saveRun(lossless, lossless_report, ...
            fullfile(frequency_directory, "lossless"), ...
            Overwrite=options.Overwrite);
        kwsim.io.saveRun(attenuated, attenuated_report, ...
            fullfile(frequency_directory, "attenuated"), ...
            Overwrite=options.Overwrite);
    end
end

pairs = vertcat(pair_cells{:});
sweep = kwsim_benchmarks.attenuation_power_law_2d.evaluate( ...
    pairs, base_cfg);

sweep.reproducibility = struct( ...
    'seed', double(base_cfg.seed), ...
    'frequencies_hz', frequencies_hz(:), ...
    'matched_lossless_reference', true, ...
    'frequency_ordering', "ascending");
if strlength(string(output_directory)) > 0
    kwsim_benchmarks.attenuation_power_law_2d.saveResults( ...
        sweep, output_directory, ...
        Overwrite=options.Overwrite);
end
if strict && ~sweep.valid
    failed_names = strjoin([sweep.checks(~[sweep.checks.pass]).name], ', ');
    error('kwsim:AttenuationPowerLawValidationFailed', ...
        ['Attenuation power-law sweep was saved but failed ', ...
         'diagnostics: %s'], failed_names);
end

end
