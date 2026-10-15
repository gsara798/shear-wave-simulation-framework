function positions = generate(request)
%GENERATE Place physical sources on a circle/annulus in an x-z plane.
% Request must have passed positions.validateRequest.
n=request.count;
if request.method=="fibonacci"
    u=((0:n-1)'+0.5)/n;
else
    if isfield(request,"stream") && ~isempty(request.stream)
        u=rand(request.stream,n,1);
    else
        u=rand(n,1);
    end
end
if request.support.type=="cone"
    axis=request.support.axis_xyz;
    centerAngle=atan2(axis(3),axis(1));
    angle=centerAngle+(2*u-1)*deg2rad(request.support.half_angle_deg);
else
    % On a circle, deterministic equal-angle spacing is the 2D analogue
    % of the Fibonacci sphere's approximately uniform angular placement.
    angle=2*pi*u;
end
r=swsynth.sources.positions.sampleRadii(request,2);
center=request.center_xyz_m;
positions=[center(1)+r.*cos(angle), ...
    repmat(center(2),n,1),center(3)+r.*sin(angle)];
positions=swsynth.sources.positions.planar2d.validate( ...
    positions,n,request.observation_y_m);
end
