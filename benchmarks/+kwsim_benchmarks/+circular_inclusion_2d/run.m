function validation = run(base_cfg)
%RUN Run and evaluate the three circular-inclusion benchmark comparison cases.
%
% validation = kwsim_benchmarks.circular_inclusion_2d.run(cfg)
%
% The suite runs: (1) the requested contrast inclusion, (2) a homogeneous
% reference with the same constant cp, and (3) a zero-contrast circle with
% the same constant cp. Numerical evaluation is delegated to
% circular_inclusion_2d.evaluate so saved simulations can be re-evaluated after a
% diagnostic update without rerunning k-Wave.

arguments
    base_cfg struct = kwsim_benchmarks.circular_inclusion_2d.config()
end

if isempty(base_cfg.geometry.objects)
    error('kwsim:MissingCircularInclusionGeometry', ...
        'circular-inclusion benchmark validation requires at least one geometry object.');
end

base_cfg.diagnostics.fail_on_invalid = false;
base_cfg.output.save_time_series = false;
[resolved_base, ~] = kwsim.two_d.validateConfig(base_cfg);
constant_cp_m_s = resolved_base.medium.cp_m_s;

[contrast, contrast_report] = kwsim.two_d.run(base_cfg);

homogeneous_cfg = base_cfg;
homogeneous_cfg.scenario = "circular_inclusion_homogeneous_reference";
homogeneous_cfg.geometry.objects = homogeneous_cfg.geometry.objects([]);
homogeneous_cfg.medium.reduced_cp_factor = ...
    constant_cp_m_s / homogeneous_cfg.medium.cs_m_s;
[homogeneous, homogeneous_report] = kwsim.two_d.run(homogeneous_cfg);

zero_cfg = base_cfg;
zero_cfg.scenario = "circular_inclusion_zero_contrast";
for index = 1:numel(zero_cfg.geometry.objects)
    zero_cfg.geometry.objects(index).cs_m_s = zero_cfg.medium.cs_m_s;
    zero_cfg.geometry.objects(index).rho_kg_m3 = zero_cfg.medium.rho_kg_m3;
end
zero_cfg.medium.reduced_cp_factor = constant_cp_m_s / zero_cfg.medium.cs_m_s;
[zero_contrast, zero_report] = kwsim.two_d.run(zero_cfg);

validation = kwsim_benchmarks.circular_inclusion_2d.evaluate( ...
    contrast, contrast_report, homogeneous, homogeneous_report, ...
    zero_contrast, zero_report, base_cfg);

end
