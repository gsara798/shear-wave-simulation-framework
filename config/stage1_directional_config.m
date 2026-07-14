function cfg = stage1_directional_config()
%STAGE1_DIRECTIONAL_CONFIG Return the documented 96-by-96 reference case.
%
% Keep scenario-specific overrides here rather than editing solver code.
% Downstream projects can copy this pattern and version their own configs.

cfg = kwsim.two_d.defaultConfig();

end
