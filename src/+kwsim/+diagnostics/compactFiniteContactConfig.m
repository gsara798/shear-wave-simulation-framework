function cfg = compactFiniteContactConfig(regime)
%COMPACTFINITECONTACTCONFIG Fast Stage 3B finite-contact benchmark.

arguments
    regime (1,1) string {mustBeMember(regime, ...
        ["directional", "partially_diffuse", "diffuse"])} = "directional"
end

cfg = kwsim.diagnostics.compactStage3Config(regime);
cfg.scenario = "compact_stage3b_finite_contact_" + regime;
cfg.source.contact_model = "finite_segment";
cfg.source.contact_sampling = "sparse_patch";
cfg.source.contact_profile = "raised_cosine";
cfg.source.contact_node_spacing_points = 4;
cfg.source.contact_radius_m = 2e-3;

switch regime
    case "directional"
        cfg.source.vibrator_count = 4;
    case "partially_diffuse"
        cfg.source.vibrator_count = 8;
    case "diffuse"
        cfg.source.vibrator_count = 8;
end

end
