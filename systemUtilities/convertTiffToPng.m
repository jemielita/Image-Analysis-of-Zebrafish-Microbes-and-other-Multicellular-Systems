%convertTiffToPng: Convert every tiff in image in every subfolder to png
%
% USAGE: [] = convertTiffToPng(dir)
%
% INPUT: dir: directory to search through and find all TIFF image in all
%subdirectories.
%
% NOTE: original tiff image will be deleted when this script is run!
%
% AUTHOR: Matthew Jemielita, 8/22/2012

function [] = convertTiffToPng(thisDir)
currentDir = pwd;
cd(thisDir);
allFile = rdir('**\*.tif');

for i=1:length(allFile)
inFile = allFile(i).name;
im = imread(inFile);
im = uint16(im);
outFile = [inFile(1:end-4), '.png'];
imwrite(im, outFile);

delete(inFile);
fprintf(1, '.');
end

end