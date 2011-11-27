%Calculates the outline of the gut for an arbitrary number of different 
function [] = outlineSeveralGuts()

%Read in the directories that contain the stacks that we're going to
%analyze

%Probably want to clean up this program a bit.
scanLoc = uigetfile_n_dir;

%Check to make sure that each of these directories has the valid structure
%for storing scan data from our microscope.

%Going through each directory

for numDir =1:length(scanLoc)
    param.directoryName = scanLoc{numDir};
    
    %Get the necessary information to register these images.
    
    %Outline and crop the gut by hand
    
    %Save the result.
    
    
end










end