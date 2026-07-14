function cfg = stage4_power_law_config()
%STAGE4_POWER_LAW_CONFIG Reproducible Stage 4 attenuation configuration.
%
% Edit material laws here rather than changing solver or conversion code.
% Every frequency supplied to runFrequencySweep remains an independent
% monofrequency simulation.

cfg = kwsim.two_d.stage4Config();

end
