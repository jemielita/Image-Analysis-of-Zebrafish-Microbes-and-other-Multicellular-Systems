%makeUnrotatedMask: Make a series of unrotated masks for different gut
%regions
%
% AUTHOR: Matthew Jemielita, March 20, 2014

function [] = makeUnrotatedMask(param)

maxS = length(param.regionExtent.polyAll);

for nS=1:maxS
    poly = param.regionExtent.polyAll{nS};
    imSize = param.regionExtent.regImSize{1};
    gutMask = poly2mask(poly(:,1), poly(:,2), imSize(1), imSize(2));
    
    cl = param.centerLineAll{nS};
    cM = curveMask(gutMask, cl,'', 'rectangle');
    
    save([param.dataSaveDirectory filesep 'masks' 'maskUnrotated_' num2str(nS) '.mat']);
    
end

end

