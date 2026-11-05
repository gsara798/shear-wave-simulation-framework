function [Tobs,Aobs,diag] = cachedTravelTime(speedZX,lossZX,x,z,source,obsY,opts,reference)
%CACHEDTRAVELTIME Lossless, frequency-independent Eikonal cache.
% One MAT file per physical source. Concurrent writes to the same source
% are unsupported: the orchestration must run fields serially.
arguments
    speedZX (:,:) double
    lossZX (:,:) double
    x (1,:) double
    z (:,1) double
    source (1,3) double
    obsY (1,1) double
    opts (1,1) struct
    reference (1,1) struct
end
assert(all(lossZX(:)==0),"swsynth:EikonalCacheLossless", ...
    "Cache supports nondispersive, lossless elastic media only.");
required=["directory","source_id","x_m","z_m","speed_zx"];
assert(all(isfield(reference,cellstr(required))), ...
    "swsynth:EikonalCacheReference");
rx=double(reference.x_m(:)');rz=double(reference.z_m(:));
rc=double(reference.speed_zx);
assert(isequal(size(rc),[numel(rz),numel(rx)]) && ...
    all(isfinite(rc(:)) & rc(:)>0), ...
    "swsynth:EikonalCacheReference");
dir=string(reference.directory);idx=double(reference.source_id);
assert(isscalar(idx) && idx>=1 && idx==floor(idx), ...
    "swsynth:EikonalCacheSource");
file=fullfile(dir,sprintf("source_%03d.mat",idx));
physics=struct("version",1,"source",source,"obsY",obsY, ...
    "reference_x",rx,"reference_z",rz,"reference_speed",rc, ...
    "GridSpacingM",double(opts.GridSpacingM), ...
    "MaxGridCells",double(opts.MaxGridCells), ...
    "MaximumIterations",double(opts.MaximumIterations), ...
    "ToleranceS",double(opts.ToleranceS));
if isfield(opts,"SpeedInterfacePlane")
    physics.SpeedInterfacePlane=opts.SpeedInterfacePlane;
end
if isfile(file)
    item=load(file,"physics","T_reference");
    assert(isfield(item,"physics") && isfield(item,"T_reference") ...
        && isequaln(item.physics,physics) ...
        && isequal(size(item.T_reference),size(rc)) ...
        && all(isfinite(item.T_reference(:))), ...
        "swsynth:EikonalCacheMismatch", ...
        "Cached travel times do not match the frozen physical specification: %s",file);
    referenceTime=item.T_reference;
    cacheStatus="hit";
else
    [referenceTime,refLoss,details]= ...
        swsynth.propagation.spherical.point_source.eikonal.solveExtended( ...
            rc,zeros(size(rc)),rx,rz,source,obsY,opts);
    assert(all(refLoss(:)==0) && all(isfinite(referenceTime(:))) ...
        && details.solver.converged,"swsynth:EikonalCacheInvalid");
    if ~isfolder(dir)
        assert(mkdir(dir),"swsynth:EikonalCacheDirectory");
    end
    % Write to an independent temporary file, publish only once complete.
    temp=fullfile(dir,sprintf("source_%03d_incomplete_%s.mat", ...
        idx,char(java.util.UUID.randomUUID)));
    cleanup=onCleanup(@()deleteIfExists(temp));
    T_reference=referenceTime; %#ok<NASGU>
    save(temp,"physics","T_reference","-v7.3");
    assert(movefile(temp,file,"f"),"swsynth:EikonalCacheWrite");
    clear cleanup
    cacheStatus="miss";
end
[Zo,Xo]=ndgrid(z,x);
% Same physical speed/source reference for every frequency and observation
% resolution. Interpolation is deterministic; never extrapolate.
assert(x(1)>=rx(1)-1e-12 && x(end)<=rx(end)+1e-12 ...
    && z(1)>=rz(1)-1e-12 && z(end)<=rz(end)+1e-12, ...
    "swsynth:EikonalCacheCoverage");
Tobs=interp2(rx,rz,referenceTime,Xo,Zo,"linear");
assert(all(isfinite(Tobs(:))),"swsynth:EikonalCacheInterpolation");
Aobs=zeros(size(Tobs));
diag=struct("model","cached_lossless_first_arrival", ...
    "cache_status",cacheStatus,"cache_file",file, ...
    "reference_sampling_m",[mean(diff(rx)),mean(diff(rz))], ...
    "source_xyz_m",source);
end

function deleteIfExists(file)
if isfile(file),delete(file);end
end
