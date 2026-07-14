function validation = runStage2Validation(base_cfg)
%RUNSTAGE2VALIDATION Run and evaluate the three Stage 2 comparison cases.
%
% validation = kwsim.diagnostics.runStage2Validation(cfg)
%
% The suite runs: (1) the requested contrast inclusion, (2) a homogeneous
% reference with the same constant cp, and (3) a zero-contrast circle with
% the same constant cp. Numerical evaluation is delegated to
% evaluateStage2Results so saved simulations can be re-evaluated after a
% diagnostic update without rerunning k-Wave.

arguments
    base_cfg struct = kwsim.two_d.circularInclusionConfig()
end

if isempty(base_cfg.geometry.objects)
    error('kwsim:MissingStage2Geometry', ...
        'Stage 2 validation requires at least one geometry object.');
end

base_cfg.diagnostics.fail_on_invalid = false;
base_cfg.output.directory = "";
base_cfg.output.save_time_series = false;
[resolved_base, ~] = kwsim.two_d.validateConfig(base_cfg);
constant_cp_m_s = resolved_base.medium.cp_m_s;

[contrast, contrast_report] = kwsim.two_d.run(base_cfg);

homogeneous_cfg = base_cfg;
homogeneous_cfg.scenario = "stage2_homogeneous_reference";
homogeneous_cfg.geometry.objects = homogeneous_cfg.geometry.objects([]);
homogeneous_cfg.medium.reduced_cp_factor = ...
    constant_cp_m_s / homogeneous_cfg.medium.cs_m_s;
[homogeneous, homogeneous_report] = kwsim.two_d.run(homogeneous_cfg);

zero_cfg = base_cfg;
zero_cfg.scenario = "stage2_zero_contrast";
for index = 1:numel(zero_cfg.geometry.objects)
    zero_cfg.geometry.objects(index).cs_m_s = zero_cfg.medium.cs_m_s;
    zero_cfg.geometry.objects(index).rho_kg_m3 = zero_cfg.medium.rho_kg_m3;
end
zero_cfg.medium.reduced_cp_factor = constant_cp_m_s / zero_cfg.medium.cs_m_s;
[zero_contrast, zero_report] = kwsim.two_d.run(zero_cfg);

validation = kwsim.diagnostics.evaluateStage2Results( ...
    contrast, contrast_report, homogeneous, homogeneous_report, ...
    zero_contrast, zero_report, base_cfg);

end
