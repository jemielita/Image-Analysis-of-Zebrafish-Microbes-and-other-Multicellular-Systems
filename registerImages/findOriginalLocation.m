%Calculate the location in the original image of the bacteri found in the
%rotated region

function pos= findOriginalLocation(param, cutNumber, scanNum, cutValAll, regFeatures)
[oI, rI, rHeight, rWidth] = getIndices(param, cutNumber, scanNum, cutValAll);


pos = [regFeatures{1}{cutNumber}{1}.Centroid];
pos = reshape(pos, 3,length(pos)/3);
pos = round(pos);

%rHeight = cutValAll{scanNum}{cutNumber,4}(1);
%rWidth = cutValAll{scanNum}{cutNumber,4}(2);

partInd = sub2ind([rWidth, rHeight], pos(1,:), pos(2,:));

[x,y] = ind2sub([rHeight, rWidth], rI);

oHeight = param.regionExtent.regImSize{1}(1);
oWidth = param.regionExtent.regImSize{1}(2);
%Map position to nearest point in our list of rotation points
for i=1:size(pos,2)
    comp = abs(x-pos(2,i));
    xInd = find(min(comp)==comp);
    
    comp = abs(y-pos(1,i));
    yInd = find(min(comp)==comp);
    
    ind = intersect(xInd, yInd); ind = ind(1);
    pos(2,i) = x(ind);
    pos(1,i) = y(ind);
    %Index of rotated and unrotated point
    pos(4,i) = ind;
    pos(5,i) = oI(ind);
    % x and y position in original frame
    [pos(6,i), pos(7,i)] = ind2sub([oHeight, oWidth], pos(5,i));
end





end

    function [oI, rI, rHeight, rWidth] = getIndices(param, cutNumber, scanNum,cutValAll)
        thisCut = cell(4,1);
        thisCut{1} = cutValAll{scanNum}{cutNumber,1};
        thisCut{2} = cutValAll{scanNum}{cutNumber,2};
        thisCut{3} = cutValAll{scanNum}{cutNumber,3};
        thisCut{4} = cutValAll{scanNum}{cutNumber,4};
        
        centerLine = param.centerLineAll{scanNum};
        
        %colorNum = find(strcmp(param.color, imVar.color));
        indReg = find(thisCut{2}==1);
        
        %Get z extent that we need to load in
        zList = param.regionExtent.Z(:, indReg);
        zList = zList>0;
        zList = sum(zList,2);
        minZ = find(zList~=0, 1, 'first');
        maxZ = find(zList~=0, 1, 'last');
        finalDepth = maxZ-minZ+1;
        
        %Get mask of gut
        height = param.regionExtent.regImSize{1}(1);
        width = param.regionExtent.regImSize{1}(2);
        polyX = param.regionExtent.polyAll{scanNum}(:,1);
        polyY = param.regionExtent.polyAll{scanNum}(:,2);
        gutMask = poly2mask(polyX, polyY, height, width);
        
        %fprintf(1, 'imOrig');
        %imOrig = nan*zeros(height, width, dataType);
        
        %Size of pre-cropped rotated image
        %imRotate = zeros(thisCut{4}(1), thisCut{4}(2), dataType);
        
        %Final image stack
        xMin =thisCut{4}(5); xMax = thisCut{4}(6);
        yMin = thisCut{4}(3); yMax = thisCut{4}(4);
        finalHeight = xMax-xMin+1;
        finalWidth = yMax-yMin+1;
        
        %im = nan*zeros(finalHeight, finalWidth, finalDepth, dataType);
        
        %fprintf(1, 'im big');
        %Crop down the mask to the size of the cut region
        maxCut = size(cutValAll{scanNum},1);
        
        cutPosInit = getOrthVect(centerLine(:,1), centerLine(:,2), 'rectangle', thisCut{1}(2));
        cutPosFinal = getOrthVect(centerLine(:,1), centerLine(:,2), 'rectangle', thisCut{1}(1));
        
        pos = [cutPosFinal(1:2,:); cutPosInit(2,:); cutPosInit(1,:)];
        
        cutMask = poly2mask(pos(:,1), pos(:,2), height, width);
        cutMask = cutMask.*gutMask;
        
        %Load in the entire volume
        %baseDir = [param.directoryName filesep 'Scans' filesep];
        %Going through each scan
        %scanDir = [baseDir, 'scan_', num2str(imVar.scanNum), filesep];
        
        %Find the indices to map the original image points onto the rotated image
        theta = thisCut{3};
        [oI, rI] = rotationIndex(cutMask, theta);
        
        [x,y] = ind2sub([thisCut{4}(1), thisCut{4}(2)], rI);

        ind = [find(x<xMin); find(x>xMax); find(y<yMin); find(y>yMax)];
        ind = unique(ind);
        x(ind) = []; y(ind) = []; oI(ind) = []; rI(ind) = [];
        x = x-xMin+1; y = y-yMin+1;
        rI = sub2ind([finalHeight, finalWidth], x,y);
        
        rHeight =finalHeight;
        rWidth = finalWidth;
    end
