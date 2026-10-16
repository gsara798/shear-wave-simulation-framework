function D=sampleDirections(spec,geometry)
%SAMPLEDIRECTIONS Deterministic 2D angular / 3D Fibonacci direction sets.
% count_in_plane denotes an exact number on the x-z great circle, not
% physical point sources. Remaining directions lie on the unit sphere.
arguments
    spec (1,1) struct
    geometry (1,1) string
end
required=["count","method","support"];
for f=required
    if ~isfield(spec,f)
        error("swsynth:InvalidDirectionSampling","Missing sampling.%s.",f);
    end
end
allowed=["count","count_in_plane","method","support"];
if ~isempty(setdiff(string(fieldnames(spec)),allowed))
    error("swsynth:InvalidDirectionSampling","Unsupported sampling field.");
end
n=double(spec.count);
if ~isscalar(n)||~isfinite(n)||n<1||n~=fix(n)
    error("swsynth:InvalidDirectionSampling","count must be positive integer.");
end
ni=0;
if isfield(spec,"count_in_plane")
    ni=double(spec.count_in_plane);
end
if ~isscalar(ni)||~isfinite(ni)||ni<0||ni~=fix(ni)||ni>n
    error("swsynth:InvalidDirectionSampling","count_in_plane must be between 0 and count.");
end
method=string(spec.method);
support=string(spec.support);
if ~isscalar(method)||~isscalar(support)
    error("swsynth:InvalidDirectionSampling","method and support must be scalar.");
end
if geometry=="2d"
    if method~="uniform_circle" || ni~=n
        error("swsynth:InvalidDirectionSampling", ...
            "2d requires uniform_circle and count_in_plane=count.");
    end
    if ~ismember(support,["full_circle","forward_half_circle"])
        error("swsynth:InvalidDirectionSampling","Unsupported 2d support.");
    end
    span=2*pi;
    if support=="forward_half_circle";span=pi;end
    a=-span/2+span*(0:n-1)'/n;
    D=[cos(a),zeros(n,1),sin(a)];
else
    if method~="fibonacci" || support~="full_sphere"
        error("swsynth:InvalidDirectionSampling", ...
            "3d requires fibonacci and full_sphere.");
    end
    no=n-ni;
    D=zeros(n,3);
    if ni>0
        a=2*pi*(0:ni-1)'/ni;
        D(1:ni,:)=[cos(a),zeros(ni,1),sin(a)];
    end
    if no>0
        j=(0:no-1)';
        yy=1-2*(j+0.5)/no;
        theta=pi*(3-sqrt(5))*j;
        r=sqrt(max(0,1-yy.^2));
        D(ni+1:end,:)=[r.*cos(theta),yy,r.*sin(theta)];
    end
end
end
