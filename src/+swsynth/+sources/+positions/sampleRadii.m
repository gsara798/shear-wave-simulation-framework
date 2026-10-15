function r = sampleRadii(request, dimension)
%SAMPLERADII Radial placement: uniform area (d=2) or volume (d=3).
n=request.count;
range=request.radius_range_m;
if range(1)==range(2)
    r=repmat(range(1),n,1);
    return;
end
if request.method=="fibonacci"
    u=((0:n-1)'+0.5)/n;
else
    if isfield(request,"stream") && ~isempty(request.stream)
        u=rand(request.stream,n,1);
    else
        u=rand(n,1);
    end
end
r=(range(1)^dimension+ ...
    (range(2)^dimension-range(1)^dimension).*u).^(1/dimension);
end
