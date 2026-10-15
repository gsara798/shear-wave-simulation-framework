function unitXYZ = sampleUnitSphere(request)
%SAMPLEUNITSPHERE Angular placement of 3D physical source positions.
n=request.count;
if request.method=="fibonacci"
    index=(0:n-1)';
    u=(index+0.5)/n;
    phi=pi*(3-sqrt(5))*index;
else
    if isfield(request,"stream") && ~isempty(request.stream)
        u=rand(request.stream,n,1);
        phi=2*pi*rand(request.stream,n,1);
    else
        u=rand(n,1);
        phi=2*pi*rand(n,1);
    end
end
support=request.support;
if support.type=="cone"
    mu=1-u*(1-cosd(support.half_angle_deg));
else
    mu=1-2*u;
end
sine=sqrt(max(0,1-mu.^2));
if support.type=="cone"
    axis=double(support.axis_xyz(:));
    if abs(axis(3))<0.99
        tmp=[0;0;1];
    else
        tmp=[0;1;0];
    end
    e1=cross(tmp,axis);e1=e1/norm(e1);
    e2=cross(axis,e1);
    unitXYZ=mu*axis.'+(sine.*cos(phi))*e1.'+(sine.*sin(phi))*e2.';
else
    unitXYZ=[sine.*cos(phi),sine.*sin(phi),mu];
end
end
