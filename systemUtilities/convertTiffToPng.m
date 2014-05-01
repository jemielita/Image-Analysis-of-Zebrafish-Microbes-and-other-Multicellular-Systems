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

%Get names of all files
fN = ['**' filesep '*.tif'];
allFile = rdir(fN);


%Converting all files
for i=1:length(allFile)
inFile = allFile(i).name;

%If we don't know a priori if the image is a single TIFF or a multipage
%TIFF-test it.
info = imfinfo(inFile);

if(size(info,1)==1)
    im = imread(inFile);
    im = uint16(im);
    outFile = [inFile(1:end-4), '.png'];
    imwrite(im, outFile);
elseif(size(info,1)>1)
    fprintf(2, 'No support for multipage png! Not converting this image.\n');
    continue;
    
else
    fprintf(2, ['Problem reading ', inFile '!']);
end
    
delete(inFile);
fprintf(1, '.');
if(mod(i,100)==0)
   fprintf(1, '\n'); 
end

end

end