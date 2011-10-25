%First attempt at doing 3d cell segmentation



for i=0:80
   
    %For each image in the scan we'll run Otsu's threshold on the image to
    %find an appropriate threshold and then stich together all the frames.
    %However, it may be more benficial in the future to find either a
    %global threshold using all the stacks or to use some local threshold.
    
    filename = strcat('pco', num2str(i), '.tif');
    
    im = imread(filename);
    im = mat2gray(im);
    
    %Cropping the image
    im = imcrop(im, rect);
    
    gt = graythresh(im);
    
    
    imO = imoverlay(im, im>gt, [1 0 0]);
    
    imshow(imO, []);
    f(i+1) = getframe;
    
    
end