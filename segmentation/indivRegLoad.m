allZ = param.regionExtent.Z;
allZ = allZ>0;

maxZ = sum(allZ,1);

%Make gut masks for each subregion

height = param.regionExtent.regImSize{1}(1);
width = param.regionExtent.regImSize{1}(2);

for nS=1:44
    
%Make gut masks

polyX = param.regionExtent.polyAll{nS}(:,1);
polyY = param.regionExtent.polyAll{nS}(:,2);
gutMask = poly2mask(polyX, polyY, height, width);


for nR=1:4
    thisRegion = param.regionExtent.XY{1};
    xOutI = thisRegion(nR,1);
    xOutF = thisRegion(nR,3)+xOutI-1;
    
    yOutI = thisRegion(nR,2);
    yOutF = thisRegion(nR,4)+yOutI -1;
    xInI = thisRegion(nR,5);
    xInF = xOutF - xOutI +xInI;
    
    yInI = thisRegion(nR,6);
    yInF = yOutF - yOutI +yInI;
    
    thisMask = gutMask(xOutI:xOutF, yOutI:yOutF);
    %Find smallest cropping region 
    xMin = find(sum(thisMask,2)~=0,1,'first');
    xMax = find(sum(thisMask,2)~=0, 1, 'last');

    yMin = find(sum(thisMask,1)~=0, 1, 'first');
    yMax = find(sum(thisMask,1)~=0, 1, 'last');
    

    thisMask = thisMask(xMin:xMax, yMin:yMax);

    im = zeros(size(thisMask,1), size(thisMask,2), maxZ(nR));
    clear im;
    fprintf(1, 'Loading images');

fileDir = [param.directoryName filesep 'Scans' filesep 'scan_' num2str(nS) filesep...
'region_' num2str(nR) filesep '488nm' filesep ];

    for nZ=1:maxZ(nR)

        temp = imread([fileDir, filesep, 'pco', num2str(nZ-1), '.tif'],...
            'PixelRegion', {[xInI xInF], [yInI yInF]});
        temp = temp(xMin:xMax, yMin:yMax);
        temp(~thisMask) = NaN;
        im(:,:,nZ) = temp;
        fprintf(1, '.');
    end
    fprintf(1, '\n');

    spotLoc{nR} = countSingleBacteria(im, '', '', param);
    
end
saveName = ['BacteriaCount', num2str(nS), '.mat'];
save(saveName, 'spotLoc');

end