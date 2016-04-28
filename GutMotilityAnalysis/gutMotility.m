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
%        Inverse mask for registration

function gutMotility

%% Prompt user for main directory, which processes to run, initialize variables
mainDirectory=uigetdir(pwd,'Main directory containing fish to analyze'); %directory containing the images you want to analyze
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
fishDirect=dir;
% fishDirect(1:2)=[]; % Remove . and .., assumes ONLY directories here
fishDirect(strncmp({fishDirect.name}, '.', 1)) = []; % Removes . and .. and hidden files
fishDirect([fishDirect.isdir]==0) = []; % removes non-directories from list

% Allow user to select which fish to analyze
nameList = { fishDirect.name };
setFull = 1:size( nameList, 2 );
[ setKeep, ~ ] = listdlg( 'PromptString', 'Select Fish to Analyze', 'ListString', nameList );
setRemove = setdiff( setFull, setKeep ); % setdiff( A, B ) returns the data in A that is not in B
fishDirect( setRemove ) = [];
nFD=size(fishDirect,1);
subFishDirect={};
useFishBools = cell(1,nFD);

%% Loop through fish directories to obtain masks
for i=1:nFD
    
    % Find appropriate directory
    subDire=dir(fishDirect(i).name);
    % subDire(1:2)=[]; % Better below
    subDire(strncmp({subDire.name}, '.', 1)) = []; % Removes . and ..
    subFishDirect(i).name={subDire.name};
    nSFD=size(subFishDirect(i).name,2);
    
    
    for j=1:nSFD
        if(deconChoice~=1) % Subsubdirectory already exists
            
            temp=dir(strcat(mainDirectory, filesep, fishDirect(i).name, filesep, subFishDirect(i).name{1}, filesep));
            tempDirs=temp([temp.isdir]==1); % Takes only folders (not files)
            tempDirs(strncmp({tempDirs.name}, '.', 1)) = []; % Removes . and .. and hidden files
            subSubFishDirect=tempDirs.name;
            imPath=strcat(mainDirectory, filesep, fishDirect(i).name, filesep, subFishDirect(i).name{j}, filesep, subSubFishDirect);
            filetype=settings{1};
            resReduce=-1;
            
        else % Just use first element of multipage tiff
            
            imPath=strcat(mainDirectory, filesep, fishDirect(i).name, filesep, subFishDirect(i).name{j});
            filetype='*.tif';
            
        end
        
        %initMask
        if(i==1&&j==1)
            createMasks=menu(strcat('Would you like to create masks right now?: '),'Yes','No (already done)');
        end
        
        if(createMasks==1)
            maskChoice=menu(strcat('Would you like to create a mask for files in directory:',imPath,'?'),'Yes','No (already done)');
        else
            maskChoice=0;
        end
        
        if(maskChoice==1)
            initMask(imPath,filetype,resReduce);
        end
        
    end
    
end

filetype=settings{1};

%% Loop through directories for deconstructing tiffs
for i=1:nFD
    
    % Find appropriate directory
    subDire=dir(fishDirect(i).name);
    % subDire(1:2)=[]; % Better below
    subDire(strncmp({subDire.name}, '.', 1)) = []; % Removes . and ..
    subFishDirect(i).name={subDire.name};
    nSFD=size(subFishDirect(i).name,2);
    
    % Loop through sets
    % Deconstruct tiffs if necessary
    if(deconChoice==1)
        
        for j=1:nSFD
            
            curDire=strcat(mainDirectory, filesep, fishDirect(i).name, filesep, subFishDirect(i).name{j});
            subSubFishDirect=tiffStackDeconstruction(curDire,subDir,resReduce);
            
        end
    % Need the directory name where images are if they weren't created just now    
    else
        
        temp=dir(strcat(mainDirectory, filesep, fishDirect(i).name, filesep, subFishDirect(i).name{1}, filesep));
        tempDirs=temp([temp.isdir]==1); % Takes only folders (not files)
        tempDirs(strncmp({tempDirs.name}, '.', 1)) = []; % Removes . and ..
        subSubFishDirect=tempDirs.name;
        
    end
    
end

%% PIV tracking
if (PIVChoice==1)
    
    for i=1:nFD
        
        nSFD=size(subFishDirect(i).name,2);
        for j=1:nSFD
            
            curDire=strcat(mainDirectory, filesep, fishDirect(i).name, filesep, subFishDirect(i).name{j}, filesep, subSubFishDirect);
            PIVCallFunction(curDire, settings)
            
        end
        
    end
    
end

%% Analysis

% Progress bar
progtitle = sprintf('Analyzing fish n');
progbar = waitbar(0, progtitle);  % will display progress

for i=1:nFD
    
    % Progress bar update
    waitbar(i/nFD, progbar, ...
        strcat(progtitle, sprintf('umber %d of %d', i, nFD)));
    
    curFishBools = [];
    
    for j=1:nSFD
        
        imPath=strcat(mainDirectory, filesep, fishDirect(i).name, filesep, subFishDirect(i).name{j});
        
        if( interpChoice==1 )
            
            % Initialize the gut mesh
            [gutMesh, mSlopes, x, y, u_filt, v_filt] = initMesh(imPath,subSubFishDirect);
            
            % Interpolate velocities from original grid onto gutMesh
            gutMeshVels=interpolateVelocities(gutMesh, x, y, u_filt, v_filt);
            
            % Get local coordinates (longitudinal, transverse)
            [gutMeshVelsPCoords, thetas] = mapToLocalCoords(gutMeshVels, mSlopes);
            
            % Save data!
            save(strcat(imPath,filesep,'analyzedGutData',date),'gutMesh','mSlopes','gutMeshVels','gutMeshVelsPCoords','thetas');
        elseif(analysisChoice==1)
            aGDName=dir(strcat(imPath,filesep,'analyzedGutData*.mat'));
            load(strcat(imPath,filesep,aGDName(1).name));
        end
        
        % Full path
        imPath=strcat(mainDirectory, filesep, fishDirect(i).name, filesep, subFishDirect(i).name{j}, filesep, subSubFishDirect);
        
        if(analysisChoice==1)
            
            % Analyze data
            useFishBool = analyzeGutData(gutMesh, gutMeshVelsPCoords, fps, scale, imPath);
            curFishBools = [curFishBools, useFishBool]; %#ok
            
        end
        
        if( videoChoice==1)
            
            % Display a video of the motion
            displayGutVideo(gutMesh, gutMeshVels, gutMeshVelsPCoords, thetas, imPath, filetype)
            
        end
        
    end
    
    useFishBools{i} = curFishBools;
    
end

% Save data if analyzed! Won't be accurate if you break up your analysis (this currently sucks if files are individually analyzed)
if(analysisChoice==1)
    save(strcat(mainDirectory,filesep,'fishBools',date),'useFishBools'); % Be careful with this: the order is 1, 10, 11,... 2, 20, 21,... etc, and will skip over any fish folders missing from the directory
end

close(progbar);

end