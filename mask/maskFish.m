%maskFish: Stores all functions related to the production and display of
%gut masks. This class will mostly be a repository for static methods that
%we can use to create masks, in particuar ones that operate on the MIP of
%the image.


classdef maskFish
    
    
    properties
        scanNum = NaN;
        colorNum = NaN;
        
        bkgOffset = 1.8; %Scalar offset from the estimated background in each wedge of the gut.
        saveDir = '';
        
        minClusterSize = 10000;
        
        colorInten = [1500 1500]; %Intensity cutoff for each color channel (assuming 2) to produce the intensity cutoff mask.
        colorIntenMarker = [2000 2000];%Intensity cutoff for defining markers.
    end
    
   methods(Static)
       function m = getGutOutlineMask(param, scanNum,width)
           % m = getGutOutlineMask(param, scanNum,width): Get outline of of the entire 
           % gut for a particular scan. The input width gives the amount,
           % in pixels, to dilate the mask.
           m = maskFish.getGutFillMask(param, scanNum);
           
           m = bwperim(m);
           se = strel('disk', width);
           
           m = imdilate(m, se);
       end
       
       function m = getGutFillMask(param, scanNum)
           %m = getGutFillMask(param, scanNum): Get a binary mask which is
           %equal to 1 inside the outlined gut, and 0 otherwise.
           poly = param.regionExtent.polyAll{scanNum};
           imSize = param.regionExtent.regImSize{1};
           m = poly2mask(poly(:,1), poly(:,2), imSize(1), imSize(2));
       end
       
       function m = getCenterLineMask(param, scanNum, colorNum)
           
       end
       
       function gutMask = getGutRegionMask(param, ns)
           %gutMask = getGutRegionMask(param, scanNum): Construct a
           %mask of the gut that gives gut regions perpendicular to the
           %long axis of the gut for this scan.
             poly = param.regionExtent.polyAll{ns};
           imSize = param.regionExtent.regImSize{1};
           gutMask = poly2mask(poly(:,1), poly(:,2), imSize(1), imSize(2));
           
           cl = param.centerLineAll{ns};
           gutMask = curveMask(gutMask, cl,'', 'rectangle');
           
       end
       
       function getGutRegionMaskAll(param)
           %m = getGutRegionMask(param): Construct a
           %mask of the gut that gives gut regions perpendicular to the
           %long axis of the gut for all scans. Save the result to the
           %subdirectory 'masks'.
           
           if(~isdir([param.dataSaveDirectory filesep 'masks']))
               mkdir([param.dataSaveDirectory filesep 'masks']);
           end
           for ns = 1:param.expData.totalNumberScans
               fprintf(1, ['Making mask for scan ', num2str(ns), '\n']);
               gutMask = maskFish.getGutRegionMask(param, ns);
               gutMask = maskFish.fillGap(gutMask,param,ns);
               %Save result
               save([param.dataSaveDirectory filesep 'masks' filesep 'maskUnrotated_' num2str(ns) '.mat'], 'gutMask', '-v7.3');
           end
           
       end
       
       function gutMask = fillGapGutRegionMask(gutMask, param, ns)
            m = maskFish.getGutFillMask(param, ns);
            
       end
       
       function fillGapAll(param)
           for ns = 1:param.expData.totalNumberScans
               fprintf(1, ['Making gaps for scan ', num2str(ns), '\n']);
               %load result
               inputVar = load([param.dataSaveDirectory filesep 'masks' filesep 'maskUnrotated_' num2str(ns) '.mat']);
               gutMask = inputVar.gutMask;
               
               gutMask = maskFish.fillGap(gutMask,param,ns);
               
               %Save result
               save([param.dataSaveDirectory filesep 'masks' filesep 'maskUnrotated_' num2str(ns) '.mat'], 'gutMask', '-v7.3');
           end
       end
       
       function gutMask = fillGap(gutMask,param, scannum)
           %% Fill in gaps in our gut region mask
           
           %% Get boundaries of each of the gut regions as currently found
           pmask = zeros(size(gutMask,1),size(gutMask,2));
           for i=1:size(gutMask,3)
               r = gutMask(:,:,i);
               numel = unique(r); numel(numel==0) = [];
               
               for j=1:length(numel)
                   t = r==numel(j);
                   t = bwperim(t);
                   
                   pmask(t) = numel(j);
               end
           end
           
           %% Get list of points that haven't been assigned to a region
           c = maskFish.getGutFillMask(param,scannum);
           c = c-(max(gutMask,[],3)>0);
           
           %% Find regions for each of the wedges that's missing
           
           cc = regionprops(logical(c));
           
           for i=1:size(gutMask,3)
               r = gutMask(:,:,i);
               ind = unique(r); ind(ind==0) =[];
               t = regionprops(r);
               
               for j=1:length(ind)
                   ccR(ind(j)) = t(ind(j));
               end
           end
           
           %% Get distances from each of the remaining wedges to the regions remaining
           xy = [cc.Centroid];
           xy = reshape(xy, 2,length(xy)/2);
           
           xyr = [ccR.Centroid];
           xyr = reshape(xyr, 2,length(xyr)/2);
           
           d = dist(xy', xyr);
           
           [~,ind] = min(d,[],2);
           
           %% Update each of the missing wedges
           b = bwlabel(c);
           notzero = find(b(:)~=0);
           
           b(notzero) = ind(b(notzero));
           %%
           for i=1:size(gutMask,3)
               el = unique(gutMask(:,:,i));
               el(el==0) = [];
               
               t = gutMask(:,:,i);
               t(ismember(b,el)) = b(ismember(b,el));
               gutMask(:,:,i) = t;
           end
           
       end
           
       
   end
   
       methods 
           
       function m = getSpotMask(obj,param, scanNum, colorNum)
           %m = getSpotMask(param, scanNum, colorNum): Get a binary mask
           %showing the locations of found spots in the gut.
           
           %% Remove regions around found bacterial spots
           spotFile = [param.dataSaveDirectory filesep 'singleBacCount' filesep 'spotClassifier.mat'];
           if(~exist(spotFile))
               fprintf(2, 'Need to construct spot classifier first!\n');
               return
           else
               inputVar = load(spotFile);
               spots = inputVar.spots;
           end
           
           rProp = spots.loadFinalSpot(scanNum, colorNum);
           
           xyz = spotClass.getXYZPos(rProp);
           xyz = xyz(1:2,:);
           
           %Go through each of these spots and add a circle to to the mask around the
           %spot
           imSize = param.regionExtent.regImSize{1};           
           spotRad = 5;
           m = makeCircleMask(imSize, xyz, spotRad);
       end
       
       function m = getBkgEstMask(obj,param, scanNum, colorNum)
           %m = getBkgEstMask(param, scanNum, colorNum): Construct an
           %estimate of the background intensity. This function requires
           %the creation of the background estimator for each wedge in the
           %gut-this is somewhat old code that I'm hoping to retire.

           %New code: construct an estimator of the background from just
           %the MIP
           recalcProj = false;
           im = selectProjection(param, 'mip', 'true', scanNum, param.color{colorNum}, '',recalcProj);
           m = maskFish.getGutFillMask(param, scanNum);
           im(~m) = nan;
           inputVar = load([param.dataSaveDirectory filesep 'masks' filesep 'maskUnrotated_' num2str(scanNum) '.mat']);
           gutMask = inputVar.gutMask;
           
           histInd = unique(gutMask(:));
           histInd(histInd==0) = [];
           
           histAll = cell(length(histInd),1);
           
           for i=1:length(param.centerLineAll{scanNum})
              %Get region just around each of these lines-use this to estimate the background to subtract 
              cl = param.centerLineAll{scanNum}(i,:);
              minX = max([1, cl(1)-20]);
              maxX = min([size(im,2),cl(1)+20]);
              minY = max([1, cl(2)-20]);
              maxY = min([size(im,1),cl(2)+20]);
              imc = im(minY:maxY, minX:maxX);
              meanv(i) = nanmean(imc(:)) + 3*nanstd(double(imc(:)));
           end
           
           m = smooth(meanv, 10);
           %Force everything after the end of the bulb to go to a constant
           %background intensity
           m(round(0.75*param.gutRegionsInd(2)/2):end) = m(round(0.75*param.gutRegionsInd(2)/2));
           
           maskAll = zeros(size(im));
           
           
           for i=1:length(histInd)
               for nm =1:size(gutMask,3)
                   mask = gutMask(:,:,nm)== histInd(i);
                   if(sum(mask(:))==0)
                       %Wrong stack
                       continue;
                   else
                       maskAll(mask) = meanv(i);
                   end
                   i
               end
           end
%            
%            for i=1:length(histInd)
%                ind = 0:10:4000;
%                data = histAll{i};
%                smth = smooth(ind,data, 51, 'sgolay',3);
%                
%                minP = data(end)+ 500;
%                [pks,loc] = findpeaks(smth, 'MINPEAKHEIGHT', minP,...
%                    'MINPEAKDISTANCE', 20);
%                
%            end
           
%            
%            fN = [param.dataSaveDirectory filesep 'bkgEst' filesep 'bkgEst_' param.color{colorNum} '_nS_' num2str(scanNum) '.mat'];
%            if(exist(fN, 'file')~=2)
%                makeUnrotatedMask(param, scanNum, colorNum);
%                makeBkgSegmentMask(param, scanNum, colorNum);
%            else
%                
%                recalcProj = false;
%                im = selectProjection(param, 'mip', 'true', scanNum, param.color{colorNum}, '',recalcProj);
%                
%                m = showBkgSegment(im, scanNum, colorNum, param, obj.bkgOffset);
%            end
       end
       
       function m = getIntenMask(obj,param, scanNum, colorNum, varargin)
          %m = getIntenMask(param, scanNum, colorNum, direction): Construct a binary
          %mask of regions above a given intensity. Used the variable
          %obj.colorInten(colorNum) as the intensity cutoff. Optional
          %input : direction ('gt', 'lt', default: 'gt') give an intensity
          %cutoff  greater than ('gt') or less than ('lt') the given
          %intensity cutoff.
          if(nargin==4)
              direction = 'gt';
          else
             direction = varargin{1}; 
          end
          
          recalcProj = false;
          im = selectProjection(param, 'mip', 'true', scanNum, param.color{colorNum}, '',recalcProj);
          param.dataSaveDirectory
          switch direction
              case 'gt'
                  m = im>obj.colorInten(colorNum);
              case 'lt'
                  m = im<obj.colorInten(colorNum);
          end
          gm = maskFish.getGutFillMask(param, scanNum);
          
          m(~gm) = 0;
          
       end
       
       function m = getGraphCutMask(obj,param, scanNum, colorNum)
           
           % m = getGraphCutMask(param, scanNum, colorNum): Construct a
           % segmented image of the gut using a graph cut segmentation
           % algorithm.
           
          % segMask = maskFish.getBkgEstMask(param, scanNum, colorNum);
           segMask  = obj.getIntenMask(param, scanNum, colorNum,'lt');
           spotMask = obj.getSpotMask(param, scanNum, colorNum);
          
           recalcProj = false;
           im = selectProjection(param, 'mip', 'true', scanNum, param.color{colorNum}, '',recalcProj);
           obj.colorInten(colorNum)  = obj.getIntensityCutoff(im, spotMask);
           
           obj.colorInten = obj.colorIntenMarker;
           intenMask = obj.getIntenMask(param, scanNum, colorNum);
           
           intenMask = obj.removeSmallObj(intenMask, spotMask);
           
           segMask = ~bwareaopen(~segMask,1000);
           %segMask = imclearborder(~segMask,4);
           m = maskFish.getGutFillMask(param, scanNum);
           segMask(~m) = 1;
           segMask = ~segMask;
           %segMask(~m) = NaN;
           %Force the intensity mask to always include individual bacteria,
           %even if they fall below the intensity threshold.
           %intenMask = (intenMask+spotMask)>0;
           
           %Remove regions that don't have high intensity spots in it or single
           %bacteria.
           cc = bwconncomp(segMask );
           label = labelmatrix(cc);
           
           ul = unique(label(:)); ul(ul==0) =[];
           
           for i=1:length(ul)
               thisR = label==ul(i);
               thisR = thisR+intenMask;
               if(max(thisR(:))==1)
                   %Then check to see if there are no spots in this region
                   thisR = (label==ul(i))+spotMask;
                   if(max(thisR(:))==1)
                       label(label==ul(i)) = 0;
                   end
                   
               end
               
           end
           
           segMask = label>0;
           
           %segMask = (segMask+spotMask)>0;
           
           %% Further segment data using graph cut approach
           
           cc = bwconncomp(segMask);
           
           maskTot = zeros(size(segMask));
           imMaster = im;
           imMaster(~segMask) = NaN;
           for i=1:cc.NumObjects
               
               fprintf(1, '.');
               mask = zeros(size(segMask));
               mask(cc.PixelIdxList{i}) = 1;
             
               [mask2, im, range] = minBoundBox(mask, imMaster);
               [~,maskM,~] = minBoundBox(mask, intenMask);
               mask = mask2;
               if(isempty(mask)|sum(mask(:))==0||length(mask(:))<4)
                   continue
               end  
               %To generate a histogram of potential intensities from source and
               %sink, dilate mask by a given amount and use that as the cutoff
               %between the two regions.
               %mlj: Note this value here is probably too small-should
               %probably increase this.
               se = strel('disk',5);
               
               maskD = imdilate(maskM,se);
               
               im = mat2gray(im);
               val = double(im(maskD));val = val(:);
               val(isnan(val)) = [];val(val==0) = [];
               
               %Require that all pixel values equal to 0 are not in source
               src = double(im(maskD));src(src==0) =[];
               [sourceHistProb, sourceHistVal]= hist(src,50);
               dx = unique(sourceHistVal(2:end)-sourceHistVal(1:end-1));
               dx = dx(1);
               sourceHistProb = sourceHistProb/(dx*sum(sourceHistProb(:)));

               val = double(im(~maskD));val = val(:);
               val(isnan(val)) = []; val(val==0) = [];
               [sinkHistProb, sinkHistVal] = hist(double(im(~maskD)),50);
               dx = unique(sinkHistVal(2:end)-sinkHistVal(1:end-1));
               dx = dx(1);
               sinkHistProb = sinkHistProb/(dx*sum(sinkHistProb));
               
               %[sinkHistProb, sinkHistVal] = hist(double(im(~maskD)),50);
               
               intenEst{1,1} = sinkHistProb;
               intenEst{1,2} = sinkHistVal;
               
               intenEst{2,1} = sourceHistProb;
               intenEst{2,2} = sourceHistVal;
               
               %Require that pixels on the edge of the image region are in
               %the sink (to prevent bleedthrough of our segmentation onto
               %the image border
               bkgMask = ~maskD;
               bkgMask(1,:) = 1; bkgMask(:,1) = 1;
               bkgMask(end,:) = 1; bkgMask(:,end) = 1;
               
               finMask = graphCut(im, maskM, bkgMask, intenEst);
               finMask = finMask==1;
               maskTot(range(1):range(3), range(2):range(4)) = double(finMask)+double(maskTot(range(1):range(3), range(2):range(4)));
               
               dspIm = false;
               if(dspIm==true)
                  %Now seeing how well we can do at our segmentation
                  imshow(im,[]);
                  alphamask(bwperim(mask), [1 0 0]);
                  alphamask(bwperim(finMask), [0 1 0]);
                  pause
               end
               %Get histogram of pixel intensities in mask
               fprintf(1,'.');
               
           end
           fprintf(1,'\n');
           
           m = maskTot>0;         
       end
       
       function inten = getIntensityCutoff(obj,im, spotMask)
            b  = im(spotMask==1);
            b = sort(b(:));
            if(isempty(b(:)))
                %If not spts found, force the itensity cutoff to be higher
                %than the max intensity-effectively counting zero bacteria.
                inten = max(im(:));
            else
                %Cutoff equal to intensity of the 90% percentile of bugs.
                inten = b(round(0.2*length(b)));
            end
       end
       
       function m = getFinalGutMask(obj,param, scanNum, colorNum)
           
       end
       
       function m = calcFinalMask(obj,param,saveName, varargin)
           switch nargin
               case 2
                   sL = param.expData.totalNumberScans;
                   cL = length(param.color);
               case 4
                   sL = varargin{1};
                   cL = varargin{2};
           end
           
           for s = 1:sL
               fprintf(1, ['Scan ' num2str(s) '\n']);
               for c=1:cL
                   
                   segMask = maskFish.getGraphCutMask(param, s,c);
           
                   fileN = [param.dataSaveDirectory filesep 'bkgEst' filesep saveName '_' num2str(s) '_' param.color{c} '.mat'];
                   save(fileN, 'segMask');
               end
           end
       end
       
       function segMask = removeSmallObj(obj,segMask, spotMask)
           %Remove small objects that don't overlap with found spots
           segMask = bwareaopen(segMask, 500);
          
           segMask = (spotMask+segMask)>0;
           
       end
       
       function m = calcIndivClumpMask(obj,param, scanNum, colorNum)
           
       end
       
       function m = filterMask(obj, scanNum,colorStr)
           saveLoc = [obj.saveDir filesep 'allRegMask_' num2str(scanNum) '_' colorStr '.mat'];
           inputVar = load(saveLoc); segMask = inputVar.segMask;
           segMask = bwlabel(segMask>0);
           
           
           segMaskNew = bwareaopen(segMask, obj.minClusterSize);
           
           %Save result, backup old result
           if(~isdir([obj.saveDir filesep 'maskBackup']))
              mkdir([obj.saveDir filesep 'maskBackup']); 
           end
           save([obj.saveDir filesep 'maskBackup' filesep 'allRegMask_' num2str(scanNum) '_' colorStr '.mat'], 'segMask');
           

           segMask = bwlabel(segMaskNew);
%Save output as a label matrix, not a binary mask.           
           save([obj.saveDir filesep 'allRegMask_' num2str(scanNum) '_' colorStr '.mat'], 'segMask');
           
           m = segMask;
       end
       
       
       function saveInstance(obj)
          %saveInstance(): save this instance of maskFish to
          %(obj.saveDir/'masks.mat). This will almost always be in
          %the subfolder /gutOutline/masks
          mask = obj;
          
          if(~isdir(obj.saveDir))
              fprintf(1, 'Making directory for masks.\n');
              mkdir(obj.saveDir)
          end
              
          save([obj.saveDir filesep 'mask.mat'], 'mask');     
          fprintf(1, 'maskFish instance saved!\n');
       end
   end

end