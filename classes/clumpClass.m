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

   end
   
   methods
       
       function obj = clumpClass(scanNum, colorNum, param,ind)
           obj = obj@clumpSClass(param, scanNum, colorNum);          
           obj.IND = ind;
       end
      
       function vol = loadVolume(obj)
           inputVar = load([obj.saveLoc filesep 'param.mat']); param = inputVar.param;
           imVar.zNum = ''; imVar.scanNum = obj.scanNum; imVar.color = obj.colorStr;
           param.directoryName = ['J' param.directoryName(2:end)];
           vol = load3dVolume(param, imVar, 'crop', obj.cropRect);
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
           
           
       
%        function display(obj)
%           %Display the MIP of this particular bug
%           %figure; 
%           
%        end
      %Save class to file
      
   end
end % classdef