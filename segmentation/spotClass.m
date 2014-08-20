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
                
   end

end