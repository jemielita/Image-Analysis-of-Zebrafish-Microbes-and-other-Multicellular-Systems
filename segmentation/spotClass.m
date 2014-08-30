%spotClass: All functions for manipulating individual spots from a scan.


classdef spotClass
    
    
    properties
        scanNum = NaN;
        colorNum = NaN;
        
    end
    
   methods(Static)
       function rProp = findGutSliceParticle(rProp,param, nS)
           %Find the slice in the gut that each of the found
           %spots is located in. Updates the bacteria count list.
           pos = [rProp.CentroidOrig];
           pos = reshape(pos, 3, length(pos)/3);
           pos = pos(1:2,:);
           pos = pos';
           
           %Distance of all points to the center line
           cL = param.centerLineAll{nS};

           clDist = dist(pos, cL');
           [~,ind] = min(clDist,[],2);
           
           for i=1:length(rProp)
               rProp(i).sliceNum = ind(i);
               
               ri = param.gutRegionsInd(nS,:);
               rProp(i).gutRegion = find(ind(i)>=ri, 1, 'last');
           end           
       end
       
       function rProp = setSpotInd(rProp)
           %Give a unique number to each of the found spots. Be careful
           %when calling this function because this is what the
           %hand-checked list of spots uses to discriminate spots
          for i=1:length(rProp)
             rProp(i).ind = i; 
          end
           
       end
           
       function pos = getXYZPos(rProp)
           pos = [rProp.CentroidOrig];
           pos = reshape(pos,3,length(pos)/3);
       end
       
       function rProp = cullList(rProp)
           %Apply harsh cutoffs to list of spots to remove obvious false
           %positives.
       end
       
       function rProp = cullVal(rProp, type, minVal)
          rProp([rProp.(type)]<minVal) = []; 
       end
       
       function rProp = removeManualBug(rProp, param, ns, nc)
           
       end
       
       function rProp = distCutoff(rProp,cut)
          %Find all points within a given distance (cut, in microns) and
          %remove the points that have a lower intensity.
          %Suggest using a cutoff ~ the size of a bacteria. ex: 3 microns.
          
          pos = [rProp.CentroidOrig];
          pos = reshape(pos, 3, length(pos)/3);
          %Rescale xy coordinates.
          pos(1:2,:) = 0.1625*pos(1:2,:);
          
          %Find all points within cutoff of each other.
          d = dist(pos',pos);
          d = (d<cut).*(d>0);
          [y,x] = find(triu(d)==1);
          xy = [x,y];

          if(isempty(xy))
              return
          end
          
          %Construct list of these point's intensities.
          inten = [rProp(x).MeanIntensity; rProp(y).MeanIntensity]';
          list = inten(:,1)<inten(:,2);
          %Find which point has the lower intensity.
          list = [list, ~list];

          xyFinal = unique(xy(list(:)==1));
          %Remove lower intensity point
          rProp(xyFinal) = [];
       end
       
       function rProp = getObjectFeat(rProp,param, boxSize, ns, nc)
           %% Get extensive list of features of each of the found spots.
           rem = []; %List of spots to remove.
           maxThresh = 30;
           for i=1:length(rProp)
               %% Get spot
               
               cropRect = spotClass.getCropRect(rProp(i),param, boxSize);
               
               %% Loading volume
               
               imVar.scanNum = ns; imVar.zNum =''; imVar.color = param.color(nc);
               
               im = load3dVolume(param, imVar, 'crop', cropRect);
               
               %figure; imshow(max(im,[],3),[0 1000]);
               
               %% Filtering the spots again using the wavelet-based spot
               %detection approach.
               %mlj: This code should call the exact same code as we use
               %for our spot detection!
               ims = im;
               imWavelet = im;
               for z = 1:size(im,3)
                   ims(:,:,z) = cv.spotDetectorFast(im(:,:,z),4);
                   imWavelet(:,:,z) = ims(:,:,z);
                   %Clean up small regions
                   ims(:,:,z) = bwareaopen(ims(:,:,z)>maxThresh, 10);
                   ims(:,:,z) = imclearborder(ims(:,:,z)==1);   
               end
               
               label = bwlabeln(ims);
               
               if(isempty(label))
                   rem = [rem i];
                   continue;
                   fprintf(1, '.');                   
               end
               
               if(size(label,1)<boxSize || size(label,2)<boxSize)
                   rem = [rem i];
                   continue;
                   fprintf(1, '.');                   
               end
               
               %If more than onde object is here, find one closest to
               %the z centroid as found before
               z = rProp(i).CentroidOrig(3)-cropRect(3);
               val = find(label(boxSize, boxSize, :)~=0);
               [~,n] = min(abs(val-z));
               
               %Only keep the closest one
               ind = label(boxSize, boxSize, val(n));
              
               if(isempty(ind))
                   %fprintf('No object at center!?\n');
                   rem = [rem i];
                   continue
                   fprintf(1, '.');
               end
               
               if(length(ind)>1)
                   val = find(label(boxSize, boxSize, :)~=0);
                   [~,n] = min(abs(val-z));
                   
                   %Only keep the closest one
                   ind = label(boxSize, boxSize, val(n));
                   fprintf(1, 'Fix up code!\n');
                   
                   pause
               end
               
               label = label==ind;
               
               %% Construct mask for the background
               bkgIm = im;
               bkgIm(~label==0) = -1;
               
               %% Histogram properties of background and spots
               x = 0:50:3000;
               hgram.s = hist(im(label==1),x);
               hgram.bkg = hist(im(label==0),x);
               
               hgram.s= hgram.s/sum(hgram.s);
               hgram.bkg = hgram.bkg/sum(hgram.bkg);
               
               rProp(i).objMean = mean(im(label==1));
               rProp(i).bkgMean = mean(im(label==0));
               
               rProp(i).wvlMean = mean(imWavelet(label==1));
               rProp(i).wvlMean = mean(imWavelet(label==0));
               
               
               rProp(i).objStd = std(im(label==1));
               rProp(i).bkgStd = std(im(label==0));
               
               rProp(i).Volume = sum(im(label==1));
               
               %% ks-test
               [~,rProp(i).ksTest] = kstest2(hgram.s, hgram.bkg);
               
               %% Particle fitting code-gives the goodness of fit-should be low for a purely circular object
               %(smallish tests seem to support this).
               temp = max(im,[],3);
               temp(max(label,[],3)~=1) = 0;
               [~,~,~,rProp(i).centroidFit] = radialcenter(temp);
               %% Object properties
               
               maxL = max(label,[],3)==1;
               maxIm = max(im,[],3);
               
               spotProp = regionprops(maxL,maxIm, 'Area','ConvexHull', 'Eccentricity', 'MajorAxisLength', 'MinorAxisLength', 'ConvexArea');
               
               rProp(i).MajorAxisLength = spotProp.MajorAxisLength;
               rProp(i).MinorAxisLength = spotProp.MinorAxisLength;
               rProp(i).Eccentricity = spotProp.Eccentricity;
               rProp(i).ConvexHull = spotProp.ConvexHull;
               rProp(i).Area = spotProp.Area;
               rProp(i).convexArea = spotProp.ConvexArea;
        
               fprintf(1, '.');
           end
  
           %% Cull out spots that don't meet these filtered criteria
           rProp(rem) = [];
           fprintf(1, '.');
           fprintf(1, '\n');
       end
       
       function cropRect = getCropRect(spot,param,boxSize)
           boxZ = 5;
           %Getting cropping box around this particular spot.
               cropRect = [spot.CentroidOrig(1)-boxSize,spot.CentroidOrig(2)-boxSize, spot.CentroidOrig(3)-boxZ, 2*boxSize, 2*boxSize, 2*boxZ];
               
               cropRect(1) = max([cropRect(1), 1]);
               cropRect(2) = max([cropRect(2), 1]);
               cropRect(3) = max([cropRect(3), 1]);
               
               x = param.regionExtent.regImSize{1}(1);
               y = param.regionExtent.regImSize{1}(2);
               z = size(param.regionExtent.Z,1);
               cropRect(4) = min([cropRect(1)+cropRect(4), y])-cropRect(1)-1;
               cropRect(5) = min([cropRect(2)+cropRect(5), x])-cropRect(2)-1;
               cropRect(6) = min([cropRect(3)+cropRect(6), z])-cropRect(3)-1;
       end
   end

end