% Function which analyzes movies of gut motility. It first (optionally)
% deconstructs sets of multipage tiffs, then runs the PIVLab software to
% obtain velocity fields. In the future, it should also analyze the data.
%
% Notes: -Directory structure should be mainDirectory->fish->sets->DeconstructedImages
%        -Many more PIV settings can be input, add to the variable settings
%        if desired
%
% To do: User choice of which processes to run should be one box, not three
%        User defined contrast for video
%        tRegCell full cell array

function gutMotilitySingle

%% Prompt user for main directory, which processes to run, initialize variables
mainDirectory=uigetdir(pwd,'Directory containing fish sets to analyze'); %directory containing the images you want to analyze
deconChoice = menu('Would you like to deconstruct sets of multipage tiffs?','Yes','No (already done)');
PIVChoice = menu('Would you like to run the PIV tracking?','Yes','No (already done)');
analysisChoice = menu('Would you like to analyze the data?','Yes','No (already done)');
interpChoice = menu('Would you like to generate a mesh and interpolate the data?','Yes','No (already done)');
videoChoice = menu('Would you like to create a video?','Yes','No (already done)');

% Prompt user for variables
dlgAns=inputdlg({'What image format would you like to save as: *.tif or *.png?', ...
    'What smallest template size should be used (for first pass)?',...
    'What framerate are you using (frames/sec)?:',...
    'What scale will the final result be at (um/pix)?:'...
    'What (linear) factor would you like to reduce your image size by?:'}, 'Title',1,{'*.png','32','5','0.325','2'});

settings=dlgAns(1);
settings{2}=str2double(dlgAns(2));
fps=str2double(dlgAns(3));
scale=str2double(dlgAns(4));
resReduce=str2double(dlgAns(5));


% Initialize variables
subDir='DeconstructedImages';

% Go into directory (for ease of writing code)
cd(mainDirectory);
setDirect=dir;
setDirect(strncmp({setDirect.name}, '.', 1)) = []; % Removes . and .. and hidden files
setDirect=setDirect([setDirect.isdir]==1);
nSD=size(setDirect,1);
tRegCell={};
subFishDirect={};

%% Loop through fish directories to obtain masks
for i=1:nSD    
    
    if(deconChoice~=1) % Subsubdirectory already exists
        
        temp=dir(strcat(mainDirectory, filesep, setDirect(i).name, filesep));
        tempDirs=temp([temp.isdir]==1); % Takes only folders (not files)
        tempDirs(strncmp({tempDirs.name}, '.', 1)) = []; % Removes . and .. and hidden files
        subSubFishDirect=tempDirs.name;
        imPath=strcat(mainDirectory, filesep, setDirect(i).name, filesep, subSubFishDirect);
        filetype=settings{1};
        resReduce=-1;
        
    else % Just use first element of multipage tiff
        
        imPath=strcat(mainDirectory, filesep, setDirect(i).name);
        filetype='*.tif';
        
    end
    
    %initMask
    maskChoice=menu(strcat('Would you like to create a mask for files in directory:',imPath,'?'),'Yes','No (already done)');
    
    if(maskChoice==1)
        initMask(imPath,filetype,resReduce);
    end
    
end

filetype=settings{1};

%% Loop through directories for deconstructing tiffs

% Loop through sets
% Deconstruct tiffs if necessary
if(deconChoice==1)
    for i=1:nSD
        
        curDire=strcat(mainDirectory, filesep, setDirect(i).name, filesep);
        [subSubFishDirect, tRegCellTemp]=tiffStackDeconstruction(curDire,subDir,resReduce);
        tRegCell=[tRegCell;tRegCellTemp];
        
    end
    % Need the directory name where images are if they weren't created just now
else
    
    temp=dir(strcat(mainDirectory, filesep, setDirect(i).name, filesep));
    tempDirs=temp([temp.isdir]==1); % Takes only folders (not files)
    tempDirs(strncmp({tempDirs.name}, '.', 1)) = []; % Removes . and ..
    subSubFishDirect=tempDirs.name;
    
end

%% PIV tracking
if (PIVChoice==1)
    
    for i=1:nSD
        
        curDire=strcat(mainDirectory, filesep, setDirect(i).name, filesep, subSubFishDirect);
        PIVCallFunction(curDire, settings);
            
    end
    
end

%% Analysis
if (analysisChoice==1)
    for i=1:nSD
        
        imPath=strcat(mainDirectory, filesep, setDirect(i).name);
        
        if( interpChoice==1)
            
            % Initialize the gut mesh
            [gutMesh, mSlopes, x, y, u_filt, v_filt] = initMesh(imPath,subSubFishDirect);
            
            % Interpolate velocities from original grid onto gutMesh
            gutMeshVels=interpolateVelocities(gutMesh, x, y, u_filt, v_filt);
            
            % Get local coordinates (longitudinal, transverse)
            [gutMeshVelsPCoords, thetas] = mapToLocalCoords(gutMeshVels, mSlopes);
            
            % Save data!
            save(strcat(imPath,filesep,'analyzedGutData',date),'gutMesh','mSlopes','gutMeshVels','gutMeshVelsPCoords','thetas','tRegCell');
        else
            aGDName=dir(strcat(imPath,filesep,'analyzedGutData*.mat'));
            load(strcat(imPath,filesep,aGDName(1).name));
        end
        
        % Full path
        imPath=strcat(mainDirectory, filesep, setDirect(i).name, filesep, subSubFishDirect);
        
        % Analyze data
        analyzeGutData(gutMesh, gutMeshVels, gutMeshVelsPCoords, fps, scale, imPath)
        
        if( videoChoice==1)
            
            % Display a video of the motion
            displayGutVideo(gutMesh, gutMeshVels, gutMeshVelsPCoords, thetas, imPath, filetype)
            
        end
    end
end

end