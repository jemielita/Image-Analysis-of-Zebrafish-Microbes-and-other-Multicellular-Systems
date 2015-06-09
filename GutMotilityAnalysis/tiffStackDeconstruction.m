% Function which converts an ordered set of multipage tiffs into an ordered
% set of tiff images, reduced by a resolution in x and y by resReduce, in 
% a subdirectory given by subDir
%
% To do:
%       Remove 8 bit optimization during registration

function [subDir, tRegCell] = tiffStackDeconstruction(directory,subDir,resReduce)

%% Initialize variables
filenames={};
count=1; % Linear index that travels through all multipages monotonically
regReduce=8;
sizeToSearch=regReduce*resReduce/2;
tRegCell={};

% Create directory
mkdir([directory, filesep, subDir]);

% Obtain multipages
setStacks=dir([directory, filesep, '*.tif']);
nSS=size(setStacks,1);
filenameBase=setStacks(1).name;
filenameBase(end-3:end)=[]; % Removes the .tif at the end

% Loop through multipages
for i=1:nSS
    
    % Put all image names and locations into one array
    info = imfinfo([directory filesep setStacks(i).name]);
    nI=size(info,1);
    for j=1:nI
       
        filenames{count}.name = info.Filename;
        filenames{count}.index = j;
        
        count = count+1;
    end
    
end

% Image properties
nF=size(filenames,2);
numCols = info(1).Height;
numRows = info(1).Width;
nDigits=numel(num2str(nF));

% Registration variables
% Get mask variables for registration
maskVars=dir(strcat(directory,filesep,'maskVars*.mat'));
maskFile=strcat(directory,filesep,maskVars(1).name);
load(maskFile);

% Get first image for registration
firstIm=imread(fullfile(filenames{1}.name), 'Index', filenames{1}.index,'PixelRegion', {[1 resReduce numCols], [1 resReduce numRows]}); % read images
firstIm=im2uint8(firstIm);
firstImReg=imread(fullfile(filenames{1}.name), 'Index', filenames{1}.index,'PixelRegion', {[1 regReduce numCols], [1 regReduce numRows]});
firstImReg=im2uint8(firstImReg);

% Mask parameters
x=size(firstIm,1);
y=size(firstIm,2);
r=x;
c=y;
arr=repmat((1:r)',1,c);
see=repmat(1:c,r,1);
psIn=inpolygon(see(:),arr(:),gutOutlinePoly(:,1),gutOutlinePoly(:,2));
logicPsIn = reshape(psIn,size(see));

% Initialize registration parameters
[optimizer, metric] = imregconfig('monomodal');

%% Loop through each element in array
warning('off','all') % WARNING: Removed annoying message about strip range

% Progress bar
progtitle = sprintf('Converting tif');
progbar = waitbar(0, progtitle);  % will display progress

for i=1:nF
    
    % Progress bar update
    waitbar(i/nF, progbar, ...
        strcat(progtitle, sprintf('f %d of %d', i, nF)));
    
    % Open file as 1/(resReduce)th resolution, lower bit depth
    image=imread(fullfile(filenames{i}.name), 'Index', filenames{i}.index,'PixelRegion', {[1 resReduce numCols], [1 resReduce numRows]}); % read images
%     image=im2uint8(image);
    
    % Open file as 1/(regReduce)th resolution, lower bit depth
    imageReg=imread(fullfile(filenames{i}.name), 'Index', filenames{i}.index,'PixelRegion', {[1 regReduce numCols], [1 regReduce numRows]}); % read images
%     imageReg=im2uint8(imageReg);
    
    % Do a rough registration (so large drift doesn't lead to mask failing)
    TReg = imregtform(imageReg,firstImReg,'rigid',optimizer,metric); % Find transform with masked image2
    % Rescale translation by regReduce/resReduce
    TRegFull = TReg;
    TRegFull.T(3,1:2)=regReduce/resReduce*TRegFull.T(3,1:2);
    % Move image by that amount 
%     image = imwarp(image,TRegFull,'OutputView',imref2d(size(firstIm))); % Actually do the transform with unmasked image
    image2 = imwarp(image,TRegFull,'OutputView',imref2d(size(firstIm))); % Actually do the transform with unmasked image
%     
%     % Mask gut, do fine registration using all other features
%     image2=image;
    imMat=image2(logicPsIn);
    image2(logicPsIn)=mean(imMat(:));
    TReg2=gutPolyRegistration(firstIm,image,image2,sizeToSearch);
    tRegCell=[tRegCell;TReg,TReg2];
    
    % Save as png in subDir
    iMO=i-1;
    fName=[directory, filesep, subDir, filesep, sprintf(strcat(filenameBase,'_%0',num2str(nDigits),'i.png'),iMO)];
    imwrite(image,fName,'PNG');
    
end
warning('on','all') % WARNING: Removed annoying message about strip range
close(progbar);

%% Delete all original files (Suppressed for now)

end