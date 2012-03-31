%Script to cycle through a set of opercle images, and save them to a new
%directory, but lacking the directory structure.
%Will be used to load images into Hyugens. Images will also be cropped.

function []= flattenDir(rect)

imDir = uigetdir(pwd, 'Load images from this directory');

outDir = uigetdir(imDir, 'Location to save the images');
minN = 0;
maxN = 50;

minScan = 1;
maxScan = 144;
color = '488nm';
region = 'region_1';

im = zeros(634, 523, maxN-minN+1);

fprintf(2,'cropping and moving the images');
    
for scanN=minScan:maxScan
    fprintf(2, 'Scan:  %d \n', scanN);

    filename = sprintf('OP_Scan%03d.tif',scanN); 
    filename = [outDir, filesep, filename];
    
    for imN=minN:maxN
       imF = [imDir,filesep,'scan_', num2str(scanN), filesep, region, filesep,...
           color, filesep, 'pco', num2str(imN), '.tif'];
       temp = imread(imF);
       temp = imcrop(temp, rect);
       imwrite(temp, filename, 'writemode', 'append');       
    end
 
end





end