function alpha_db_cm = evaluatePowerLawAttenuation( ...
        alpha_ref_db_cm, f_ref_hz, power_y, f0_hz)
%EVALUATEPOWERLAWATTENUATION Evaluate a target attenuation law at one frequency.
%
% alpha_db_cm = kwsim.materials.evaluatePowerLawAttenuation( ...
%     alpha_ref_db_cm, f_ref_hz, power_y, f0_hz)
%
% The returned value is an amplitude attenuation coefficient in dB/cm.
% This pure unit-conversion helper does not imply that the time-domain
% elastic solver implements an arbitrary power law. The attenuation benchmark evaluates this
% target independently for each monofrequency simulation and then calibrates
% k-Wave's f^2 Kelvin-Voigt coefficient at that simulation frequency.

arguments
    alpha_ref_db_cm (1,1) double {mustBeNonnegative, mustBeFinite}
    f_ref_hz (1,1) double {mustBePositive, mustBeFinite}
    power_y (1,1) double {mustBeNonnegative, mustBeFinite}
    f0_hz (1,1) double {mustBePositive, mustBeFinite}
end

alpha_db_cm = alpha_ref_db_cm * (f0_hz/f_ref_hz)^power_y;

end
