function tests = test_extract_3d_harmonic_sensor_data
%TEST_EXTRACT_3D_HARMONIC_SENSOR_DATA Verify temporal harmonic extraction.

tests = functiontests(localfunctions);

end


function testLeastSquaresRecoversAmplitudePhaseAndOffset(testCase)

fs_hz = 8000;
f0_hz = 500;
t_s = (0:159) / fs_hz;

amplitude = [1.2; 0.7; 2.1];
phase = [0.3; -1.1; 2.0];
offset = [0.4; -0.2; 1.3];

expected_phasor = amplitude .* exp(1i*phase);

sensor_values = ...
    real(expected_phasor .* exp(1i*2*pi*f0_hz*t_s)) + ...
    offset;

[actual, metadata] = ...
    kwsim.three_d.extractHarmonicSensorData( ...
        sensor_values, t_s, f0_hz, ...
        Method="least_squares");

verifyEqual(testCase, actual, expected_phasor, ...
    "AbsTol", 1e-11);

verifyEqual(testCase, metadata.offset, offset, ...
    "AbsTol", 1e-11);

verifyEqual(testCase, ...
    metadata.evaluated_frequency_hz, f0_hz);

end


function testFourierProjectionRecoversIntegerCycleSignal(testCase)

fs_hz = 8000;
f0_hz = 500;
t_s = (0:159) / fs_hz;

expected_phasor = [
    1.0*exp(1i*0.2)
    0.6*exp(-1i*0.8)
    1.8*exp(1i*1.4)
];

sensor_values = ...
    real(expected_phasor .* exp(1i*2*pi*f0_hz*t_s));

actual = kwsim.three_d.extractHarmonicSensorData( ...
    sensor_values, t_s, f0_hz, ...
    Method="fourier_projection", ...
    Window="none");

verifyEqual(testCase, actual, expected_phasor, ...
    "AbsTol", 1e-11);

end


function testLeastSquaresHandlesNonIntegerCycles(testCase)

fs_hz = 7500;
f0_hz = 470;
t_s = (0:136) / fs_hz;

expected_phasor = [
    1.4*exp(1i*0.45)
    0.9*exp(-1i*1.2)
];

sensor_values = ...
    real(expected_phasor .* exp(1i*2*pi*f0_hz*t_s)) + ...
    [0.7; -0.3];

actual = kwsim.three_d.extractHarmonicSensorData( ...
    sensor_values, t_s, f0_hz, ...
    Method="least_squares");

verifyEqual(testCase, actual, expected_phasor, ...
    "AbsTol", 1e-11);

end


function testFftBinReportsSelectedFrequency(testCase)

fs_hz = 8000;
sample_count = 128;
t_s = (0:(sample_count - 1)) / fs_hz;

target_frequency_hz = 530;

signal = cos(2*pi*target_frequency_hz*t_s);

[phasor, metadata] = ...
    kwsim.three_d.extractHarmonicSensorData( ...
        signal, t_s, target_frequency_hz, ...
        Method="fft_bin", ...
        Window="hann");

frequency_resolution_hz = fs_hz / sample_count;

verifySize(testCase, phasor, [1, 1]);

verifyLessThanOrEqual(testCase, ...
    abs(metadata.frequency_error_hz), ...
    frequency_resolution_hz / 2 + eps);

verifyTrue(testCase, ...
    isfinite(metadata.selected_fft_bin));

end


function testPreservesSinglePrecision(testCase)

fs_hz = 8000;
f0_hz = 500;
t_s = (0:79) / fs_hz;

sensor_values = single(cos(2*pi*f0_hz*t_s));

actual = kwsim.three_d.extractHarmonicSensorData( ...
    sensor_values, t_s, f0_hz, ...
    Method="least_squares");

verifyClass(testCase, actual, "single");
verifyTrue(testCase, ~isreal(actual));

end


function testRejectsTimeLengthMismatch(testCase)

sensor_values = zeros(4, 20);
t_s = 0:18;

verifyError(testCase, ...
    @() kwsim.three_d.extractHarmonicSensorData( ...
        sensor_values, t_s, 0.1), ...
    "kwsim:InvalidHarmonicTime");

end


function testRejectsFrequencyAboveNyquist(testCase)

t_s = (0:99) / 1000;
sensor_values = zeros(2, numel(t_s));

verifyError(testCase, ...
    @() kwsim.three_d.extractHarmonicSensorData( ...
        sensor_values, t_s, 600), ...
    "kwsim:InvalidHarmonicFrequency");

end


function testRejectsInvalidMethod(testCase)

t_s = (0:99) / 1000;
sensor_values = zeros(2, numel(t_s));

verifyError(testCase, ...
    @() kwsim.three_d.extractHarmonicSensorData( ...
        sensor_values, t_s, 100, ...
        Method="magic"), ...
    "kwsim:InvalidHarmonicMethod");

end
