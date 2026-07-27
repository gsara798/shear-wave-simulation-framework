function csv_file = writeCampaignRunsCsv(report, runs)
%WRITECAMPAIGNRUNSCSV Write backend-neutral campaign run metadata.

arguments
    report (1,1) struct
    runs struct
end

run_count = numel(report.runs);

ordinal = zeros(run_count, 1);
run_id = strings(run_count, 1);
backend = strings(run_count, 1);
hash_sha256 = strings(run_count, 1);
status = strings(run_count, 1);
outcome_status = strings(run_count, 1);

scenario = strings(run_count, 1);
seed = NaN(run_count, 1);
frequency_hz = NaN(run_count, 1);
background_cs_m_s = NaN(run_count, 1);
medium_object_count = NaN(run_count, 1);
direction_count = NaN(run_count, 1);
propagation_model = strings(run_count, 1);
valid = NaN(run_count, 1);

run_directory = strings(run_count, 1);
resolved_config_path = strings(run_count, 1);
wavefield_sample_path = strings(run_count, 1);
summary_path = strings(run_count, 1);
validation_report_path = strings(run_count, 1);

error_identifier = strings(run_count, 1);
error_message = strings(run_count, 1);

for index = 1:run_count
    record = report.runs(index);
    config = runs(index).config;

    ordinal(index) = record.ordinal;
    run_id(index) = string(record.run_id);
    backend(index) = string(runs(index).backend);
    hash_sha256(index) = string(record.hash_sha256);
    status(index) = string(record.status);
    outcome_status(index) = string(record.outcome_status);

    run_directory(index) = string(record.run_directory);

    resolved_config_path(index) = fullfile( ...
        run_directory(index), ...
        "config", ...
        "resolved_config.json");

    wavefield_sample_path(index) = fullfile( ...
        run_directory(index), ...
        "data", ...
        "wavefield_sample.mat");

    summary_path(index) = fullfile( ...
        run_directory(index), ...
        "data", ...
        "run_summary.json");

    validation_report_path(index) = fullfile( ...
        run_directory(index), ...
        "data", ...
        "validation_report.json");

    error_identifier(index) = string(record.error_identifier);
    error_message(index) = string(record.error_message);

    if isfile(resolved_config_path(index))
        try
            config = jsondecode(fileread(resolved_config_path(index)));
        catch
            config = runs(index).config;
        end
    end

    scenario(index) = textField(config, "scenario");
    seed(index) = numericField(config, "seed");

    if backend(index) == "swsynth"
        if isfield(config, "wavefield")
            frequency_hz(index) = ...
                numericField(config.wavefield, "frequency_hz");
        end

        if isfield(config, "medium")
            background_cs_m_s(index) = ...
                numericField(config.medium, "background_cs_m_s");

            if isfield(config.medium, "objects")
                medium_object_count(index) = ...
                    numel(config.medium.objects);
            end
        end

        if isfield(config, "directions")
            direction_count(index) = ...
                numericField(config.directions, "count");
        end

        if isfield(config, "propagation")
            propagation_model(index) = ...
                textField(config.propagation, "model");
        end

    elseif backend(index) == "kwsim"
        if isfield(config, "source")
            frequency_hz(index) = ...
                numericField(config.source, "f0_hz");
        end

        if isfield(config, "medium")
            background_cs_m_s(index) = ...
                numericField(config.medium, "cs_m_s");
        end
    end

    if isfile(validation_report_path(index))
        try
            validation_value = ...
                jsondecode(fileread(validation_report_path(index)));

            valid(index) = ...
                numericField(validation_value, "valid");
        catch
            % Keep unavailable value as NaN.
        end
    end
end

campaign_runs = table( ...
    ordinal, ...
    run_id, ...
    backend, ...
    hash_sha256, ...
    status, ...
    outcome_status, ...
    scenario, ...
    seed, ...
    frequency_hz, ...
    background_cs_m_s, ...
    medium_object_count, ...
    direction_count, ...
    propagation_model, ...
    valid, ...
    run_directory, ...
    resolved_config_path, ...
    wavefield_sample_path, ...
    summary_path, ...
    validation_report_path, ...
    error_identifier, ...
    error_message);

csv_file = fullfile( ...
    string(report.campaign_directory), ...
    "campaign_runs.csv");

temporary_file = csv_file + ".tmp.csv";
deleteIfPresent(temporary_file);

writetable( ...
    campaign_runs, ...
    temporary_file, ...
    FileType="text", ...
    Delimiter=",");

[moved, message] = movefile( ...
    temporary_file, ...
    csv_file, ...
    "f");

if ~moved
    deleteIfPresent(temporary_file);

    error("simcampaigns:CampaignTableWriteFailed", ...
        "Could not publish campaign table '%s': %s", ...
        csv_file, message);
end

end

function value = numericField(value_struct, field_name)

value = NaN;

if ~isstruct(value_struct) || ...
        ~isscalar(value_struct) || ...
        ~isfield(value_struct, field_name)
    return
end

candidate = value_struct.(field_name);

if (isnumeric(candidate) || islogical(candidate)) && ...
        isscalar(candidate) && ...
        isfinite(double(candidate))
    value = double(candidate);
end

end

function value = textField(value_struct, field_name)

value = "";

if ~isstruct(value_struct) || ...
        ~isscalar(value_struct) || ...
        ~isfield(value_struct, field_name)
    return
end

candidate = value_struct.(field_name);

if (isstring(candidate) && isscalar(candidate)) || ...
        (ischar(candidate) && isrow(candidate))
    value = string(candidate);
end

end

function deleteIfPresent(path_value)

if isfile(path_value)
    delete(path_value);
end

end
