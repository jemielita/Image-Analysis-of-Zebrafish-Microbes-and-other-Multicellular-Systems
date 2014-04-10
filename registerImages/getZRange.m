%getZRange: For a given cropping rectangle in the gut, find the range of z
%value that this rectangle will span
%
% USAGE [zList, totalZ, zRange] = getZRange(param, cropRect)
%
% AUTHOR Matthew Jemielita, April 2, 2014

function [zList, totalZ,zRange] = getZRange(param, loadType, loadVariable)

switch loadType
    case 'region'
        regNum = loadVariable;
        zList = param.regionExtent.Z(param.regionExtent.Z(:,regNum)~=-1,regNum);
        totalZ = size(zList,1);
        zRange(1) = find(param.regionExtent.Z(:,regNum)~=-1, 1, 'first');
        zRange(2) = find(param.regionExtent.Z(:,regNum)~=-1, 1, 'last');
    case 'multipleRegions'
        regNum = loadVariable;
        zList = param.regionExtent.Z(:,regNum);
        zList = zList>0;
        zList = sum(zList,2);

        zRange(1) = find(zList~=-1, 1, 'first');
        zRange(2) = find(zList~=-1, 1, 'last');
        totalZ = zRange(2)-zRange(1)+1;        
        
    case 'cropRect'
        cropRect = loadVariable;
        totalNumRegions = size(param.regionExtent.XY{1},1);
        [regList, overlap] = regionOverlap(param, cropRect);
        regList = ismember(1:totalNumRegions, regList);
        zList = param.regionExtent.Z(:,regList);
        zList = zList>(-1);
        zList = sum(zList,2);

        zRange(1) = find(zList~=-1, 1, 'first');
        zRange(2) = find(zList~=-1, 1, 'last');
        totalZ = zRange(2)-zRange(1)+1;
end

end