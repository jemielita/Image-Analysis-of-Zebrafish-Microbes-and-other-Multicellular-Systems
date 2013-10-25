%checkParameterFiles: Script to check input parameter, and scanParam
%variables to make sure the code will run correctly.
%This code will be in semi-constant flux as new fields are added as they
%cause a bug.


function [] = checkParameterFiles(param, scanParam)

%% Variables for comparing variables
numFish = length(param);

%% See if we have equal numbers of param and scanParam entries 
if(length(param)~=length(scanParam))
   fprintf(2, 'Parameter and scan parameters files not the same length!\n');
end

%% Check to make sure directories exist
for nF=1:numFish
    if(~isdir(param{nF}.dataSaveDirectory))
        fprintf(2, ['Fish ', num2str(nF), '  : Save directory does not exist!\n']);
    end
    
    if(~isdir(param{nF}.directoryName))
        fprintf(2, ['Fish ', num2str(nF), '  : Data directory does not exist!\n']);
    end
    
end

%% Check to make sure the scan list doesn't go beyond bounds


for nF =1:numFish
   if(max(scanParam{nF}.scanList)>param{nF}.expData.totalNumberScans)
      fprintf(2, ['Fish ', num2str(nF), ': Total number of scans exceeded!\n']);
   end
       
end



