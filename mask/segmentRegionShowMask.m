%segmentRegionShowMask: High level function to select type of mask to show
%on top of image


function mask = segmentRegionShowMask(mask, maskFeat)


switch maskFeat.Type
    case 'perim'
        
        if(isfield(maskFeat, 'seSize'))
            radius = maskFeat.seSize;
        else
            radius = 5;
        end
        se = strel('disk', radius);
        
        mask = bwperim(mask);
        mask = imdilate(mask, se);
end


end
