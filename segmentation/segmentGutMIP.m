%segmentGutMIP: high level function for segmenting the MIP image of the gut
%
% USAGE segMask = segmentGutMIP(im, segmentType)
%
% INPUT im: maximum intensity image of the gut.
%       segmentType: string giving the type of segmentation to use
%              'otsu': intensity level thresholding with some morphological
%              bell and whistles
% OUTPUT segMask: binary mask with segmented regions given by 1s.
%
% AUTHOR: Matthew Jemielita, Aug 15, 2013

function segMask = segmentGutMIP(im, segmentType)

switch lower(segmentType)
    case 'otsu'
        segMask = otsuSegment(im);
end


end


function segMask = otsuSegment(im)
im = mat2gray(im);
gT = graythresh(im(im~=0));

segMask = im > gT;

end