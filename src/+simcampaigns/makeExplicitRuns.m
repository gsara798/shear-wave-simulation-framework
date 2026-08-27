function definitions = makeExplicitRuns(plan, override_map, options)
%MAKEEXPLICITRUNS Convert a tabular run plan to schema-1.2 explicit runs.
%
% definitions = simcampaigns.makeExplicitRuns(plan, override_map)
%
% plan
%   MATLAB table containing one row per planned simulation.
%
% override_map
%   N-by-2 string array:
%
%       [configuration_path, source_column]
%
%   Example:
%
%       [
%         "seed"                    "random_seed"
%         "wavefield.frequency_hz"  "frequency_hz"
%       ]
%
% Optional provenance columns may be selected with:
%
%   DesignIdColumn
%   ConditionIdColumn
%   RealizationIdColumn
%
% No simulator-, backend-, or project-specific parameter names are assumed.

arguments
    plan table
    override_map (:,2) string

    options.DesignIdColumn (1,1) string = "design_id"
    options.ConditionIdColumn (1,1) string = ""
    options.RealizationIdColumn (1,1) string = ""
end

if height(plan) == 0
    error( ...
        "simcampaigns:EmptyExplicitRunPlan", ...
        "The explicit-run plan must contain at least one row.");
end

if size(override_map,1) == 0
    error( ...
        "simcampaigns:EmptyExplicitOverrideMap", ...
        "The override map must contain at least one mapping.");
end

config_paths = override_map(:,1);
source_columns = override_map(:,2);

if any(strlength(config_paths) == 0) || ...
        any(strlength(source_columns) == 0)
    error( ...
        "simcampaigns:InvalidExplicitOverrideMap", ...
        "Configuration paths and source columns must be non-empty.");
end

if numel(unique(config_paths)) ~= numel(config_paths)
    error( ...
        "simcampaigns:DuplicateExplicitOverridePath", ...
        "Each configuration path may appear only once.");
end

design_column = options.DesignIdColumn;
condition_column = options.ConditionIdColumn;
realization_column = options.RealizationIdColumn;

require_column(plan,design_column,"DesignIdColumn");

has_condition = strlength(condition_column) > 0;
has_realization = strlength(realization_column) > 0;

if xor(has_condition,has_realization)
    error( ...
        "simcampaigns:IncompleteExplicitRunProvenance", ...
        "ConditionIdColumn and RealizationIdColumn must either " + ...
        "both be supplied or both be omitted.");
end

if has_condition
    require_column(plan,condition_column,"ConditionIdColumn");
    require_column(plan,realization_column,"RealizationIdColumn");
end

for source_column = source_columns'
    require_column(plan,source_column,"override map");
end

definitions = repmat(struct( ...
    "design_id","", ...
    "overrides",struct([])), ...
    height(plan),1);

if has_condition
    definitions = repmat(struct( ...
        "design_id","", ...
        "condition_id","", ...
        "realization_id",0, ...
        "overrides",struct([])), ...
        height(plan),1);
end

for row_index = 1:height(plan)

    design_id = string(row_value(plan,row_index,design_column));

    if ~isscalar(design_id) || ...
            ismissing(design_id) || ...
            strlength(design_id) == 0
        error( ...
            "simcampaigns:InvalidExplicitDesignId", ...
            "Row %d contains an invalid design ID.", ...
            row_index);
    end

    definitions(row_index).design_id = design_id;

    if has_condition
        condition_id = string( ...
            row_value(plan,row_index,condition_column));

        if ~isscalar(condition_id) || ...
                ismissing(condition_id) || ...
                strlength(condition_id) == 0
            error( ...
                "simcampaigns:InvalidExplicitConditionId", ...
                "Row %d contains an invalid condition ID.", ...
                row_index);
        end

        realization_id = double( ...
            row_value(plan,row_index,realization_column));

        if ~isscalar(realization_id) || ...
                ~isfinite(realization_id) || ...
                realization_id < 1 || ...
                realization_id ~= fix(realization_id)
            error( ...
                "simcampaigns:InvalidExplicitRealizationId", ...
                ["Row %d contains an invalid realization ID; " ...
                 "a positive integer is required."], ...
                row_index);
        end

        definitions(row_index).condition_id = condition_id;
        definitions(row_index).realization_id = realization_id;
    end

    overrides = repmat(struct( ...
        "path","", ...
        "value",[]), ...
        size(override_map,1),1);

    for map_index = 1:size(override_map,1)

        overrides(map_index).path = ...
            config_paths(map_index);

        overrides(map_index).value = ...
            row_value( ...
                plan, ...
                row_index, ...
                source_columns(map_index));
    end

    definitions(row_index).overrides = overrides;
end

design_ids = string({definitions.design_id})';

if numel(unique(design_ids)) ~= numel(design_ids)
    error( ...
        "simcampaigns:DuplicateExplicitDesignId", ...
        "Each explicit run must have a unique design ID.");
end

end


function require_column(plan,column_name,source)

variables = string(plan.Properties.VariableNames);

if ~ismember(column_name,variables)
    error( ...
        "simcampaigns:ExplicitRunPlanColumnMissing", ...
        "Column '%s' required by %s is missing from the run plan.", ...
        column_name,source);
end

end


function value = row_value(plan,row_index,column_name)

raw = plan.(column_name);

if iscell(raw)
    value = raw{row_index};
    return
end

if isstring(raw) || iscategorical(raw)
    value = raw(row_index,:);
    return
end

if ischar(raw)
    value = raw(row_index,:);
    return
end

if isstruct(raw)
    value = raw(row_index,:);
    return
end

value = raw(row_index,:);

end
