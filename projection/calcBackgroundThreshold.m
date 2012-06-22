%Calculates the sum of the background pixel intensties assuming a certain
%threshold for the lower limit. Will be used to find an appropriate
%threshold to remove background pixel intensity.

function intenVal = calcBackgroundThreshold(fileDir, totNumRegions)
%Initially assume that we're going to do this for all the scans

%Make a location to save the data

color = {'488nm', '568nm'};
nS = 1;
intenVal = zeros(2,totNumRegions, 200,2);

for nR=1:totNumRegions
            
    for nC=1:2
        imVar.color =color{nC};
        imVar.zNum = '';%Won't need this for mip
        imVar.scanNum = 1;
        
            inputDirName = [fileDir, '_S',num2str(nS), 'nR', num2str(nR), ...
                '_', color{nC}, '.tif'];
            imInf = imfinfo(inputDirName);
                   imSize = [imInf(1).Height, imInf(1).Width]; 
                   numIm = size(imInf,1);
                   im = zeros(imSize(1), imSize(2), numIm);
                   for i=1:numIm
                       im(:,:,i) = imread(inputDirName, 'Index', i);
                   end
  
                   fprintf(2,'.');
                   for nT =1:200
                       index = find(im>nT);
                       intenVal(nC,nR, nT,1) = length(index);
                       intenVal(nC,nR,nT,2) = sum(im(index));
                       
                       if(length(index)<1000)
                           break
                       end
                       
                   end
                   fprintf(1,'.');
        end
    end



end