function fig = plot_campaign(report, options)
%PLOT_CAMPAIGN Compare representative field-regime campaign wavefields.
%
%   plot_campaign(report)
%
% Uses realization 1 from the directional, intermediate, and diffuse
% conditions. Rows show ground-truth SWS, real(U), and |U|. Color limits are
% shared across regimes so the panels are directly comparable.

arguments
    report (1,1) struct
    options.RealizationId (1,1) double {mustBeInteger,mustBePositive} = 1
    options.SaveFigure (1,1) logical = true
end

regimes = ["directional", "intermediate", "diffuse"];
samples = cell(1, numel(regimes));
counts = zeros(1, numel(regimes));

for index = 1:numel(regimes)
    run = selectRun(report, regimes(index), options.RealizationId);
    sampleFile = fullfile(string(run.run_directory), ...
        "data", "wavefield_sample.mat");

    if ~isfile(sampleFile)
        error("examples:CampaignSampleNotFound", ...
            "wavefield_sample.mat not found for %s: %s", ...
            regimes(index), sampleFile);
    end

    loaded = load(sampleFile, "wavefield_sample");
    samples{index} = loaded.wavefield_sample;
    counts(index) = directionCount(samples{index});
end

truthLimits = sharedLimits(samples, "truth");
realLimit = sharedMaximum(samples, "real");
magnitudeLimit = sharedMaximum(samples, "magnitude");

fig = figure("Name", "Projected-3D field regimes", "Color", "w");
layout = tiledlayout(fig, 3, 3, ...
    "TileSpacing", "compact", "Padding", "compact");

title(layout, ...
    sprintf("Projected-3D inclusion: directional \rightarrow intermediate \rightarrow diffuse (realization %d)", ...
    options.RealizationId));

for column = 1:numel(regimes)
    sample = samples{column};
    xMm = 1e3 * double(sample.coordinates.x_m(:));
    zMm = 1e3 * double(sample.coordinates.z_m(:));
    U = double(sample.wavefield.data_zx);
    cs = double(sample.truth.cs_map_zx);

    ax = nexttile(layout, column);
    imagesc(ax, xMm, zMm, cs);
    axis(ax, "image");
    set(ax, "YDir", "reverse");
    clim(ax, truthLimits);
    colorbar(ax);
    title(ax, sprintf("%s, N=%d", regimes(column), counts(column)));
    if column == 1
        ylabel(ax, "SWS truth\nz (mm)");
    end

    ax = nexttile(layout, 3 + column);
    imagesc(ax, xMm, zMm, real(U));
    axis(ax, "image");
    set(ax, "YDir", "reverse");
    clim(ax, [-realLimit realLimit]);
    colorbar(ax);
    if column == 1
        ylabel(ax, "real(U)\nz (mm)");
    end

    ax = nexttile(layout, 6 + column);
    imagesc(ax, xMm, zMm, abs(U));
    axis(ax, "image");
    set(ax, "YDir", "reverse");
    clim(ax, [0 magnitudeLimit]);
    colorbar(ax);
    xlabel(ax, "x (mm)");
    if column == 1
        ylabel(ax, "|U|\nz (mm)");
    end
end

if options.SaveFigure
    outputDirectory = campaignDirectory(report);
    outputFile = fullfile(outputDirectory, "field_regime_comparison.png");
    exportgraphics(fig, outputFile, "Resolution", 200);
    fprintf("Saved comparison figure:\n%s\n", outputFile);
end

end

function run = selectRun(report, regime, realizationId)

if ~isfield(report, "runs") || isempty(report.runs)
    error("examples:CampaignReportMissingRuns", ...
        "The campaign report does not contain run records.");
end

conditions = string({report.runs.condition_id});
realizations = double([report.runs.realization_id]);
mask = conditions == regime & realizations == realizationId;

if nnz(mask) ~= 1
    error("examples:CampaignRunNotUnique", ...
        "Expected one %s run for realization %d; found %d.", ...
        regime, realizationId, nnz(mask));
end

run = report.runs(find(mask, 1));

if isfield(run, "status")
    status = string(run.status);
    if status ~= "completed" && status ~= "skipped_completed"
        error("examples:CampaignRunNotCompleted", ...
            "%s realization %d has status '%s'.", ...
            regime, realizationId, status);
    end
end

end

function count = directionCount(sample)

if isfield(sample, "directions") && isfield(sample.directions, "retained_count")
    count = double(sample.directions.retained_count);
elseif isfield(sample, "directions") && isfield(sample.directions, "xyz")
    count = size(sample.directions.xyz, 1);
else
    count = NaN;
end

end

function limits = sharedLimits(samples, quantity)

minimum = Inf;
maximum = -Inf;
for index = 1:numel(samples)
    switch quantity
        case "truth"
            values = double(samples{index}.truth.cs_map_zx);
        otherwise
            error("examples:UnknownPlotQuantity", ...
                "Unknown plot quantity: %s", quantity);
    end
    minimum = min(minimum, min(values(:)));
    maximum = max(maximum, max(values(:)));
end

if minimum == maximum
    padding = max(abs(minimum), 1) * 0.01;
    limits = [minimum-padding, maximum+padding];
else
    limits = [minimum, maximum];
end

end

function maximum = sharedMaximum(samples, quantity)

maximum = 0;
for index = 1:numel(samples)
    U = double(samples{index}.wavefield.data_zx);
    switch quantity
        case "real"
            values = abs(real(U));
        case "magnitude"
            values = abs(U);
        otherwise
            error("examples:UnknownPlotQuantity", ...
                "Unknown plot quantity: %s", quantity);
    end
    maximum = max(maximum, max(values(:)));
end

if maximum == 0
    maximum = 1;
end

end

function directory = campaignDirectory(report)

if isfield(report, "campaign_directory") && strlength(string(report.campaign_directory)) > 0
    directory = string(report.campaign_directory);
elseif isfield(report, "runs") && ~isempty(report.runs)
    directory = fileparts(string(report.runs(1).run_directory));
else
    error("examples:CampaignDirectoryUnknown", ...
        "Could not determine the campaign output directory.");
end

end
