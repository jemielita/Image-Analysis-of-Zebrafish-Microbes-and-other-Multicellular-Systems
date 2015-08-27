%nameChanger

mainDirectory=uigetdir(pwd,'Directory containing fish sets to analyze'); %directory containing the images you want to analyze

% Initialize variables
subDir='DeconstructedImages';
fileType='.png';
nameToChan='QSTMXCorr_X_06_22_15_FX.png';
changeToNameOne='QSTMXCorr_';
changeToNameTwo='_02_05_15_F';

% Go into directory (for ease of writing code)
cd(mainDirectory);
fishDirect=dir;
fishDirect(strncmp({fishDirect.name}, '.', 1)) = []; % Removes . and .. and hidden files
fishDirect=fishDirect([fishDirect.isdir]==1);
nFD=size(fishDirect,1);
subFishDirect={};

for i=1:nFD
    
    % Find appropriate directory
    subDire=dir(fishDirect(i).name);
    % subDire(1:2)=[]; % Better below
    subDire(strncmp({subDire.name}, '.', 1)) = []; % Removes . and ..
    subFishDirect(i).name={subDire.name};
    nSFD=size(subFishDirect(i).name,2);
    
        for j=1:nSFD
            
%             temp=dir(strcat(mainDirectory, filesep, fishDirect(i).name, filesep, subFishDirect(i).name{1}, filesep));
%             tempDirs=temp([temp.isdir]==1); % Takes only folders (not files)
%             tempDirs(strncmp({tempDirs.name}, '.', 1)) = []; % Removes . and .. and hidden files
%             subSubFishDirect=tempDirs.name;
%             imPath=strcat(mainDirectory, filesep, fishDirect(i).name, filesep, subFishDirect(i).name{j}, filesep, subSubFishDirect);
              imPath=strcat(mainDirectory, filesep, fishDirect(i).name, filesep, subFishDirect(i).name{j}, filesep);
              midVent='MV';
              nameToChange=strcat(imPath,nameToChan);
              whichFish=fishDirect(i).name;
              whichFish(1:4)=[];
              changeToName=strcat(imPath,changeToNameOne,midVent(j),changeToNameTwo,whichFish,fileType);
              movefile(nameToChange, changeToName);
            
        end
    
end