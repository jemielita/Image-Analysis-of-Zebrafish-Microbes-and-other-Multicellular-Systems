%correlationGut: Calculate the radial correlation function down the length
%of the gut.
%
% USAGE: radCorr = correlationGut(im, regionMask, centerLine, subtractBkg, radStep,param)
%
% INPUT: im: immage stack fo the region that we're calculating correlations
%            the correlation function for.
%        mask: mask of different regions
%        centerLine: line down the center of the gut
%        param: parameter file: will be used to extract the appropriate background to subtract 
%        subtractBkg: true/false: will remove background from each region
%        according to our previous background estimation.
%        radStep: Binning size for radial correlation in microns
% radCorr: Radial correlation function in microns.
%
% AUTHOR: Matthew Jemielita, January 28, 2013
%
function radCorr = correlationGut(imStack, regionMask, centerLine, subtractBkg, radStep, param)

totalNumMask = size(regionMask,3);
maxNumReg = 30; %Maximum number of regions to calculate properties of at the same time
%Duplicate the mask.
regionMask =uint16(regionMask);

allReg = unique(regionMask(:));

maxCorr =100; %Should be input-gives upper bound on how
radCorr= zeros(length(centerLine),1);



for numMask=1:totalNumMask
   %Get regions in this particular mask.
   regNum = unique(regionMask(:,:,numMask));
   regNum(regNum==0) = [];
    
   for nR=1:length(regNum)
      thisRegMask = regionMask(:,:,numMask)==regNum(nR);
      
      %Collect together all the regions with 3 boxes of this one-this will
      %give each box an effective are of 35 microns.
      regList = [regNum(nR)-3:regNum(nR)-1, regNum(nR)+1:regNum(nR)+3];
      regList(regList==0) = [];
      regList(regList>max(allReg)) = [];
      for i=1:length(regList)
         for nM =1:totalNumMask
            thisRegMask = thisRegMask + (regionMask(:,:,numMask)==regList(i)); 
         end
      end
      thisRegMask = thisRegMask>0;
      %Get the convex hull of this region
      thisRegMask = bwconvhull(thisRegMask);
      
      %Crop down the image to the size of this mask
      xMin = find(sum(thisRegMask,2)>0, 1,'first');
      xMax = find(sum(thisRegMask,2)>0, 1,'last');
      
      yMin = find(sum(thisRegMask,1)>0, 1,'first');
      yMax = find(sum(thisRegMask,1)>0, 1,'last');
      
      imO = imStack(xMin:xMax,yMin:yMax,:);
      thisRegMask = thisRegMask(xMin:xMax,yMin:yMax,:);
      %Rotate this region
      [~, ~, theta, ~] = optimalAngle(thisRegMask, 'slow');
      thisRegMask = imrotate(thisRegMask,theta);
      
      %Crop down the image to the size of this mask
      xMin = find(sum(thisRegMask,2)>0, 1,'first');
      xMax = find(sum(thisRegMask,2)>0, 1,'last');
      
      yMin = find(sum(thisRegMask,1)>0, 1,'first');
      yMax = find(sum(thisRegMask,1)>0, 1,'last');
      
      thisRegMask = thisRegMask(xMin:xMax,yMin:yMax,:);
      thisRegMask = imresize(thisRegMask, 0.1625); %To match the x,y, and z dimensions.
      
      xMin2 = find(sum(thisRegMask,2)>0, 1,'first');
      xMax2 = find(sum(thisRegMask,2)>0, 1,'last');
      
      yMin2 = find(sum(thisRegMask,1)>0, 1,'first');
      yMax2 = find(sum(thisRegMask,1)>0, 1,'last');
      
      im = zeros(size(thisRegMask,1), size(thisRegMask,2), size(imO,3));
      for nZ=1:size(imO,3)
          rotIm =  imrotate(imO(:,:,nZ),theta);
          rotIm = rotIm(xMin:xMax,yMin:yMax,:);
          rotIm = imresize(rotIm, 0.1625);
          im(:,:,nZ) = rotIm;
      end
      
      cc = normxcorr3(im,im);
      %Get radial correlation function
      cm.x = round(size(cc,2)/2);
      cm.y = round(size(cc,1)/2);
      cm.z = round(size(cc,3)/2);
      dr = 1;


       [rpos, rint] = getrdist(cc, cm, dr);
       radCorr = [rpos; rint];
       fprintf(1, '.');
   end
    
    
end
fprintf(1, 'done!\n');








end