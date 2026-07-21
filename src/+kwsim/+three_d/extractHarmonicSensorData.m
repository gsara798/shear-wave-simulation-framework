function [phasor, metadata] = extractHarmonicSensorData( ...
    sensor_values, t_s, f0_hz, options)
%EXTRACTHARMONICSENSORDATA Extract a complex harmonic field from time data.
%
% Inputs
% ------
% sensor_values:
%   Numeric array [sensor_point, time].
%
% t_s:
%   Time vector in seconds with one sample per column of sensor_values.
%
% f0_hz:
%   Target temporal frequency.
%
% Name-value options
% ------------------
% Method:
%   "least_squares"       Fit cosine, sine, and constant offset.
%   "fourier_projection"  Evaluate the Fourier projection exactly at f0.
%   "fft_bin"             Select the nearest discrete FFT bin.
%
% Window:
%   "none" or "hann". Used by fourier_projection and fft_bin.
%
% RemoveMean:
%   Remove the temporal mean before Fourier-based extraction.
%
% Outputs
% -------
% phasor:
%   Complex array [sensor_point, 1].
%
% metadata:
%   Extraction method, target/evaluated frequency, frequency error,
%   sampling information, and window information.
%
% Phasor convention:
%
%   u(t) = real{U exp(i 2*pi*f*t)}
%
% Thus:
%   abs(U)   is the harmonic amplitude
%   angle(U) is the harmonic phase

arguments
    sensor_values {mustBeNumeric}
    t_s {mustBeNumeric, mustBeVector}
    f0_hz (1,1) double {mustBeFinite, mustBePositive}
    options.Method (1,1) string = "least_squares"
    options.Window (1,1) string = "none"
    options.RemoveMean (1,1) logical = true
end

if ndims(sensor_values) > 2
    error("kwsim:InvalidHarmonicData", ...
        "sensor_values must have shape [sensor_point,time].");
end

t_s = double(t_s(:).');
sample_count = numel(t_s);

if sample_count < 3
    error("kwsim:InvalidHarmonicTime", ...
        "At least three temporal samples are required.");
end

if size(sensor_values, 2) ~= sample_count
    error("kwsim:InvalidHarmonicTime", ...
        "The length of t_s must match the number of signal columns.");
end

if any(~isfinite(t_s)) || any(diff(t_s) <= 0)
    error("kwsim:InvalidHarmonicTime", ...
        "t_s must contain finite, strictly increasing values.");
end

if any(~isfinite(sensor_values), "all")
    error("kwsim:InvalidHarmonicData", ...
        "sensor_values contains NaN or Inf.");
end

dt_s = diff(t_s);
reference_dt_s = mean(dt_s);

relative_dt_variation = ...
    max(abs(dt_s - reference_dt_s)) / reference_dt_s;

if relative_dt_variation > 1e-8
    error("kwsim:NonuniformHarmonicSampling", ...
        "Temporal harmonic extraction currently requires uniform sampling.");
end

sampling_frequency_hz = 1 / reference_dt_s;
nyquist_hz = sampling_frequency_hz / 2;

if f0_hz >= nyquist_hz
    error("kwsim:InvalidHarmonicFrequency", ...
        "f0_hz must be below the Nyquist frequency.");
end

method = lower(options.Method);
window_name = lower(options.Window);

valid_methods = [
    "least_squares"
    "fourier_projection"
    "fft_bin"
];

if ~any(method == valid_methods)
    error("kwsim:InvalidHarmonicMethod", ...
        "Method must be least_squares, fourier_projection, or fft_bin.");
end

valid_windows = [
    "none"
    "hann"
];

if ~any(window_name == valid_windows)
    error("kwsim:InvalidHarmonicWindow", ...
        "Window must be none or hann.");
end

% Use double precision for the temporal reduction. The output is cast back
% to the floating-point class of the input where practical.
working_values = double(sensor_values);

evaluated_frequency_hz = f0_hz;
selected_bin = NaN;
offset = zeros(size(sensor_values, 1), 1);

switch method
    case "least_squares"
        omega0 = 2*pi*f0_hz;

        design_matrix = [
            cos(omega0*t_s(:)), ...
            sin(omega0*t_s(:)), ...
            ones(sample_count, 1)
        ];

        coefficients = design_matrix \ working_values.';

        cosine_coefficient = coefficients(1, :).';
        sine_coefficient = coefficients(2, :).';
        offset = coefficients(3, :).';

        % u(t) = a*cos(wt) + b*sin(wt) + c
        %      = real{(a - i*b)*exp(iwt)} + c
        phasor_double = ...
            cosine_coefficient - 1i*sine_coefficient;

        effective_window = ones(1, sample_count);

    case "fourier_projection"
        effective_window = makeWindow(window_name, sample_count);

        if options.RemoveMean
            weighted_mean = ...
                sum(working_values .* effective_window, 2) ./ ...
                sum(effective_window);

            working_values = working_values - weighted_mean;
            offset = weighted_mean;
        end

        kernel = ...
            effective_window .* exp(-1i*2*pi*f0_hz*t_s);

        phasor_double = ...
            2 * (working_values * kernel.') / sum(effective_window);

    case "fft_bin"
        effective_window = makeWindow(window_name, sample_count);

        if options.RemoveMean
            weighted_mean = ...
                sum(working_values .* effective_window, 2) ./ ...
                sum(effective_window);

            working_values = working_values - weighted_mean;
            offset = weighted_mean;
        end

        windowed_values = working_values .* effective_window;
        spectrum = fft(windowed_values, [], 2);

        frequency_axis_hz = ...
            (0:(sample_count - 1)) * ...
            sampling_frequency_hz / sample_count;

        positive_indices = ...
            1:(floor(sample_count / 2) + 1);

        [~, relative_index] = min(abs( ...
            frequency_axis_hz(positive_indices) - f0_hz));

        selected_bin = positive_indices(relative_index);
        evaluated_frequency_hz = frequency_axis_hz(selected_bin);

        phasor_double = ...
            2 * spectrum(:, selected_bin) / sum(effective_window);
end

if isa(sensor_values, "single")
    phasor = complex( ...
        single(real(phasor_double)), ...
        single(imag(phasor_double)));
else
    phasor = phasor_double;
end

metadata = struct();
metadata.method = method;
metadata.window = window_name;
metadata.remove_mean = options.RemoveMean;
metadata.target_frequency_hz = f0_hz;
metadata.evaluated_frequency_hz = evaluated_frequency_hz;
metadata.frequency_error_hz = evaluated_frequency_hz - f0_hz;
metadata.selected_fft_bin = selected_bin;
metadata.sample_count = sample_count;
metadata.dt_s = reference_dt_s;
metadata.sampling_frequency_hz = sampling_frequency_hz;
metadata.nyquist_frequency_hz = nyquist_hz;
metadata.duration_s = t_s(end) - t_s(1);
metadata.offset = offset;
metadata.phasor_convention = ...
    "u(t) = real{U exp(i 2*pi*f*t)}";

end


function window = makeWindow(window_name, sample_count)

switch window_name
    case "none"
        window = ones(1, sample_count);

    case "hann"
        if sample_count == 1
            window = 1;
        else
            index = 0:(sample_count - 1);
            window = ...
                0.5 - 0.5*cos(2*pi*index/(sample_count - 1));
        end

    otherwise
        error("kwsim:InvalidHarmonicWindow", ...
            "Unsupported temporal window.");
end

end
