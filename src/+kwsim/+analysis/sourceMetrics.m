function metrics = sourceMetrics(source_metadata, analysis_start_s)
%SOURCEMETRICS Quantify steady-state spectral purity of the imposed source.
%
% Only samples at or after analysis_start_s are used. This deliberately
% excludes the physical ramp, whose purpose is to suppress startup energy
% rather than to be monochromatic itself.

arguments
    source_metadata struct
    analysis_start_s (1,1) double {mustBeNonnegative}
end

index = source_metadata.t_s >= analysis_start_s;
if nnz(index) < 8
    error('kwsim:ShortSourceAnalysisWindow', ...
        'The source analysis window contains fewer than eight samples.');
end

t_s = source_metadata.t_s(index);
if isfield(source_metadata, 'scalar_waveforms_m_s')
    waveforms = double(source_metadata.scalar_waveforms_m_s(:, index));
else
    waveforms = source_metadata.waveform_m_s(index);
end
fit = kwsim.signal.fitHarmonic(waveforms, t_s, source_metadata.f0_hz);

% The worst source is the conservative pass/fail statistic. Per-vibrator
% values remain available to reveal a malformed member hidden by averaging.
fundamental_fraction_per_vibrator = reshape(fit.fundamental_fraction, [], 1);
[fundamental_fraction, representative_index] = min( ...
    fundamental_fraction_per_vibrator);
waveform = waveforms(representative_index, :);

% A Hann-windowed spectrum is stored for visualization only. Pass/fail is
% based on the least-squares residual above and is not subject to FFT-bin
% leakage.
n = numel(waveform);
window = 0.5 - 0.5*cos(2*pi*(0:(n - 1))/max(n - 1, 1));
spectrum = abs(fft((waveform - mean(waveform)) .* window));
positive = 1:(floor(n/2) + 1);
dt = mean(diff(t_s));

metrics = struct();
metrics.fundamental_fraction = fundamental_fraction;
metrics.fundamental_fraction_per_vibrator = ...
    fundamental_fraction_per_vibrator;
metrics.fitted_amplitude_m_s = reshape(abs(fit.phasor), [], 1);
metrics.fitted_phase_rad = reshape(angle(fit.phasor), [], 1);
metrics.residual_rms_m_s = reshape(fit.residual_rms, [], 1);
metrics.frequency_hz = (positive - 1) / (n * dt);
metrics.normalized_spectrum = spectrum(positive) / max(spectrum(positive));
metrics.analysis_window_s = [t_s(1), t_s(end)];

end
