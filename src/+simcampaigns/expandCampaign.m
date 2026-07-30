function [runs, expansion] = expandCampaign(campaign_file)
%EXPANDCAMPAIGN Expand one campaign into deterministic run definitions.
%
%   [runs, expansion] = simcampaigns.expandCampaign(campaign_file)
%
% The last declared sweep parameter varies fastest. This function does not
% execute k-Wave, create output directories, or modify the base configuration
% file.

arguments
    campaign_file {mustBeTextScalar}
end

[campaign, campaign_metadata] = ...
    simcampaigns.loadCampaignJson(campaign_file);

parameter_count = campaign_metadata.parameter_count;
value_counts = campaign_metadata.value_counts;
run_count = campaign_metadata.expanded_run_count;

empty_selection = repmat(struct( ...
    "path", "", ...
    "value_index", 0, ...
    "value", []), ...
    parameter_count, ...
    1);

empty_run = struct();
empty_run.ordinal = 0;
empty_run.run_id = "";
empty_run.hash_sha256 = "";
empty_run.backend = campaign.backend;
empty_run.value_indices = zeros(parameter_count, 1);
empty_run.selection = empty_selection;
empty_run.config = campaign_metadata.base_config;

runs = repmat(empty_run, run_count, 1);

for ordinal = 1:run_count
    value_indices = cartesianIndices( ...
        ordinal, ...
        value_counts);

    config = campaign_metadata.base_config;
    selection = empty_selection;

    for parameter_index = 1:parameter_count
        parameter = campaign.sweep(parameter_index);
        base_value = simcampaigns.getPathValue( ...
            campaign_metadata.base_config, ...
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

    canonical_identity = struct("backend", campaign.backend, "config", config);
    canonical_json = jsonencode(canonical_identity);
    hash_sha256 = sha256Text(canonical_json);

    runs(ordinal).ordinal = ordinal;
    runs(ordinal).run_id = string(sprintf( ...
        "run_%06d_%s", ...
        ordinal, ...
        extractBefore(hash_sha256, 13)));
    runs(ordinal).hash_sha256 = hash_sha256;
    runs(ordinal).backend = campaign.backend;
    runs(ordinal).value_indices = value_indices;
    runs(ordinal).selection = selection;
    runs(ordinal).config = config;
end

expansion = campaign_metadata;
expansion.campaign = campaign;
expansion.backend = campaign.backend;
expansion.run_count = run_count;
expansion.order = ...
    "declared_parameter_order_last_parameter_fastest";

end


function value_indices = cartesianIndices(ordinal, value_counts)

remainder = ordinal - 1;
parameter_count = numel(value_counts);
value_indices = zeros(parameter_count, 1);

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
        size(values, 2) == size(base_value, 2)

    value = values(index, :);
    return
end

error("simcampaigns:InvalidCampaignSweepValues", ...
    "Could not extract a structured campaign sweep value.");

end



function hash_text = sha256Text(text)

bytes = unicode2native(char(string(text)), 'UTF-8');
digest = java.security.MessageDigest.getInstance('SHA-256');
digest.update(bytes);

hash_bytes = typecast(digest.digest(), "uint8");
hex_rows = dec2hex(double(hash_bytes), 2);
hash_text = lower(join(string(hex_rows), ""));

end
