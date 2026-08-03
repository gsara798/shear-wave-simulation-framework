function csv_file = writeCampaignRunsCsv(report, runs)
%WRITECAMPAIGNRUNSCSV Write backend-neutral campaign run metadata.

arguments
    report (1,1) struct
    runs struct
end

run_count = numel(report.runs);

ordinal = zeros(run_count, 1);
design_id = strings(run_count, 1);
condition_id = strings(run_count, 1);
realization_id = NaN(run_count, 1);
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
primary_object_type = strings(run_count, 1);
primary_object_cs_m_s = NaN(run_count, 1);
primary_object_radius_m = NaN(run_count, 1);
geometry_family = strings(run_count, 1);

direction_count = NaN(run_count, 1);
retained_direction_count = NaN(run_count, 1);

direction_support_type = strings(run_count, 1);
solid_angle_sr = NaN(run_count, 1);

requested_in_plane_count = NaN(run_count, 1);
retained_in_plane_count = NaN(run_count, 1);
retained_in_plane_fraction = NaN(run_count, 1);

angular_entropy = NaN(run_count, 1);
angular_effective_bins = NaN(run_count, 1);
radial_entropy = NaN(run_count, 1);
radial_effective_bins = NaN(run_count, 1);

primary_object_center_x_m = NaN(run_count, 1);
primary_object_center_z_m = NaN(run_count, 1);
primary_object_normal_angle_rad = NaN(run_count, 1);
primary_object_offset_m = NaN(run_count, 1);

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
    design_id(index) = string(runs(index).design_id);
    condition_id(index) = string(runs(index).condition_id);
    realization_id(index) = double(runs(index).realization_id);
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

                if medium_object_count(index) > 0
                    object = firstObject(config.medium.objects);

                    primary_object_type(index) = ...
                        textField(object, "type");

                    primary_object_cs_m_s(index) = ...
                        numericField(object, "cs_m_s");

                    primary_object_radius_m(index) = ...
                        numericField(object, "radius_m");
                end
            end
        end

        geometry_family(index) = ...
            geometryFamily(config);

        if isfield(config, "directions")
            direction_count(index) = ...
                numericField(config.directions, "count");

            requested_in_plane_count(index) = ...
                numericField( ...
                    config.directions, ...
                    "in_plane_count");

            if isfield(config.directions, "support")
                direction_support_type(index) = ...
                    textField( ...
                        config.directions.support, ...
                        "type");

                solid_angle_sr(index) = ...
                    numericField( ...
                        config.directions.support, ...
                        "solid_angle_sr");
            end
        end

        if medium_object_count(index) > 0
            object = firstObject(config.medium.objects);

            if isfield(object, "center_xz_m") && ...
                    isnumeric(object.center_xz_m) && ...
                    numel(object.center_xz_m) >= 2

                primary_object_center_x_m(index) = ...
                    double(object.center_xz_m(1));

                primary_object_center_z_m(index) = ...
                    double(object.center_xz_m(2));
            end

            primary_object_normal_angle_rad(index) = ...
                numericField(object, "normal_angle_rad");

            primary_object_offset_m(index) = ...
                numericField(object, "offset_m");
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

    if isfile(summary_path(index))
        try
            summary_value = ...
                jsondecode(fileread(summary_path(index)));

            retained_direction_count(index) = ...
                numericField( ...
                    summary_value, ...
                    "retained_direction_count");

            if strlength(geometry_family(index)) == 0
                geometry_family(index) = ...
                    textField( ...
                        summary_value, ...
                        "geometry_family");
            end

            if strlength(direction_support_type(index)) == 0
                direction_support_type(index) = ...
                    textField( ...
                        summary_value, ...
                        "direction_support_type");
            end

            if isnan(solid_angle_sr(index))
                solid_angle_sr(index) = ...
                    numericField( ...
                        summary_value, ...
                        "solid_angle_sr");
            end

            retained_in_plane_count(index) = ...
                numericField( ...
                    summary_value, ...
                    "retained_in_plane_count");

            retained_in_plane_fraction(index) = ...
                numericField( ...
                    summary_value, ...
                    "retained_in_plane_fraction");

            angular_entropy(index) = ...
                numericField( ...
                    summary_value, ...
                    "angular_entropy");

            angular_effective_bins(index) = ...
                numericField( ...
                    summary_value, ...
                    "angular_effective_bins");

            radial_entropy(index) = ...
                numericField( ...
                    summary_value, ...
                    "radial_entropy");

            radial_effective_bins(index) = ...
                numericField( ...
                    summary_value, ...
                    "radial_effective_bins");
        catch
            % Keep unavailable summary values as NaN.
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
    design_id, ...
    condition_id, ...
    realization_id, ...
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
    primary_object_type, ...
    primary_object_cs_m_s, ...
    primary_object_radius_m, ...
    primary_object_center_x_m, ...
    primary_object_center_z_m, ...
    primary_object_normal_angle_rad, ...
    primary_object_offset_m, ...
    geometry_family, ...
    direction_count, ...
    retained_direction_count, ...
    direction_support_type, ...
    solid_angle_sr, ...
    requested_in_plane_count, ...
    retained_in_plane_count, ...
    retained_in_plane_fraction, ...
    angular_entropy, ...
    angular_effective_bins, ...
    radial_entropy, ...
    radial_effective_bins, ...
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


function family = geometryFamily(config)

family = "";

if ~isstruct(config) || ...
        ~isfield(config, "medium")
    return
end

medium = config.medium;

if ~isfield(medium, "objects") || ...
        isempty(medium.objects)
    family = "homogeneous";
    return
end

object = firstObject(medium.objects);
objectType = textField(object, "type");

switch objectType
    case "circle"
        family = "circular_inclusion";

    case "bilayer"
        family = "bilayer";

    otherwise
        family = objectType;
end

end


function object = firstObject(objects)

if iscell(objects)
    object = objects{1};
elseif isstruct(objects)
    object = objects(1);
else
    object = struct();
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
