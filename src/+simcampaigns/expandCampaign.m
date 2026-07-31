function [runs, expansion] = expandCampaign(campaign_file)
%EXPANDCAMPAIGN Expand one campaign into deterministic run definitions.
%
% Cartesian mode:
%   The last declared sweep parameter varies fastest.
%
% Explicit mode:
%   Runs preserve the exact order declared in the campaign JSON.

arguments
    campaign_file {mustBeTextScalar}
end

[campaign, campaign_metadata] = ...
    simcampaigns.loadCampaignJson(campaign_file);

switch campaign.mode
    case "cartesian_sweep"
        runs = expandCartesian( ...
            campaign, ...
            campaign_metadata);

        order_description = ...
            "declared_parameter_order_last_parameter_fastest";

    case "explicit_runs"
        runs = expandExplicit( ...
            campaign, ...
            campaign_metadata);

        order_description = ...
            "explicit_json_run_order";

    otherwise
        error("simcampaigns:UnsupportedCampaignMode", ...
            "Unsupported campaign mode: %s", ...
            campaign.mode);
end

expansion = campaign_metadata;
expansion.campaign = campaign;
expansion.backend = campaign.backend;
expansion.run_count = numel(runs);
expansion.order = order_description;

end


function runs = expandCartesian(campaign, metadata)

parameter_count = metadata.parameter_count;
value_counts = metadata.value_counts;
run_count = metadata.expanded_run_count;

empty_selection = repmat(struct( ...
    "path", "", ...
    "value_index", 0, ...
    "value", []), ...
    parameter_count, ...
    1);

empty_run = struct();
empty_run.ordinal = 0;
empty_run.design_id = "";
empty_run.condition_id = "";
empty_run.realization_id = NaN;
empty_run.run_id = "";
empty_run.hash_sha256 = "";
empty_run.backend = campaign.backend;
empty_run.value_indices = zeros(parameter_count,1);
empty_run.selection = empty_selection;
empty_run.config = metadata.base_config;

runs = repmat(empty_run, run_count,1);

for ordinal = 1:run_count
    value_indices = cartesianIndices( ...
        ordinal, ...
        value_counts);

    config = metadata.base_config;
    selection = empty_selection;

    for parameter_index = 1:parameter_count
        parameter = campaign.sweep(parameter_index);

        base_value = simcampaigns.getPathValue( ...
            metadata.base_config, ...
            parameter.path);

        selected_value = valueAt( ...
            parameter.values, ...
            value_indices(parameter_index), ...
            base_value);

        config = simcampaigns.setPathValue( ...
            config, ...
            parameter.path, ...
            selected_value);

        selection(parameter_index).path = ...
            string(parameter.path);

        selection(parameter_index).value_index = ...
            value_indices(parameter_index);

        selection(parameter_index).value = ...
            selected_value;
    end

    [run_id, hash_sha256] = ...
        buildRunIdentity( ...
            ordinal, ...
            campaign.backend, ...
            config);

    runs(ordinal).ordinal = ordinal;
    runs(ordinal).design_id = "";
    runs(ordinal).run_id = run_id;
    runs(ordinal).hash_sha256 = hash_sha256;
    runs(ordinal).backend = campaign.backend;
    runs(ordinal).value_indices = value_indices;
    runs(ordinal).selection = selection;
    runs(ordinal).config = config;
end

end


function runs = expandExplicit(campaign, metadata)

run_count = numel(campaign.runs);

empty_run = struct();
empty_run.ordinal = 0;
empty_run.design_id = "";
empty_run.condition_id = "";
empty_run.realization_id = NaN;
empty_run.run_id = "";
empty_run.hash_sha256 = "";
empty_run.backend = campaign.backend;
empty_run.value_indices = zeros(0,1);
empty_run.selection = struct([]);
empty_run.config = metadata.base_config;

runs = repmat(empty_run, run_count,1);

for ordinal = 1:run_count
    definition = campaign.runs(ordinal);
    overrides = definition.overrides;

    config = metadata.base_config;

    selection = repmat(struct( ...
        "path", "", ...
        "value_index", 1, ...
        "value", []), ...
        numel(overrides), ...
        1);

    for override_index = 1:numel(overrides)
        override = overrides(override_index);

        config = simcampaigns.setPathValue( ...
            config, ...
            override.path, ...
            override.value);

        selection(override_index).path = ...
            string(override.path);

        selection(override_index).value_index = 1;
        selection(override_index).value = ...
            override.value;
    end

    [run_id, hash_sha256] = ...
        buildRunIdentity( ...
            ordinal, ...
            campaign.backend, ...
            config);

    runs(ordinal).ordinal = ordinal;
    runs(ordinal).design_id = ...
        string(definition.design_id);

    if isfield(definition, "condition_id")
        runs(ordinal).condition_id = ...
            string(definition.condition_id);
    else
        runs(ordinal).condition_id = "";
    end

    if isfield(definition, "realization_id")
        runs(ordinal).realization_id = ...
            double(definition.realization_id);
    else
        runs(ordinal).realization_id = NaN;
    end

    runs(ordinal).run_id = run_id;
    runs(ordinal).hash_sha256 = hash_sha256;
    runs(ordinal).backend = campaign.backend;
    runs(ordinal).value_indices = zeros(0,1);
    runs(ordinal).selection = selection;
    runs(ordinal).config = config;
end

end


function [run_id, hash_sha256] = ...
        buildRunIdentity(ordinal, backend, config)

canonical_identity = struct( ...
    "backend", backend, ...
    "config", config);

canonical_json = jsonencode(canonical_identity);
hash_sha256 = sha256Text(canonical_json);

run_id = string(sprintf( ...
    "run_%06d_%s", ...
    ordinal, ...
    extractBefore(hash_sha256,13)));

end


function value_indices = cartesianIndices( ...
        ordinal, value_counts)

remainder = ordinal - 1;
parameter_count = numel(value_counts);
value_indices = zeros(parameter_count,1);

for parameter_index = parameter_count:-1:1
    count = value_counts(parameter_index);

    value_indices(parameter_index) = ...
        mod(remainder, count) + 1;

    remainder = floor(remainder / count);
end

end


function value = valueAt(values, index, base_value)

if iscell(values)
    value = values{index};
    return
end

if ischar(values)
    if index ~= 1
        error("simcampaigns:InvalidCampaignSweepValues", ...
            "A character sweep value can only contain one entry.");
    end

    value = values;
    return
end

if isscalar(base_value)
    value = values(index);
    return
end

if isrow(base_value) && ...
        ismatrix(values) && ...
        size(values,2) == size(base_value,2)

    value = values(index,:);
    return
end

error("simcampaigns:InvalidCampaignSweepValues", ...
    "Could not extract a structured campaign sweep value.");

end


function hash_text = sha256Text(text)

bytes = unicode2native(char(string(text)), "UTF-8");
digest = java.security.MessageDigest.getInstance("SHA-256");
digest.update(bytes);

hash_bytes = typecast(digest.digest(), "uint8");
hex_rows = dec2hex(double(hash_bytes),2);
hash_text = lower(join(string(hex_rows),""));

end
