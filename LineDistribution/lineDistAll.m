% SUMMARY: Wrapper function that runs lineDist for all elements in the Data
% structure
%
% [data, param] = lineDistAll(data,param)
%
%INPUT: data-contains all the images that will be analyzed using a line
%distribution.
%       param-all relevant experimental/computational parameters.
%
%OUTPUT: -data now contains the result of the line distribution and is
%        stored in the same subdirectory as the original image as .lineDist
%        -param.labelMatrix-contains all the regions analyzed using the line
%        distribution
%        -param.numBoxes-number of boxes used by the line distribution.
% 
%USAGE: The user will be prompted with the lineDist GUI for the first image
%in the stack (in the future will make it possible to move between images).
%After selecting the desired region the program will run the line
%distribution code for all chosen regions.       

function [data,param] = lineDistAll(data,param)


im = data.scan(1).region(1).color(1).im;

%Using the interactive GUI on the first image.
[labelMatrix, lineProp] = lineDist(im);
%Saving these parameters
param.labelMatrix = labelMatrix;
param.numBoxes  = size(lineProp,1);

%Calculate the distance 

%Running through all of the regions (we'll do the region we did above
%again, in order to make the code cleaner and to make it possible to easily
%look at regions that aren't the 1st in the set.


for nScan=1:length(data.scan)
    %Going through each scan
    for nRegion=1:length(data.scan(nScan).region)
        %Going through each region in this scan
        for nColor=1:length(data.scan(nScan).region(nRegion).color)
            %and each color

            %Cropping each of these images
            im = data.scan(nScan).region(nRegion).color(nColor).im;
            [labelMatrix, lineProp] = lineDist(im, param.numBoxes, param.labelMatrix);
            
            data.scan(nScan).region(nRegion).color(nColor).lineProp = lineProp;
            
        end
    end
end

%Now calculating several features of this line distribution: the centroid
% to centroid distance between boxes and the total length of the regions analyzed.

init = lineProp(1).Centroid;
next = lineProp(2).Centroid;
final = lineProp(end).Centroid;

param.centroidDist = sum((init-next).^2).^0.5;
param.lengthDist = sum((init-final).^2).^0.5;




end