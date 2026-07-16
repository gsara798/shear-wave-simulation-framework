function info = provenance(cfg, kwave_root)
%PROVENANCE Capture the environment needed to interpret a saved run.
%
% This is descriptive provenance rather than a claim of cross-platform
% bitwise reproducibility. Numerical reproducibility is assessed separately
% by the directional homogeneous validation suite on the same backend.

arguments
    cfg struct
    kwave_root {mustBeTextScalar}
end

info = struct();
info.created_utc = string(datetime('now', 'TimeZone', 'UTC', ...
    'Format', 'yyyy-MM-dd''T''HH:mm:ss.SSSXXX'));
info.matlab_version = string(version);
info.matlab_release = string(version('-release'));
info.computer = string(computer);
info.kwave_version = "1.4.1";
info.kwave_root = string(kwave_root);
info.kwsim_schema_version = string(cfg.schema_version);
info.random_seed = cfg.seed;
info.backend = string(cfg.solver.backend);
info.data_cast = string(cfg.solver.data_cast);

end
