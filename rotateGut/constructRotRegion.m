%constructRotRegion: For a given fish and region of rotated gut return the
%rotated image stack and rotated regions that we will use for analysis.
%
%USAGE [imStack, rotCenterLine, rotMask] = constructRotRegion(regNum,
%scanNum, color, param)
%
%INPUT: cutNum: region in the optimally cut gut to load
%       scanNum: scan number to load
%       color: color to load (ex. '488nm', '568nm'
%       param: structure with experimental parameters
%       
%OUTPUT: imStack: 3D stack containing rotated gut
%        rotCenterLine: points that pass through the center of the rotated
%        gut
%        rotMask: region masks that will be used to calculate the intensity
%        at different points along the center line
%
%AUTHOR: Matthew Jemielita, August 1, 2012

function [imStack, rotCenterLine, rotMask] = constructRotRegion(cutNum,...
scanNum, color, param)

%Quality check inputs
cutVal = param.cutVal;

%% Load in image stack 
fprintf(1, 'Loading in image stack...');
imVar.color = color;
imVar.zNum = ''; 
imVar.scanNum = scanNum;
loadType = 'multiple'; %To return optimal cut.

%Loading in images as double.
imStack = load3dVolume(param, imVar, loadType, cutNum);
fprintf(1,'...done!\n');

%% Calculate rotated center line
centerLine = param.centerLine;

rotCenterLine = getRotatedLine(centerLine, cutVal, cutNum);

%% Calculate rotated masks

%Get mask of rotated gut
height = param.regionExtent.regImSize{1}(1);
width = param.regionExtent.regImSize{1}(2);

poly = param.regionExtent.poly;
gutMask = poly2mask(poly(:,1), poly(:,2), param.regionExtent.regImSize{1}(1),...
    param.regionExtent.regImSize{1}(2));

%Rotate the  mask
xMin =cutVal{cutNum, 4}(5); xMax = cutVal{cutNum,4}(6);
yMin = cutVal{cutNum,4}(3); yMax = cutVal{cutNum,4}(4);

theta = cutVal{cutNum,3};

gutMask = imrotate(gutMask,theta);
gutMask = gutMask(xMin:xMax,yMin:yMax);

initPos = 2; finalPos = size(rotCenterLine,1)-1;
cutPosInit = getOrthVect(rotCenterLine(:,1), rotCenterLine(:,2), 'rectangle', finalPos);
cutPosFinal = getOrthVect(rotCenterLine(:,1), rotCenterLine(:,2), 'rectangle', initPos);

pos = [cutPosFinal(1:2,:); cutPosInit(2,:); cutPosInit(1,:)];

cutMask = poly2mask(pos(:,1), pos(:,2), size(gutMask,1), size(gutMask,2));
cutMask = cutMask.*gutMask;


rotMask = curveMask(cutMask, rotCenterLine, param,'rectangle');
% 
% 
% figure; imshow(sum(rotMask,3))
% hold on
% plot(rotCenterLine(:,1), rotCenterLine(:,2), '*');
% maxIm = max(imStack,[],3);


%% Set all points outside the gut mask to be NaN
outsideMask = ~cutMask;
fprintf(1, 'Setting region outside gut to NaN.');
for i=1:size(imStack,3)
    temp = imStack(:,:,i);
    temp(outsideMask) = NaN;
    imStack(:,:,i) = temp;
    fprintf(1, '.');
end
fprintf(1, '\n');

end

function rotCenterLine = getRotatedLine(centerLine, cutVal, cutNum)

%Cut down the size of the center line
centerLine = centerLine(cutVal{cutNum,1}(1):cutVal{cutNum,1}(2),:);

theta = -deg2rad(cutVal{cutNum,3});
rotMat = [cos(theta), -sin(theta); sin(theta), cos(theta)];

rotCenterLine = rotMat*centerLine';

rotCenterLine = rotCenterLine';


rotCenterLine(:,1) = rotCenterLine(:,1) -cutVal{cutNum,4}(3);
rotCenterLine(:,2) = rotCenterLine(:,2) - cutVal{cutNum,4}(5);
end