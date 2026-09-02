function result = run_example(options)
%RUN_EXAMPLE Run a true volumetric 3D synthetic example.

arguments
    options.ShowPlot (1,1) logical = true
end

example_root = fileparts(mfilename("fullpath"));
repo_root = fileparts(fileparts(fileparts(fileparts(example_root))));
addpath(fullfile(repo_root, "src"));
addpath(fullfile(repo_root, "examples"));

config_file = fullfile(example_root, "config.json");
config = jsondecode(fileread(config_file));
result = swsynth.run3D(config);

if options.ShowPlot
    sample = result.sample;
    U = sample.wavefield.data_zyx;
    cs = sample.truth.cs_map_zyx;
    y_index = round((size(U,2)+1)/2);

    figure(Name="Volumetric 3D synthetic example");
    tiledlayout(1,3);

    nexttile;
    imagesc(sample.coordinates.x_m*1e3, sample.coordinates.z_m*1e3, squeeze(cs(:,y_index,:)));
    axis image; set(gca,"YDir","normal"); colorbar;
    xlabel("x (mm)"); ylabel("z (mm)"); title("SWS, central x-z slice");

    nexttile;
    imagesc(sample.coordinates.x_m*1e3, sample.coordinates.z_m*1e3, real(squeeze(U(:,y_index,:))));
    axis image; set(gca,"YDir","normal"); colorbar;
    xlabel("x (mm)"); ylabel("z (mm)"); title("Real(U), central x-z slice");

    nexttile;
    imagesc(sample.coordinates.x_m*1e3, sample.coordinates.z_m*1e3, abs(squeeze(U(:,y_index,:))));
    axis image; set(gca,"YDir","normal"); colorbar;
    xlabel("x (mm)"); ylabel("z (mm)"); title("|U|, central x-z slice");
end
end
