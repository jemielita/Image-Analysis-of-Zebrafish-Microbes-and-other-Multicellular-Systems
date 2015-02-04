function initMask(imPath,filetype,savePrevDirBool)

%% Read first image
ims=dir(strcat(imPath,filesep,filetype));
im=imread(strcat(imPath,filesep,ims(1).name));

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
    gutMiddleBottom = impoly( 'Closed', false );
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
if( savePrevDirBool==1)
    immPath=strcat(immPath,filesep,'..');
end
theFileN=strcat(immPath,filesep,'maskVars_',date,'.mat');
clear imH;
save(theFileN);

end