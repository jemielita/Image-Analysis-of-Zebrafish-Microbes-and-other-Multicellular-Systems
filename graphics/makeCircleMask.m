%makeCircleMask: Make a mask with a number of circles
%
%

function mask = makeCircleMask(imSize, xy, rad)

mask = zeros(imSize(1), imSize(2));

ind = sub2ind(imSize, xy(2,:), xy(1,:));

mask(ind) = 1;
se = strel('disk', rad);

mask =imdilate(mask, se);

end