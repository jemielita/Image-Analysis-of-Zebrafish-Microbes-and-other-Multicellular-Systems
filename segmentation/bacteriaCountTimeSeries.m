%Get population growth curves for early time experiments
function [numBac, bacProp] =  bacteriaCountTimeSeries(param, varargin)

switch nargin
    case 1
        %Values found that minimize f-score for particular manually
        %annotated gut region.
        cullProp.radCutoff = 4;
        cullProp.minRadius = 2;
        cullProp.minInten = 229;
        cullProp.minArea = 10;
    case 2
        cullProp = varargin{1};
end

minS = 1;
maxS = param.expData.totalNumberScans;

cd(param.dataSaveDirectory);

for nS=minS:maxS
    %Load data
    spotLoc = load(['BacteriaCount', num2str(nS), '.mat']);
    spotLoc = spotLoc.spotLoc;
    
    numBac{nS} = [];
    for nR=1:length(spotLoc)
        rProp = spotLoc{nR};
        
        
        [gutMask, xOffset, yOffset] = getMask(param, nS, nR);
        
        



        rProp = cullFoundBacteria(rProp, gutMask, cullProp,xOffset, yOffset);
       
        numBac{nS} = [numBac{nS}, length(rProp)];
        
        bacProp{nS,nR} = rProp;
    end
    
    
    
   fprintf(1, '.'); 
end
fprintf(1,'\n');


end

function [gutMask, xOffset, yOffset] = getMask(param, nS,nR)

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




xOffset = param.regionExtent.indivReg(nS, nR, 1);
yOffset = param.regionExtent.indivReg(nS, nR,2);



end