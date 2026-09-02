function fig = plotFieldCrossplanes(sample, options)
arguments
    sample (1,1) struct
    options.Visible (1,1) string = "off"
end
fig = simviz.plotVolumetricCrossplanes(sample, "field_real", Visible=options.Visible);
end
