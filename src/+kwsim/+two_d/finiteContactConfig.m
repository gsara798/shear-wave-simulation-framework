function cfg = finiteContactConfig(regime)
%FINITECONTACTCONFIG Stage 3B configuration with finite external contacts.
%
% cfg = kwsim.two_d.finiteContactConfig("directional")
%
% A physical vibrator is a tangential perimeter segment sampled every two
% grid points. Every active node receives its own labelled solver channel,
% while all nodes in the segment share vibrator phase and polarization. A
% raised-cosine profile reduces edge discontinuities. The point-source model
% remains available through kwsim.two_d.stage3Config.

arguments
    regime (1,1) string {mustBeMember(regime, ...
        ["directional", "partially_diffuse", "diffuse"])} = "directional"
end

cfg = kwsim.two_d.stage3Config(regime);
cfg.scenario = "stage3b_finite_contact_" + regime;
cfg.source.contact_model = "finite_segment";
cfg.source.contact_sampling = "sparse_patch"; % Backward-compatible alias.
cfg.source.contact_profile = "raised_cosine";
% Three active nodes span 4 mm and remain 2 mm apart on the reference grid.
% A 1.5 mm separation was explicitly rejected after non-stationary diffuse
% fields; this spacing is therefore a validated numerical constraint.
cfg.source.contact_node_spacing_points = 4;
cfg.source.contact_radius_m = 2e-3;

switch regime
    case "directional"
        cfg.source.vibrator_count = 8;
    case "partially_diffuse"
        cfg.source.vibrator_count = 16;
    case "diffuse"
        cfg.source.vibrator_count = 16;
        % Finite diffuse contacts converge more slowly than point contacts.
        % A measured sweep from three to six settling cycles decreased the
        % final-cycle change monotonically from 1.337% to 0.929%.
        cfg.time.settling_cycles = 6;
end

end
