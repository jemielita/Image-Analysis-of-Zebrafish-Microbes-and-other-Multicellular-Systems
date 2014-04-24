%checkCodeVersion: Check to see if the code we're planning on running has been
%committed. Also record the current log revision number for future
%reference (will let us know if bugs creep into our code)
%
% USAGE: error = checkCodeVersion(codeDirectory, saveDirectory)
%
% INPUT codeDirectory: directory where the bzr directory for this code is stored
%       saveLogDirectory: location to save the current log as codeLog.m
%       displayLog (optional, default ==false). If true then don't save the
%       code log to a file and instead print out the result.
% OUTPUT error: equals 1 if there was a problem recording the state of the
%        code, 0 otherwise.
% AUTHOR Matthew Jemielita, August 16, 2012

function error = checkCodeVersion(codeDirectory, saveLogDirectory, varargin)

switch nargin
    case 2
        displayLog = false;
    case 3
        displayLog = varargin{1};
    otherwise
        fprintf(2, 'checkCodeVersion either takes 2 or 3 inputs!\n');
        return;
end

error = 0;

currentDir = pwd;

cd(codeDirectory);

[status, revisionUpdated] = system('bzr diff');

if(~isempty(revisionUpdated))
   fprintf(2, 'Code has been changed since the last commit! \n Please committ code. \n');  
   error = 1;
end

[status, currentLog] = system('bzr log -r-1');


switch displayLog
    case true
        fprintf(1, currentLog);
    case false
        save([saveLogDirectory filesep 'codeLog.mat'],'currentLog')
        cd(currentDir);
        fprintf(1, 'Current code log saved!');

end

end