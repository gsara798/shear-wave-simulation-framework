function fit = fitHarmonic(samples, t_s, f0_hz)
%FITHARMONIC Fit a complex phasor, DC term, and residual to time samples.
%
% samples is [Nsignals,Nt] or a vector. The phasor convention is
%
%   signal(t) = real(phasor * exp(1i*2*pi*f0*t)) + dc.
%
% A least-squares fit is used instead of selecting an FFT bin, so the result
% remains valid when the k-Wave time step does not give an integer number of
% samples per cycle.

arguments
    samples {mustBeNumeric}
    t_s {mustBeNumeric, mustBeVector}
    f0_hz (1,1) double {mustBePositive}
end

if isvector(samples)
    samples = reshape(samples, 1, []);
end
t_s = double(t_s(:));
if size(samples, 2) ~= numel(t_s)
    error('kwsim:HarmonicSizeMismatch', ...
        'samples must have one column for every time value.');
end
if numel(t_s) < 8
    error('kwsim:TooFewHarmonicSamples', ...
        'At least eight time samples are required for harmonic fitting.');
end

omega = 2*pi*f0_hz;
design = [cos(omega*t_s), sin(omega*t_s), ones(size(t_s))];
coefficients = (double(samples) * design) / (design.' * design);

phasor = coefficients(:, 1) - 1i * coefficients(:, 2);
dc = coefficients(:, 3);
reconstruction = real(phasor .* exp(1i*omega*t_s.')) + dc;
residual = double(samples) - reconstruction;

centered = double(samples) - mean(double(samples), 2);
signal_energy = sum(centered.^2, 2);
residual_energy = sum(residual.^2, 2);
fundamental_fraction = 1 - residual_energy ./ max(signal_energy, eps);

fit = struct();
fit.phasor = phasor;
fit.dc = dc;
fit.residual_rms = sqrt(mean(residual.^2, 2));
fit.fundamental_fraction = fundamental_fraction;
fit.convention = "signal(t)=real(phasor*exp(1i*2*pi*f0*t))+dc";

end
