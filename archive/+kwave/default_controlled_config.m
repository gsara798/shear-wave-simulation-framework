function CFG = default_controlled_config(varargin)
%DEFAULT_CONTROLLED_CONFIG Reproducible 2D k-Wave simulation defaults.
%
% The defaults are intentionally modest. They are meant for controlled,
% interpretable tests before launching large k-Wave sweeps.

p = inputParser;
p.FunctionName = 'adaptive_req.kwave.default_controlled_config';
addParameter(p, 'Geometry', "inclusion_2_3", @(x) ischar(x) || isstring(x));
addParameter(p, 'SourceMode', "single_sine", @(x) ischar(x) || isstring(x));
addParameter(p, 'Seed', 1001, @(x) isnumeric(x) && isscalar(x));
addParameter(p, 'Nx', 96, @(x) isnumeric(x) && isscalar(x) && x >= 32);
addParameter(p, 'Nz', 96, @(x) isnumeric(x) && isscalar(x) && x >= 32);
addParameter(p, 'dx', 0.5e-3, @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(p, 'dz', 0.5e-3, @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(p, 'f0', 500, @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(p, 't_end', 0.040, @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(p, 'CFL', 0.20, @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(p, 'cs_soft', 2.0, @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(p, 'cs_hard', 3.0, @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(p, 'rho_soft', 1000, @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(p, 'rho_hard', 1020, @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(p, 'CompressionMode', "matched_shear", @(x) ischar(x) || isstring(x));
addParameter(p, 'compression_speed', 30, @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(p, 'alpha_shear', 20, @(x) isnumeric(x) && isscalar(x) && x >= 0);
addParameter(p, 'alpha_compression', 0.05, @(x) isnumeric(x) && isscalar(x) && x >= 0);
addParameter(p, 'source_radius_m', 2.0e-3, @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(p, 'source_magnitude', 1e-6, @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(p, 'SourceSide', "left", @(x) ischar(x) || isstring(x));
addParameter(p, 'SourcePolarization', "axial", @(x) ischar(x) || isstring(x));
addParameter(p, 'num_sources', [], @(x) isempty(x) || (isnumeric(x) && isscalar(x) && x >= 1));
addParameter(p, 'inclusion_radius_m', 8.0e-3, @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(p, 'VelocityComponent', "axial_shear", @(x) ischar(x) || isstring(x));
addParameter(p, 'AnalysisROIMode', "exclude_source_buffer", @(x) ischar(x) || isstring(x));
addParameter(p, 'AnalysisBufferM', 12.0e-3, @(x) isnumeric(x) && isscalar(x) && x >= 0);
addParameter(p, 'AnalysisMarginM', 2.0e-3, @(x) isnumeric(x) && isscalar(x) && x >= 0);
addParameter(p, 'DataCast', "single", @(x) ischar(x) || isstring(x));
addParameter(p, 'PlotSim', false, @(x) islogical(x) || isnumeric(x));
addParameter(p, 'PMLInside', false, @(x) islogical(x) || isnumeric(x));
addParameter(p, 'PMLSize', 12, @(x) isnumeric(x) && isscalar(x) && x >= 0);
addParameter(p, 'KWavePath', "", @(x) ischar(x) || isstring(x));
parse(p, varargin{:});

CFG = p.Results;
CFG.Geometry = lower(string(CFG.Geometry));
CFG.SourceMode = lower(string(CFG.SourceMode));
CFG.SourceSide = lower(string(CFG.SourceSide));
CFG.SourcePolarization = lower(string(CFG.SourcePolarization));
CFG.CompressionMode = lower(string(CFG.CompressionMode));
CFG.VelocityComponent = lower(string(CFG.VelocityComponent));
CFG.AnalysisROIMode = lower(string(CFG.AnalysisROIMode));
CFG.DataCast = char(string(CFG.DataCast));
CFG.KWavePath = string(CFG.KWavePath);
CFG.PlotSim = logical(CFG.PlotSim);
CFG.PMLInside = logical(CFG.PMLInside);
CFG.Seed = round(CFG.Seed);
CFG.Nx = round(CFG.Nx);
CFG.Nz = round(CFG.Nz);

if isempty(CFG.num_sources)
    switch CFG.SourceMode
        case {"single_sine", "single_square"}
            CFG.num_sources = 1;
        case "sources8_sine"
            CFG.num_sources = 8;
        case "sources128_sine"
            CFG.num_sources = 128;
        otherwise
            error('Unknown SourceMode: %s', CFG.SourceMode);
    end
end

CFG.x_m = (0:(CFG.Nx - 1)) * CFG.dx;
CFG.z_m = (0:(CFG.Nz - 1)) * CFG.dz;
CFG.inclusion_center_m = [median(CFG.x_m), median(CFG.z_m)];

end
