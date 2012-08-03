% getrdist.m
%
% routine to get the radial intensity distribution of an image
% Distance calc'd from position (cm.x, cm.y) (px) of image (A)
% bins of size dr (pixels)
% A can be a 2D or 3D image
%
% Raghuveer Parthasarathy 
% 3 May 2004
% Generalize to 3D: Jan. 25, 2012
% last modified Jan. 25, 2012

function [rpos, rint] = getrdist(A, cm, dr)

Nbox = size(A);
Ndims = length(Nbox);

switch Ndims
    case 2
        iarray = repmat((1:Nbox(1))',1,Nbox(2));
        jarray = repmat(1:Nbox(2),Nbox(1),1);
        disarray = sqrt((iarray-cm.y).*(iarray-cm.y) + (jarray-cm.x).*(jarray-cm.x));
    case 3
        iarray = repmat((1:Nbox(1))',[1 Nbox(2) Nbox(3)]);
        jarray = repmat(1:Nbox(2),[Nbox(1) 1  Nbox(3)]);
        karray = repmat(reshape(1:Nbox(3),[1 1 Nbox(3)]), [Nbox(1) Nbox(2) 1]);
        disarray = sqrt((iarray-cm.y).*(iarray-cm.y) + ...
                        (jarray-cm.x).*(jarray-cm.x) + ...
                        (karray-cm.z).*(karray-cm.z));
    otherwise
        errordlg('Must be 2 or 3 dimensional')
end

mind = min(disarray(:));
maxd = max(disarray(:));
rpos = mind:dr:(maxd+dr);

Nint = zeros(size(rpos));
rint = zeros(size(rpos));
for j=1:length(disarray(:));
    index = floor((disarray(j)-mind)/dr)+1;
    rint(index) = rint(index) + A(j);
    Nint(index) = Nint(index)+1;
end
for i=1:length(rint),
    if (Nint(i) > 0), rint(i) = rint(i) / Nint(i);  end
end

% delete zero values
rpos(Nint==0)=[];
rint(Nint==0)=[];

