function [maps, metadata] = resolveAttenuation(cfg, geometry_maps)
%RESOLVEATTENUATION Convert material power laws to 2D Kelvin-Voigt maps.
%
% [maps, metadata] = kwsim.two_d.resolveAttenuation(cfg, geometry_maps)
%
% Inputs and outputs use k-Wave's internal [Nx,Nz] orientation. At the
% current monofrequency f0, the requested power law is converted to the
% coefficient expected by pstdElastic2D:
%
%   alpha_kv = alpha(f0)/(f0/1e6)^2  [dB/(MHz^2 cm)].
%
% The physical admissibility guard requires non-negative shear viscosity
% eta and volumetric viscosity chi. Zero attenuation is represented by
% attenuation.enabled=false; an enabled heterogeneous Kelvin-Voigt map is
% required to be strictly positive to avoid reciprocal interpolation of a
% zero shear viscosity on k-Wave's staggered grid.

arguments
    cfg struct
    geometry_maps struct
end

grid_size = size(geometry_maps.material_id_xz);
maps = emptyMaps(grid_size);
metadata = struct('enabled', logical(cfg.attenuation.enabled), ...
    'model', string(cfg.attenuation.model), ...
    'frequency_hz', cfg.source.f0_hz, ...
    'materials', repmat(emptyMaterial(), 0, 1), ...
    'units', attenuationUnits());

if ~cfg.attenuation.enabled
    metadata.model = "lossless";
    return;
end

if lower(string(cfg.attenuation.model)) ~= "monofrequency_power_law"
    invalid('attenuation.model must be "monofrequency_power_law".');
end
materials = cfg.attenuation.materials;
if ~isstruct(materials) || isempty(materials)
    invalid('attenuation.materials must contain at least one material.');
end
if ~all(isfield(materials, 'material_id'))
    invalid('Every attenuation material requires material_id.');
end

required_ids = unique(geometry_maps.material_id_xz(:)).';
provided_ids = reshape([materials.material_id], 1, []);
if ~isnumeric(provided_ids) || any(~isfinite(provided_ids)) || ...
        any(provided_ids < 1) || any(provided_ids ~= round(provided_ids))
    invalid('Every attenuation material_id must be a positive integer.');
end
if numel(unique(provided_ids)) ~= numel(provided_ids)
    invalid('Every attenuation material_id must be unique.');
end
if ~isequal(sort(double(provided_ids)), sort(double(required_ids)))
    invalid(['Attenuation definitions must cover exactly the material IDs ', ...
        'present in the rasterized medium.']);
end

resolved = repmat(emptyMaterial(), numel(materials), 1);
for index = 1:numel(materials)
    requested = materials(index);
    validateMaterial(requested);
    material_mask = geometry_maps.material_id_xz == requested.material_id;
    if ~any(material_mask, 'all')
        invalid(sprintf('Attenuation material ID %d is not present.', ...
            requested.material_id));
    end

    shear_target = kwsim.materials.evaluatePowerLawAttenuation( ...
        requested.shear.alpha_ref_db_cm, requested.shear.f_ref_hz, ...
        requested.shear.power_y, cfg.source.f0_hz);
    compression_target = kwsim.materials.evaluatePowerLawAttenuation( ...
        requested.compression.alpha_ref_db_cm, ...
        requested.compression.f_ref_hz, ...
        requested.compression.power_y, cfg.source.f0_hz);
    if shear_target <= 0 || compression_target <= 0
        invalid(['Enabled Kelvin-Voigt materials require strictly positive ', ...
            'shear and compression attenuation at f0.']);
    end

    frequency_mhz = cfg.source.f0_hz/1e6;
    shear_kv = shear_target/frequency_mhz^2;
    compression_kv = compression_target/frequency_mhz^2;
    rho = geometry_maps.rho_kg_m3_xz(material_mask);
    cs = geometry_maps.cs_m_s_xz(material_mask);
    cp = cfg.medium.cp_m_s;
    shear_np = dbPerMHz2CmToNeper(shear_kv);
    compression_np = dbPerMHz2CmToNeper(compression_kv);
    eta = 2*rho.*cs.^3*shear_np;
    chi = 2*rho.*cp.^3*compression_np - 2*eta;
    if any(~isfinite(eta)) || any(~isfinite(chi)) || ...
            any(eta < 0) || any(chi < 0)
        invalid(sprintf(['Material %d produces a negative or non-finite ', ...
            'Kelvin-Voigt viscosity. Increase compression attenuation or ', ...
            'revise the material law.'], requested.material_id));
    end

    maps.shear_alpha_at_f0_db_cm_xz(material_mask) = shear_target;
    maps.compression_alpha_at_f0_db_cm_xz(material_mask) = compression_target;
    maps.shear_kv_db_mhz2_cm_xz(material_mask) = shear_kv;
    maps.compression_kv_db_mhz2_cm_xz(material_mask) = compression_kv;
    maps.eta_pa_s_xz(material_mask) = eta;
    maps.chi_pa_s_xz(material_mask) = chi;

    info = emptyMaterial();
    info.material_id = requested.material_id;
    info.shear = requested.shear;
    info.compression = requested.compression;
    info.shear_alpha_at_f0_db_cm = shear_target;
    info.compression_alpha_at_f0_db_cm = compression_target;
    info.shear_kv_db_mhz2_cm = shear_kv;
    info.compression_kv_db_mhz2_cm = compression_kv;
    info.eta_pa_s_range = [min(eta), max(eta)];
    info.chi_pa_s_range = [min(chi), max(chi)];
    resolved(index) = info;
