%segmentRegionShowMask: High level function to select type of mask to show
%on top of image. Tied closely in with multipleRegionCrop and this function
%alters images displayed in that GUI


function mask = segmentRegionShowMask(mask, maskFeat, segmentationType,imageRegion)

%Remove previosly displayed objects
hRem = findobj('Tag', 'segMask');
delete(hRem);

switch maskFeat.Type
    case 'perim'
        
        if(isfield(maskFeat, 'seSize'))
            radius = maskFeat.seSize;
        else
            radius = 5;
        end
        se = strel('disk', radius);
        
        if(strcmp(segmentationType.Selection,'clump and indiv'))
            %Display individuals
            thisMask = bwperim(mask==1);
            thisMask = imdilate(thisMask, se);

            hAlpha = alphamask(thisMask, [1 0 0], 0.5, imageRegion);
            set(hAlpha, 'Tag', 'segMask');
            %Display clumps
            thisMask = bwperim(mask==2);
            thisMask = imdilate(thisMask, se);
            
            hAlpha = alphamask(thisMask, [0 1 0], 0.5, imageRegion);
            set(hAlpha, 'Tag', 'segMask');

        else
            mask = bwperim(mask);
            mask = imdilate(mask, se);
            hAlpha = alphamask(mask, [1 0 0], 0.5, imageRegion);
            set(hAlpha, 'Tag', 'segMask');
        end
        
    case 'preloaded'
            hAlpha = alphamask(mask, [1 0 0], 0.5, imageRegion);
            set(hAlpha, 'Tag', 'segMask');
        
end

end
