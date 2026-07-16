function [result, report] = run(cfg)
%RUN Execute the directional homogeneous 2D benchmark.
%
% [result, report] = ...
%     kwsim_benchmarks.directional_homogeneous_2d.run()
%
% A custom configuration may be supplied after obtaining it from config()
% or compactConfig().

arguments
    cfg struct = ...
        kwsim_benchmarks.directional_homogeneous_2d.config()
end

[result, report] = kwsim.two_d.run(cfg);

end
