function H = extract_harmonic_field(U, dt, f0, varargin)
%EXTRACT_HARMONIC_FIELD Extract a complex phasor at f0 from time samples.
%
% U must be Nx-by-Nz-by-Nt. The returned H.phasor_xz is Nx-by-Nz and
% H.Uxz is Nz-by-Nx for direct use with adaptive_req.estimators.req_estimator_map.

p = inputParser;
p.FunctionName = 'adaptive_req.kwave.extract_harmonic_field';
addRequired(p, 'U', @(x) isnumeric(x) && ndims(x) == 3);
addRequired(p, 'dt', @(x) isnumeric(x) && isscalar(x) && x > 0);
addRequired(p, 'f0', @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(p, 'Cycles', 8, @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(p, 'DiscardCycles', 2, @(x) isnumeric(x) && isscalar(x) && x >= 0);
parse(p, U, dt, f0, varargin{:});

Nt = size(U, 3);
t = (0:(Nt - 1)) * dt;
period = 1 / f0;
t0 = max(p.Results.DiscardCycles * period, t(end) - p.Results.Cycles * period);
idx = find(t >= t0);

if numel(idx) < 8
    warning('Very few samples available for harmonic extraction (%d).', numel(idx));
    idx = 1:Nt;
end

phase = reshape(exp(-1i * 2*pi*f0*t(idx)), 1, 1, []);
phasor = 2 / numel(idx) * sum(double(U(:, :, idx)) .* phase, 3);

H = struct();
H.phasor_xz = phasor;
H.Uxz = phasor.';
H.sample_indices = idx(:);
H.t_window_s = [t(idx(1)), t(idx(end))];
H.n_samples = numel(idx);
H.f0 = f0;
H.dt = dt;

end
