classdef clumpClass < clumpSClass
   properties
       totalInten = NaN;
       volume = NaN;
       intenCutoff = NaN;
       zRange = [NaN NaN];
       sliceNum = NaN;
       gutRegion = NaN;
       cropRect = [NaN NaN NaN NaN];
       removeObj = false;
       
       IND = NaN;%should be private
       
       surfaceArea = NaN;
       centroid = [NaN NaN NaN];
       mesh = struct('node', [], 'elem', [], 'face',[]);
       
       sliceinten = []; %Array that contains the total intensity in each of the slices of the gut that intersect this clump.

   end
   
   methods
       
       function obj = clumpClass(scanNum, colorNum, param,ind)
           obj = obj@clumpSClass(param, scanNum, colorNum);          
           obj.IND = ind;
       end
      
       function vol = loadVolume(obj)
           inputVar = load([obj.saveLoc filesep 'param.mat']); param = inputVar.param;
           imVar.zNum = ''; imVar.scanNum = obj.scanNum; imVar.color = obj.colorStr;
         
           vol = load3dVolume(param, imVar, 'crop', obj.cropRect);
          
       end
       
       function obj = calculateSliceInten(obj, ns)
          %Calculate the intensity in ech of the slices
          vol = obj.loadVolume;
          
          inputVar = load([obj.saveLoc filesep 'masks' filesep 'maskUnrotated_' num2str(ns) '.mat']);
          
          gutMasktot = inputVar.gutMask;
          
          gutMask = zeros(size(vol,1), size(vol,2),size(gutMasktot,3));
          xmax = min([obj.cropRect(2)+obj.cropRect(4),size(gutMasktot,1)]);
          ymax = min([obj.cropRect(1)+obj.cropRect(3),size(gutMasktot,2)]);
          
          gutMask(1:xmax-obj.cropRect(2)+1, 1:ymax-obj.cropRect(1)+1,:) = gutMasktot(obj.cropRect(2):xmax, obj.cropRect(1):ymax,:);
          
          gutMask = max(gutMask,[],3);
          
          vol = vol.*(vol>obj.intenCutoff);
          totinten = sum(vol,3);
          
          cc = regionprops(totinten, gutMask, 'Area','MeanIntensity');
          
          slicenum = unique(gutMask(:));
          si = arrayfun(@(x)sum(totinten(gutMask==x)), slicenum);
          obj.sliceinten = [slicenum, si];
       end
       
       function obj = calcCentroid(obj,vol)
           vol = vol>obj.intenCutoff;
           
           rp = regionprops(vol);
           %Only consider largest region, in case there was some pixel
           %noise around the found objects.
           rp = rp([rp.Area]==max([rp.Area]));
           obj.centroid = [obj.cropRect(1)+rp(1).Centroid(1) obj.cropRect(2)+rp(1).Centroid(2) rp(1).Centroid(3)];
           
       end
       
       function obj = save(obj)
           
           sl = [obj.saveLoc filesep obj.saveStr filesep 'clump_' obj.colorStr '_nS' num2str(obj.scanNum) ];
           if(~isdir(sl))
               mkdir(sl);
           end
           c = obj;
           save([sl filesep num2str(c.IND) '.mat'], 'c');
       end
       
       function obj = calcSurfaceArea(obj)
            
       end
       
       function vol = getBinaryVolume(obj,vol)
           %Make sure there's only one object in the volume and return
           %binary image above background intensity
           cc =  bwconncomp(vol>obj.intenCutoff);
           numPixels = cellfun(@numel,cc.PixelIdxList);

           vol(:) = 0;
           [biggest,idx] = max(numPixels);
           vol(cc.PixelIdxList{idx}) = 1;
           
           
       end
       
       function obj = calcMesh(obj)
          % obj = calcMesh(obj): Calculate a bounding mesh around this
          % object
          vol = obj.loadVolume;
          
          vol = obj.getBinaryVolume(vol);
         if(sum(size(vol)>1000) >1)
             vol = imresize(vol,0.25);
             resized = true;
             fprintf(2, 'Resizing image.\n')
         else
             resized = false;
         end
          [node,elem,face] = v2m(vol,1,100,100);
          obj.mesh = struct('node', node, 'elem', elem, 'face',face);
          obj.mesh.resized = resized;
       end
           
       
      
   end
end % classdef