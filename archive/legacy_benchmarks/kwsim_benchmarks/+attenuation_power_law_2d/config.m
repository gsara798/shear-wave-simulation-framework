function cfg = config(options)
%CONFIG Reference homogeneous power-law attenuation benchmark.
%
% cfg = kwsim_benchmarks.attenuation_power_law_2d.config()
%
% cfg = kwsim_benchmarks.attenuation_power_law_2d.config( ...
%     ShearAlphaRefDbCm=1.5, ...
%     ShearReferenceFrequencyHz=500, ...
%     ShearPowerY=1.1, ...
%     Seed=1001)
%
% Attenuation coefficients are amplitude coefficients in dB/cm.
% Frequencies are in Hz. Each requested frequency is simulated
% independently and paired with a matched lossless reference.

arguments
    options.ShearAlphaRefDbCm (1,1) double ...
        {mustBeNonnegative, mustBeFinite} = 1.0

    options.ShearReferenceFrequencyHz (1,1) double ...
        {mustBePositive, mustBeFinite} = 500

    options.ShearPowerY (1,1) double ...
        {mustBeNonnegative, mustBeFinite} = 1.2

    options.CompressionAlphaRefDbCm (1,1) double ...
        {mustBeNonnegative, mustBeFinite} = 0.1

    options.CompressionReferenceFrequencyHz (1,1) double ...
        {mustBePositive, mustBeFinite} = 500

    options.CompressionPowerY (1,1) double ...
        {mustBeNonnegative, mustBeFinite} = 1.2

    options.Seed (1,1) double ...
        {mustBeInteger, mustBeNonnegative, mustBeFinite} = 1001
end

cfg = kwsim.two_d.defaultConfig();

cfg.scenario = "attenuation_power_law_homogeneous";
cfg.seed = options.Seed;

% Compact homogeneous propagation domain.
cfg.grid.Nx = 64;
cfg.grid.Nz = 48;

% Stable transverse point-contact excitation.
cfg.source.layout = "single_contact";
cfg.source.regime = "single";
cfg.source.contact_model = "point";
cfg.source.contact_sampling = "point";

% Explicit Kelvin-Voigt stability setting.
cfg.grid.cfl = 0.025;

cfg.attenuation.enabled = true;
cfg.attenuation.materials = ...
    kwsim.materials.makeAttenuationMaterial( ...
        1, ...
        ShearAlphaRefDbCm=options.ShearAlphaRefDbCm, ...
        ShearReferenceFrequencyHz= ...
            options.ShearReferenceFrequencyHz, ...
        ShearPowerY=options.ShearPowerY, ...
        CompressionAlphaRefDbCm= ...
            options.CompressionAlphaRefDbCm, ...
        CompressionReferenceFrequencyHz= ...
            options.CompressionReferenceFrequencyHz, ...
        CompressionPowerY=options.CompressionPowerY);

% Benchmark-owned acceptance thresholds.
cfg.diagnostics.maximum_attenuation_relative_error = 0.05;
cfg.diagnostics.maximum_power_law_exponent_absolute_error = 0.05;
cfg.diagnostics.maximum_attenuated_speed_relative_difference = 0.02;
cfg.diagnostics.minimum_attenuation_fit_r_squared = 0.98;
cfg.diagnostics.minimum_attenuation_fit_points = 8;
cfg.diagnostics.attenuation_fit_relative_amplitude_floor = 0.20;
cfg.diagnostics.attenuation_fit_half_width_m = 1e-3;
cfg.diagnostics.attenuation_fit_downstream_wavelengths = 1.5;

end
