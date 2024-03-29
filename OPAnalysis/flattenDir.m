%Script to cycle through a set of opercle images, and save them to a new
%directory, but lacking the directory structure.
%Will be used to load images into Hyugens. Images will also be cropped.

function []= flattenDir(varargin)

loadSeries =1; %Default to load from our type of directory structure.
if nargin==1
    imDir = uigetdir(pwd, 'Load images from this directory');
    
    outDir = uigetdir(imDir, 'Location to save the images');
elseif nargin ==2
    loadSeries =varargin{2};
    %If LoadSeries ==1, then load from our type of diretory structure, if
    %loadseries ==0, then load from tiff stacks.
    imDir = uigetdir(pwd, 'Load images from this directory');
    
    outDir = uigetdir(imDir, 'Location to save the images');
    nameRoot = 'sp7_80_percent_w1Yoko GFP_s5_t';
elseif nargin==3
    imDir = varargin{2};
    outDir = varargin{3};
    
elseif nargin==4
    imDir = varargin{2};
    outDir = varargin{3};
    param = varargin{4};%For doing things with our bacteria images
end

rect = varargin{1};


totalNumRegions = length(unique([param.expData.Scan.region]));
totalNumScans = param.expData.totalNumberScans;
totalNumColors = size(param.color,2);

%Create a new directory structure if necessary
if(~strcmp(cropDir, param.directoryName))
    for nS=1:totalNumScans
        for nR = 1:totalNumRegions
            for nC = 1:totalNumColors
                dirName = [cropDir filesep 'Scans' filesep 'scan_', num2str(nS), filesep ...
                    'region_', num2str(nR), filesep param.color{nC}];
                if(~isdir(dirName))
                    mkdir(dirName);
                end
                
            end
        end
    end
end




minN = 0;
maxN = 50;

minScan = 1;
maxScan = 1;
color = '488nm';
region = 'region_1';

im = zeros(634, 523, maxN-minN+1);

fprintf(2,'cropping and moving the images');
    
for scanN=minScan:maxScan
    fprintf(2, 'Scan:  %d \n', scanN);

    filename = sprintf('OP_Scan%03d.tif',scanN); 
    filename = [outDir, filesep, filename];
    
    for imN=minN:maxN
        if loadSeries ==1
            imF = [imDir,filesep,'scan_', num2str(scanN), filesep, region, filesep,...
                color, filesep, 'pco', num2str(imN), '.tif'];
            temp = imread(imF);
        elseif loadSeries ==0
            imF = [imDir, filesep, nameRoot, sprintf('%03d', scanN), '.TIF'];
            temp = imread(imF, imN);
        end
        temp = imcrop(temp, rect);
        imwrite(temp, filename, 'writemode', 'append');
    end
 
end





end