%checkCodeVersion: Check to see if the code we're planning on running has been
%committed. Also record the current log revision number for future
%reference (will let us know if bugs creep into our code)
%
% USAGE: error = checkCodeVersion(codeDirectory, saveDirectory)
%
% INPUT codeDirectory: directory where the bzr directory for this code is stored
%       saveLogDirectory: location to save the current log as codeLog.m
% OUTPUT error: equals 1 if there was a problem recording the state of the
%        code, 0 otherwise.
% AUTHOR Matthew Jemielita, August 16, 2012

function error = checkCodeVersion(codeDirectory, saveLogDirectory)
error = 0;

currentDir = pwd;

cd(codeDirectory);

[status, revisionUpdated] = system('bzr diff');

if(~isempty(revisionUpdated))
   fprintf(2, 'Code has been changed since the last commit! \n Please committ code. \n');  
   error = 1;
end

[status, currentLog] = system('bzr log -r-1');

save([saveLogDirectory filesep 'codeLog.mat'],'currentLog')

cd(currentDir);
fprintf(1, 'Current code log saved!');

end