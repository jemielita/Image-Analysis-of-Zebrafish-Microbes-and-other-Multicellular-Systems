%For a given scan number and color, combine all the different regions
%together.

function im = registerSingleImage(varargin)
%Get the appropriate variables
switch nargin
    %We shoudl get rid of case 6-data is a useless variable
    case 6
        nScan = varargin{1};
        colorType = varargin{2};
        zNum = varargin{3};
        im = varargin{4};
        data = varargin{5};
        param = varargin{6};
        
    case 5
        nScan = varargin{1};
        colorType = varargin{2};
        zNum = varargin{3};
        im = varargin{4};
        param = varargin{5};
    case 4
        nScan = varargin{1};
        colorType = varargin{2};
        zNum = varargin{3};
        param = varargin{4};
        im = zeros(param.regionExtent.regImSize(1), param.regionExtent.regImSize(2));
end

totalNumRegions = length(unique([param.expData.Scan.region]));
%%Now loading in the images
%Base directory for image location
%baseDir = strcat(data.directory, filesep, 'Scans',filesep);
baseDir = [param.directoryName filesep 'Scans' filesep];
%Going through each scan
%scanDir = strcat(baseDir, data.scan(nScan).directory, filesep);
scanDir = [baseDir, 'scan_', num2str(nScan), filesep];
%And each color (in the debugging phase, we'll restrict ourselves
%to one color

imNum = param.regionExtent.Z(zNum,:);
%Load in the associated images

%Filling the input image with zeros, to be safe.
im(:) = 0;


im = uint16(im); %To match the input type of the images.
for regNum=1:totalNumRegions
    
    %Get the range of pixels that we will read from and read out to.
    xOutI = param.regionExtent.XY(regNum,1);
    xOutF = param.regionExtent.XY(regNum,3)+xOutI-1;
    
    yOutI = param.regionExtent.XY(regNum,2);
    yOutF = param.regionExtent.XY(regNum,4)+yOutI -1;
    
    xInI = param.regionExtent.XY(regNum,5);
    xInF = xOutF - xOutI +xInI;
    
    yInI = param.regionExtent.XY(regNum,6);
    yInF = yOutF - yOutI +yInI;
    
    
    if(imNum(regNum)~=-1)
        imFileName = ...
            strcat(scanDir,  'region_', num2str(regNum),filesep,...
            colorType, filesep,'pco', num2str(imNum(regNum)),'.tif');
        
        im(xOutI:xOutF,yOutI:yOutF) = imread(imFileName,...
            'PixelRegion', {[xInI xInF], [yInI yInF]}) + ...
            im(xOutI:xOutF,yOutI:yOutF);
        
        %         im(xOutI:xOutF,yOutI:yOutF) = imIn(xInI:xInF, yInI:yInF);
    end
    
end


for regNum = 2:totalNumRegions
    %Overlapping the regions
    %Overlapping regions
    %This is potentially slow (however we need to be as quick as possible with this type of thing).
    %After we know this code works, we'll come back and write quicker code.
    
    %Overlap for regNum>1
    if(imNum(regNum-1)>=0 &&imNum(regNum)>=0)
        im(param.regionExtent.overlapIndex{regNum-1} )= ...
            0.5*im(param.regionExtent.overlapIndex{regNum-1});
        %    im(:) =1;
        %   im(param.regionExtent.overlapIndex{regNum-1} ) = 0;
    end
    
end


end