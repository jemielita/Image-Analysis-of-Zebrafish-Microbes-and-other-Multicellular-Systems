% Function which converts an ordered set of multipage tiffs into an ordered
% set of tiff images, reduced by a resolution in x and y by resReduce, in 
% a subdirectory given by subDir
%
% To do:

function subDir = tiffStackDeconstruction(directory,subDir,resReduce)

%% Initialize variables
filenames={};
count=1; % Linear index that travels through all multipages monotonically

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

%% Loop through each element in array
warning('off','all') % WARNING: Removed annoying message about strip range
% Progress bar
progtitle = sprintf('Converting tif');
progbar = waitbar(0, progtitle);  % will display progress
for i=1:nF
    
    % Progress bar update
    waitbar(i/nF, progbar, ...
        strcat(progtitle, sprintf('f %d of %d', i, nF)));
    
    % Open file as 1/4th resolution
    image=imread(fullfile(filenames{i}.name), 'Index', filenames{i}.index,'PixelRegion', {[1 resReduce numCols], [1 resReduce numRows]}); % read images
    
    % Save as png in subDir
    iMO=i-1;
    fName=[directory, filesep, subDir, filesep, sprintf(strcat(filenameBase,'_%0',num2str(nDigits),'i.png'),iMO)];
    imwrite(image,fName,'PNG');
    
end
warning('on','all') % WARNING: Removed annoying message about strip range
close(progbar);

%% Delete all original files (Suppressed for now)

end