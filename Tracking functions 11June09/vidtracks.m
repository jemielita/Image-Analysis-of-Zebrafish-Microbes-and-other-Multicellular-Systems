%% vidtracks.m description
%
%**Update May 06, 2009**
%
%Function to take a 3D image array with frame indicies to a 4D image array
%in color with frame indicies keeping the original images in monochrome
%while adding colored pixels following the objects in the images and
%(optionally) leaving 'trails' or the colored pixels from previous images
%in different colors on subsequent images. As of May 05, 2009 there are two
%other components to this function. Intead of a 4D color 'movie' array the
%new output is a structured array in the style that matlab deals with
%movies. Also a movie is generated to specifications in the current
%directory (or where specified) and a time elapsed printout occurs.
%
%% Input Parameters
%   
%   im   -- 3D image array with dimensions [m n p] where m is y-height in
%           pixels, n is x-width in pixels and p is the frame number. Use
%           an image with uint8 values.
%           
%   objs -- 6-row linked object matrix, from nnlink_rp.m or another program
%           of that type ( see im2obj_rp for object structure)
%   
%   FPS  -- The Frame rate of the output movie file, if not input there is
%           a default value of 10FPS.
%
%   Filename-- The filename synatx is 'filename.avi' or a whole directory
%              loaction if desired, if not input there is a default value 
%              of 'vidtracks.avi'.
%
%   comp -- The compression software of your choosing the values for
%           windows are 'Indeo3', 'Indeo5', 'Cinepak', 'MSVC', 'RLE', or
%           'None'. If not input there is a default value of 'none'.
%   
%   qual -- The quality of the compressed movie with values over [1 100],
%           this parameter does not have any effect on uncompressed movies.
%           If not input there is a default value of 100.
%
%   L    -- 'Length' of tracks, or in other words how many frames a pixel
%           remains lit after its initial frame. If not input there is a
%           default value of length 0.
%
%% Output Parameters
%
%   movie-- This output is a 1xp structured array with a custom colorscale
%           that will keep the color attributes the same as the original  
%           image series file with the added points from the objs matrix.
%
%   filename.avi -- Self explanatory.
%
%% Method
%1)For every frame there is a corresponding set of objects.
%
%2)Add each object to the corresponding frame through a single colored
%pixel.
%
%3)If you want to show previous positions it changes the color so to that 
%no pixel is confused for being the newest pixel in an image.
%
%4)Use the new 4D image series array to create a MATLAB structured array in
%the format of a movie file, this structure array will print out so that it
%may be saved if desired.
%
%5)Use the created structure array to create an avi movie using the
%built-in function of movie2avi(...)
%
%% Author
%
%vidtracks.m
%Richard Holton
%Created: April 28, 2009
%
%Last modified: May 06, 2009
%
function [ movie ] = vidtracks(im, objs, fps, filename, comp, qual,L)
%% Defualt Parameters
%Specifies for variables : FPS,filename,comp,qual and L a defined default
%value.
tic
if exist('L','var')==0
    L = 0;      %Default of no subsequent frames for pixels
end

if exist('comp','var')==0
    comp = 'none';      %Default with no compression
end

if exist('qual','var')==0
    qual = 100;      %Default is highest quality video
end

if exist('fps','var')==0
    fps = 10;      %Default of 10FPS
end

if exist('filename','var')==0
    filename = 'videotracks.avi'; %Default filename for the movie
end

%% Pre-allocation and sizing of variables
%These are useful variables for later and for speeding up the loops.

dimim = size(im);          %Finds dimensions of original image

newim=zeros([dimim(1,1) dimim(1,2) 3 (dimim(1,3)+L)], 'uint8'); %Pre-allocates image 
                                                       %for speed
unqfrm = (1:dimim(1,3)); %Creates a unique frame vector


%% Creating a color image series from the monochrome

for k = unqfrm
    frm_mat = repmat(im(:,:,k),[1,1,3]); %Takes kth frame of im and repeats 
                                   %3 times for mono-->color
    newim(:,:,:,k) = frm_mat;   %Replaces kth frame with repeat of the im
end

%Repeating last frame for L extra frames so that the movie doesn't end with
%color pixels and black background only if L>0

lst_frm = repmat(im(:,:,unqfrm(end)),[1,1,3]);

if L>0
    for j = 1:L
    newim(:,:,:,(dimim(1,3)+j))=lst_frm;
    end
end

%% Objs file modification
% This section modifies the objs file so that the data can be put into the
% integer indexed image series

%Rounding to whole pixel values in (x,y)
objs = round(objs);
dimobj = size(objs);%Finding how many coordinate pairs exist

%Keeping obj pixels inside boundaries of the image, so rounding did not
%effectively move the object's pixel out of the image
for i = 1:dimobj(2)
for j = 1:2

    if (objs(2,i)>dimim(1)) %Correcting for y>y-boundary
       objs(2,i)=dimim(1);
    end
    
    if (objs(1,i)>dimim(2)) %Correcting for x>x-boundary
       objs(1,i)=dimim(2);
    end
    
    
    if (objs(j,i)<1) %Correcting for values that are not in the matrix
        objs(j,i)=1;
    end
end
end

%% Creating the 4D image array
%Taking points from frame specific objs and putting the points on their 
%respective frames

for m = unqfrm
    
    obfrm = objs(:, ismember(objs(5,:),m));  % object matrix for frame m
    
    sizfrm = size(obfrm); %Facilitates making the for additive
    
    %Here I am adding the points to the image matrix, and if there are
    %trails I am adding the lingering and changing color trails the color
    %goes from bright green to purple to dim purple
    
    for k = 1:sizfrm(1,2)
    for t = 0:L
    newim(obfrm(2,k), obfrm(1,k), :, m+t)=[ (255-50*t) (50*t)  (50*t)];
    end
    end
end

%Making the image file a compatable format for MATLAB
newim = uint8(newim);

%% Making the structured array
% This takes the 4D image array into a matlab movie structured array
% format.

%Pre-allocation of the colorscale array
gray8=zeros(256,3);

for j=1:256 %Creates colorscale
gray8(j,1:3) = (j-1)/256.0;
end

%Adds L frames to the number of unique frames to facilitate the next step
%if there are trails
if L>0
    for b = 1:L
        unqfrm=[unqfrm (dimim(1,3)+b)];
    end
end
%Pre-allocation of the structure array for speed
movie=struct('cdata',{},'colormap',{});

for k = unqfrm      %Takes total frames and makes a structure array for movie
    movie(k).cdata=newim(:,:,:,k);%This is the data component of the array
    movie(k).colormap=gray8;%This is the colormap of the array
end

%% Making the actual movie
%This function takes the new movie structured array to an avi video file
%with the format movie2avi(movie,filename,'param',val,'param',val,...)

movie2avi(movie,filename,'compression',comp,'quality',qual,'fps',fps);
toc
end