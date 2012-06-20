%Load a 3D volume of a particular region of the gut
%Note: need to optimize this for speed-this will likely be a bottleneck in
%much of our analysis.

function im = load3dVolume(param,imVar,regNum)

%Allocating a huge array for the entire image stack
colorNum =  find(strcmp(param.color, imVar.color));

%Getting a list of all the image to load in
zList = param.regionExtent.Z(find(param.regionExtent.Z(:,regNum)~=-1),regNum);
totalZ = size(zList,1);

im = zeros(param.regionExtent.XY{colorNum}(regNum,3),...
    param.regionExtent.XY{colorNum}(regNum,4),totalZ);

%Get the extent of this region
xOutI = param.regionExtent.XY{colorNum}(regNum,1);
xOutF = param.regionExtent.XY{colorNum}(regNum,3)+xOutI-1;

yOutI = param.regionExtent.XY{colorNum}(regNum,2);
yOutF = param.regionExtent.XY{colorNum}(regNum,4)+yOutI -1;

xInI = param.regionExtent.XY{colorNum}(regNum,5);
xInF = xOutF - xOutI +xInI;

yInI = param.regionExtent.XY{colorNum}(regNum,6);
yInF = yOutF - yOutI +yInI;

baseDir = [param.directoryName filesep 'Scans' filesep];
%Going through each scan
scanDir = [baseDir, 'scan_', num2str(imVar.scanNum), filesep];


for nZ = 1:totalZ 
    imNum = zList(nZ);

    imFileName = ...
        strcat(scanDir,  'region_', num2str(regNum),filesep,...
        param.color(colorNum), filesep,'pco', num2str(imNum),'.tif');
    try
        im(:,:,nZ)= imread(imFileName{1},'PixelRegion', {[xInI xInF], [yInI yInF]});
    catch
        disp('This image doesn't exist-fix up your code!!!!');
    end
end


end