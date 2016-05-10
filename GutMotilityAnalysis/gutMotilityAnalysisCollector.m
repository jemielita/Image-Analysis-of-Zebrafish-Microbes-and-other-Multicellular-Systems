function gutMotilityAnalysisCollector( varargin )

    if( nargin < 1 )
        mainDirectory = uigetdir( pwd, 'Main directory containing fish to analyze' );
    else
        mainDirectory = varargin{ 1 };
    end
    
    subDir = 'DeconstructedImages';
    subSubDir = 'Data';
    fishDirect=dir;
    fishDirect(strncmp({fishDirect.name}, '.', 1)) = []; % Removes . and .. and hidden files
    nFD=size(fishDirect,1);
    subFishDirect={};
    params=[];
    
    %% Loop through fish directories
    for i=1:nFD
        
        % Find appropriate directory
        subDire=dir(strcat(mainDirectory,filesep,fishDirect(i).name));
        % subDire(1:2)=[]; % Better below
        subDire(strncmp({subDire.name}, '.', 1)) = []; % Removes . and ..
        subFishDirect(i).name={subDire.name};
        nSFD=size(subFishDirect(i).name,2);
        
        for j=1:nSFD
            
            filePath = strcat(mainDirectory,filesep,fishDirect(i).name,filesep,subDire(j).name,filesep,subDir,filesep,'Data');
            aGDName=dir(strcat(filePath,filesep,'analyzedGutData*.mat'));
            load(strcat(filePath,filesep,aGDName(1).name)); % DOUBLE CHECK
            
        end
        
    end

end