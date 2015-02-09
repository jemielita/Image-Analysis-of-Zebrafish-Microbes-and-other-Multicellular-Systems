function initMask(imPath,filetype,resReduce)

%% Read first image
% Use resReduce if opening image for the first time (-1 indicates this
% isn't the first time)
if(resReduce==-1)
    rR=0;
else
    rR=resReduce;
end
ims=dir(strcat(imPath,filesep,filetype));
im=imread(strcat(imPath,filesep,ims(1).name),'ReductionLevel',resReduce);

% Initialize variables
continueBool = 0;

%% Draw gut outline, gut center
while ( continueBool ~= 1 )
    
    close all;
    
    % Draw the boundary and gut center. Try to draw the centerline in a way
    % you'd want orthogonal vectors to orient themselves
    figure;
    imH = imshow( im, [] );
    imcontrast( imH ) ;
    gutOutline = impoly;
    gutOutlinePoly = getPosition( gutOutline );
    setColor( gutOutline, 'red' ); 
%     gutMiddleTop = imfreehand( 'Closed', false );
%     gutMiddleBottom = imfreehand( 'Closed', false );
    gutMiddleTop = impoly( 'Closed', false );
    %gutMiddleBottom = impoly( 'Closed', false );
    gutMiddleBottom = gutMiddleTop;
    gutMiddlePolyTop=getPosition( gutMiddleTop );
    gutMiddlePolyBottom = getPosition( gutMiddleBottom );
    setColor( gutMiddleTop,'green' ); 
    setColor( gutMiddleBottom,'green' ); 
    
    % Prompt user to see if they want to continue or redraw
    continueBool=menu( 'Are you satisfied with your drawing?', ...
        'Yes', 'No' );

end

close all;
immPath=imPath;
if( resReduce==-1)
    immPath=strcat(immPath,filesep,'..');
end
theFileN=strcat(immPath,filesep,'maskVars_',date,'.mat');
clear imH;
save(theFileN);

end