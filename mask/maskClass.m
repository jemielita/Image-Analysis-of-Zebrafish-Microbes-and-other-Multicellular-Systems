%maskClass: Stores all functions related to the production and display of
%gut masks. This class will mostly be a repository for static methods that
%we can use to create masks, in particuar ones that operate on the MIP of
%the image.


classdef maskClass
    
    
    properties
        scanNum = NaN;
        colorNum = NaN;
        
    end
    
   methods(Static)
       function m = getGutOutlineMask(param, scanNum,width)
        m = maskClass.getGutFillMask(param, scanNum);
        
        m = bwperim(m);
        se = strel('disk', width);
        
        m = imdilate(m, se);
       end
       
       function m = getGutFillMask(param, scanNum)
           poly = param.regionExtent.polyAll{scanNum};
           imSize = param.regionExtent.regImSize{1};
           m = poly2mask(poly(:,1), poly(:,2), imSize(1), imSize(2));
       end
       
       function m = getCenterLineMask(param, scanNum, colorNum)
           
       end
       
       function m = getSpotMask(param, scanNum, colorNum)

           
           %% Remove regions around found bacterial spots
           inputVar = load([param.dataSaveDirectory filesep 'singleBacCount'...
               filesep 'bacCount' num2str(scanNum) '.mat']);
           
           if(iscell(inputVar.rProp))
               rProp = inputVar.rProp{colorNum};
           else
               rProp = inputVar.rProp;
           end
           
           remBugsSaveDir = [param.dataSaveDirectory filesep 'singleBacCount' filesep 'removedBugs.mat'];
           if(exist(remBugsSaveDir, 'file')==2)
               removeBugInd = load(remBugsSaveDir);
               removeBugInd = removeBugInd.removeBugInd;
           end
           
           keptSpots = setdiff(1:length(rProp), removeBugInd{scanNum, colorNum});
           
           rPropClassified = rProp(keptSpots);
           useRemovedBugList = false;
           classifierType = 'none';
           distCutoff_combRegions = false;
           
           rProp = bacteriaCountFilter(rPropClassified, scanNum, colorNum, param, useRemovedBugList, classifierType,distCutoff_combRegions);
           
           xyz = [rProp.CentroidOrig];
           xyz = reshape(xyz,3,length(xyz)/3);
           
           xyz = xyz(1:2,:);
           
           %Go through each of these spots and add a circle to to the mask around the
           %spot
           imSize = param.regionExtent.regImSize{1};           
           spotRad = 5;
           m = makeCircleMask(imSize, xyz, spotRad);
       end
       
       function m = getBkgEstMask(param, scanNum, colorNum)
           
           fN = [param.dataSaveDirectory filesep 'bkgEst' filesep 'bkgEst_' param.color{colorNum} '_nS_' num2str(scanNum) '.mat'];
           if(exist(fN, 'file')~=2)
               makeUnrotatedMask(param, scanNum, colorNum);
               makeBkgSegmentMask(param, scanNum, colorNum);
           else
               
               recalcProj = false;
               im = selectProjection(param, 'mip', 'true', scanNum, param.color{colorNum}, '',recalcProj);
               
               bkgOffset = 1.8;
               m = showBkgSegment(im, scanNum, colorNum, param, bkgOffset);
           end
       end
       
       function m = getIntenMask(param, scanNum, colorNum, varargin)
          switch nargin
              case 3
                  colorIntenL = [1000,500];
                  colorInten = colorIntenL(colorNum);
              case 4
                  colorInten = varargin{1};
          end
          
          recalcProj = false;
          im = selectProjection(param, 'mip', 'true', scanNum, param.color{colorNum}, '',recalcProj);
          
          m = im>colorInten;
          
          gm = maskClass.getGutFillMask(param, scanNum);
          
          m(~gm) = 0;
          
       end
       
       function m = getGraphCutMask(param, scanNum, colorNum)
           segMask = maskClass.getBkgEstMask(param, scanNum, colorNum);
           spotMask = maskClass.getSpotMask(param, scanNum, colorNum);
           recalcProj = false;
           im = selectProjection(param, 'mip', 'true', scanNum, param.color{colorNum}, '',recalcProj);
           
           inten = maskClass.getIntensityCutoff(im, spotMask);
           
           intenMask = maskClass.getIntenMask(param, scanNum, colorNum,inten);
           
           intenMask = maskClass.removeSmallObj(intenMask, spotMask);
           %Force the intensity mask to always include individual bacteria,
           %even if they fall below the intensity threshold.
           intenMask = (intenMask+spotMask)>0;
           
           %Remove regions that don't have high intensity spots in it or single
           %bacteria.
           cc = bwconncomp(segMask);
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
           
           segMask = (segMask+spotMask)>0;
           
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
               
               %To generate a histogram of potential intensities from source and
               %sink, dilate mask by a given amount and use that as the cutoff
               %between the two regions.
               se = strel('disk',10);
               
               maskD = imdilate(maskM,se);
               
               im = mat2gray(im);
               val = double(im(maskD));val = val(:);
               val(isnan(val)) = [];val(val==0) = [];
               
               [sourceHistProb, sourceHistVal]= hist(double(im(maskD)),50);
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
               
               finMask = graphCut(im, maskM, ~maskD, intenEst);
               maskTot(range(1):range(3), range(2):range(4)) = double(finMask)+double(maskTot(range(1):range(3), range(2):range(4)));
               
               
               %    %Now seeing how well we can do at our segmentation
               %    imshow(im,[]);
               %    alphamask(bwperim(mask), [1 0 0]);
               %    alphamask(bwperim(finMask), [0 1 0]);
               %    %Get histogram of pixel intensities in mask
               fprintf(1,'.');
               
               
           end
           fprintf(1,'\n');
           
           m = maskTot>0;
           
       end
       
       function inten = getIntensityCutoff(im, spotMask)
            b  = im(spotMask==1);
            b = sort(b(:));
            if(isempty(b(:)))
                %If not spts found, force the itensity cutoff to be higher
                %than the max intensity-effectively counting zero bacteria.
                inten = max(im(:));
            else
                %Cutoff equal to intensity at which %80 of bacteria signal
                %present-somewhat arbitrary
                inten = b(round(0.2*length(b)));
            end
       end
       
       function m = getFinalGutMask(param, scanNum, colorNum)
           
       end
       
       function m = calcFinalMask(param,saveName, varargin)
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
                   segMask = maskClass.getGraphCutMask(param, s,c);
           
                   fileN = [param.dataSaveDirectory filesep 'bkgEst' filesep saveName '_' num2str(s) '_' param.color{c} '.mat'];
                   save(fileN, 'segMask');
               end
           end
       end
       
       function segMask = removeSmallObj(segMask, spotMask)
           %Remove small objects that don't overlap with found spots
           segMask = bwareaopen(segMask, 500);
           segMask = (spotMask+segMask)>0;
           
       end
   end

end