end
metadata.materials = resolved;

end

function validateMaterial(material)
if ~all(isfield(material, ["material_id", "shear", "compression"]))
    invalid('Each attenuation material requires material_id, shear, and compression.');
end
validateLaw(material.shear, 'shear');
validateLaw(material.compression, 'compression');
end

function validateLaw(law, label)
required = ["alpha_ref_db_cm", "f_ref_hz", "power_y"];
if ~isstruct(law) || ~all(isfield(law, required))
    invalid(sprintf('%s attenuation law is incomplete.', label));
end
values = [law.alpha_ref_db_cm, law.f_ref_hz, law.power_y];
if any(~isfinite(values)) || law.alpha_ref_db_cm < 0 || ...
        law.f_ref_hz <= 0 || law.power_y < 0
    invalid(sprintf('%s attenuation law contains invalid values.', label));
end
end

function value = dbPerMHz2CmToNeper(value)
% Same unit conversion used by k-Wave db2neper(value, 2), kept local so
% configuration validation does not depend on MATLAB path state.
value = 100*value*(1e-6/(2*pi))^2/(20*log10(exp(1)));
end

function maps = emptyMaps(grid_size)
zeros_map = zeros(grid_size);
maps = struct('shear_alpha_at_f0_db_cm_xz', zeros_map, ...
    'compression_alpha_at_f0_db_cm_xz', zeros_map, ...
    'shear_kv_db_mhz2_cm_xz', zeros_map, ...
    'compression_kv_db_mhz2_cm_xz', zeros_map, ...
    'eta_pa_s_xz', zeros_map, 'chi_pa_s_xz', zeros_map);
end

function info = emptyMaterial()
law = struct('alpha_ref_db_cm', NaN, 'f_ref_hz', NaN, 'power_y', NaN);
info = struct('material_id', uint16(0), 'shear', law, ...
    'compression', law, 'shear_alpha_at_f0_db_cm', NaN, ...
    'compression_alpha_at_f0_db_cm', NaN, ...
    'shear_kv_db_mhz2_cm', NaN, 'compression_kv_db_mhz2_cm', NaN, ...
    'eta_pa_s_range', [NaN, NaN], 'chi_pa_s_range', [NaN, NaN]);
end

function units = attenuationUnits()
units = struct('target_at_f0', "dB/cm", ...
    'kelvin_voigt_coefficient', "dB/(MHz^2 cm)", ...
    'viscosity', "Pa s");
end

function invalid(message)
error('kwsim:InvalidConfiguration', ...
    'Attenuation configuration is invalid: %s', message);
end
