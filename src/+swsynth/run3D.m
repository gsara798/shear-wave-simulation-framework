function result = run3D(requestedConfig)
%RUN3D Compatibility entrypoint for legacy volumetric callers.
% New code may call swsynth.run(cfg) with observation.geometry=volumetric3d.
arguments
    requestedConfig (1,1) struct = swsynth.defaultConfig3D()
end
result = swsynth.run(requestedConfig);
end
