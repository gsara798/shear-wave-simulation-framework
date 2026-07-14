function tests = test_harmonic_fit
%TEST_HARMONIC_FIT Verify the explicit complex-phasor convention.
tests = functiontests(localfunctions);
end

function setupOnce(~)
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(root, 'src'));
end

function testRecoversAmplitudePhaseAndDc(testCase)
f0 = 517;
t = (0:1/17321:0.0317);
expected = 2.3e-6 * exp(1i*0.73);
dc = -0.4e-6;
signal = real(expected * exp(1i*2*pi*f0*t)) + dc;
fit = kwsim.diagnostics.fitHarmonic(signal, t, f0);
verifyEqual(testCase, fit.phasor, expected, 'RelTol', 1e-11);
verifyEqual(testCase, fit.dc, dc, 'AbsTol', 1e-16);
verifyGreaterThan(testCase, fit.fundamental_fraction, 1 - 1e-12);
end

function testRejectsMismatchedTimeVector(testCase)
verifyError(testCase, @() kwsim.diagnostics.fitHarmonic(ones(2, 10), 1:9, 1), ...
    'kwsim:HarmonicSizeMismatch');
end
