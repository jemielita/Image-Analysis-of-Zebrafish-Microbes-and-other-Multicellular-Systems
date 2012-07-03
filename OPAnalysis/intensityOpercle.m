%Calculate the total intensity, mean intensity, and total volume for a time
%series of opercles.


function output = intensityOpercle(imDir, maskDir,maskRoot,maskBase, sMin, sMax)

output = zeros(sMax-sMin+1, 3);


imf = imfinfo([imDir filesep 'OP_Scan', sprintf('%03d',sMin), '.tif']); 

%imf = imfinfo([imDir sprintf('%03d',sMin), '.TIF']); 


zMax = size(imf,1);
im = zeros(imf(1).Height,imf(1).Width, zMax);

for sNum=sMin:sMax
    mask = load([maskDir filesep, maskRoot, sprintf('%03d', sNum), maskBase]);
    mask = mask.imT;
    
    for zNum=1:zMax
        im(:,:,zNum) = imread([imDir , filesep ,'OP_Scan', sprintf('%03d',sMax-1), '.tif'], 'Index', zNum);
    end
    
    mask = mask>0;
    index = find(mask==1);
    vol = length(index);
    
    inFish = im(index);
    
  %  inFish(~mask) = 0;%Remove pixels that we didn't consider to be in the fish

    
    output(sNum,1) = sum(inFish(:));
    output(sNum,2) = mean(inFish(:));
    output(sNum,3) = vol;
    
    fprintf(2,'.');
end
fprintf(2, '\n');




end