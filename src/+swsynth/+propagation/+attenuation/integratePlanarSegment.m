function optical=integratePlanarSegment(p0,p1,plane)
%INTEGRATEPLANARSEGMENT Exact optical depth for a straight segment crossing
% one planar material boundary. Coordinates are xyz, normal_xyz unit length.
arguments
    p0 (:,3) double
    p1 (:,3) double
    plane (1,1) struct
end
if ~isequal(size(p0),size(p1))
    error("swsynth:InvalidPlanarAttenuation","Segment endpoints must match.");
end
required=["normal_xyz","offset_m","alpha_negative_np_m","alpha_positive_np_m"];
if ~all(isfield(plane,cellstr(required)))
    error("swsynth:InvalidPlanarAttenuation","Incomplete planar interface definition.");
end
n=double(plane.normal_xyz(:).');
if numel(n)~=3 || any(~isfinite(n)) || abs(norm(n)-1)>1e-8
    error("swsynth:InvalidPlanarAttenuation","Interface normal must have unit norm.");
end
offset=double(plane.offset_m);
aNeg=double(plane.alpha_negative_np_m);
aPos=double(plane.alpha_positive_np_m);
if any(~isfinite([offset,aNeg,aPos])) || any([aNeg,aPos]<0)
    error("swsynth:InvalidPlanarAttenuation","Invalid interface offset or loss.");
end
s0=p0*n.'-offset;
s1=p1*n.'-offset;
lengths=sqrt(sum((p1-p0).^2,2));
fracPositive=zeros(size(s0));
bothPos=s0>=0 & s1>=0;
bothNeg=s0<=0 & s1<=0;
fracPositive(bothPos)=1;
crossing=~bothPos & ~bothNeg;
if any(crossing)
    frac=abs(s0(crossing))./(abs(s0(crossing))+abs(s1(crossing)));
    startPositive=s0(crossing)>0;
    fracPositive(crossing)=frac.*startPositive+(1-frac).*(~startPositive);
end
optical=lengths.*(aNeg+(aPos-aNeg).*fracPositive);
end
