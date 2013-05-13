%Overlap individual region with found bugs
%
%

function [] = overlapFoundBugs(param, nS, nR)

%
allZ = param.regionExtent.Z;
allZ = allZ>0;

maxZ = sum(allZ,1);

height = param.regionExtent.regImSize{1}(1);
width = param.regionExtent.regImSize{1}(2);

thisRegion = param.regionExtent.XY{1};
xOutI = thisRegion(nR,1);
xOutF = thisRegion(nR,3)+xOutI-1;

yOutI = thisRegion(nR,2);
yOutF = thisRegion(nR,4)+yOutI -1;

xInI = thisRegion(nR,5);
xInF = xOutF - xOutI +xInI;

yInI = thisRegion(nR,6);
yInF = yOutF - yOutI +yInI;

%Make gut masks

polyX = param.regionExtent.polyAll{nS}(:,1);
polyY = param.regionExtent.polyAll{nS}(:,2);
gutMask = poly2mask(polyX, polyY, height, width);
thisMask = gutMask(xOutI:xOutF, yOutI:yOutF);

%Find smallest cropping region
xMin = find(sum(thisMask,2)~=0,1,'first');
xMax = find(sum(thisMask,2)~=0, 1, 'last');

yMin = find(sum(thisMask,1)~=0, 1, 'first');
yMax = find(sum(thisMask,1)~=0, 1, 'last');

color = '488nm';

% Loading in images

fileDir = [param.directoryName filesep 'Scans' filesep 'scan_' num2str(nS) filesep...
'region_' num2str(nR) filesep color filesep ];
for nZ=1:maxZ(nR)
    
    temp = imread([fileDir, filesep, 'pco', num2str(nZ-1), '.tif'],...
            'PixelRegion', {[xInI xInF], [yInI yInF]});
   % temp = temp(xMin:xMax, yMin:yMax);

    temp(~thisMask)= 0;
    im(:,:,nZ) = temp;
    fprintf(1, '.');
end

%Load bacteria
bacCount = load([param.dataSaveDirectory filesep 'BacteriaCount', num2str(nS), '.mat']);
rProp = bacCount.spotLoc; rProp = rProp{nR};




xOffset = param.regionExtent.indivReg(nS, nR, 1);
yOffset = param.regionExtent.indivReg(nS, nR,2);



%Cull data
cullProp.radCutoff = 4;
cullProp.minRadius = 0;
cullProp.minInten = 0;
cullProp.minArea = 10;

rProp = cullFoundBacteria(rProp, thisMask, cullProp, xOffset, yOffset);

figure; imshow(max(im, [],3),[0 1000]);
hold on
for i=1:length(rProp)
    if(rProp(i).Area>100)
    plot(rProp(i).Centroid(1)+yOffset, rProp(i).Centroid(2)+xOffset, 'o', 'Color', [1 0 0],...
        'MarkerSize', 10);
    end
end


  for nZ = 1:maxZ(nR)
     close all
      figure;
      imshow(im(:,:,nZ),[0 1000]);
      hold on
      for i=1:length(rProp)
         if(abs(rProp(i).Centroid(3)-nZ)<1)
             if(rProp(i).Area<100)
                 plot(rProp(i).Centroid(1)+yOffset, rProp(i).Centroid(2)+xOffset, 'o', 'Color', [1 0 0],...
                'MarkerSize', 10);
             else
                 plot(rProp(i).Centroid(1)+yOffset, rProp(i).Centroid(2)+xOffset, 'o', 'Color', [0 0 1],...
                'MarkerSize', 10);
             end
                 
         end
   
      end
      pause
    
end


end