%segmentRegionShowMask: High level function to select type of mask to show
%on top of image


function im = segmentRegionShowMask(im, mask, maskFeat)


switch maskFeat.Type
    case 'perim'
        
        if(isfield(maskFeat, 'seSize'))
            radius = maskFeat.seSize;
        else
            radius = 5;
        end
        se = strel('disk', radius);
        maxInten = max(im(:));
        
        mask = bwperim(mask);
        mask = imdilate(mask, se);
        im = im+ maxInten*uint16(mask);
end

end
