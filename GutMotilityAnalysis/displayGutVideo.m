function displayGutVideo(gutMesh, gutMeshVels, gutMeshVelsPCoords, thetas, imPath, filetype)

% Load data and images from directory
matData=dir(strcat(imPath,filesep,'*.mat')); % Assumes filesep at end of imPath
load(strcat(imPath,filesep,matData(1).name));
ims=dir(strcat(imPath,filesep,filetype));
nT=size(ims,1)-1; % differencing frames obviously leads to n-1 frames
%cd(imPath);

% Initialize variables
writerObj = VideoWriter('animation.avi','Uncompressed AVI');
velMultiple=5;

% Open video writing code, initialize settings
open(writerObj);
figure;
set(gcf,'Renderer','zbuffer');

for i=1:nT
    
    % Get image
    im=imread(strcat(imPath,filesep,ims(i).name));
   
    % Get full vector field for quiver plot
    qx=gutMesh(:,:,1);
    qy=gutMesh(:,:,2);
    qu=velMultiple*gutMeshVels(:,:,1,i);
    qv=velMultiple*gutMeshVels(:,:,2,i);
    
    % Get local representations of components
    qup=velMultiple*squeeze(gutMeshVelsPCoords(:,:,1,i));
    qvp=velMultiple*squeeze(gutMeshVelsPCoords(:,:,2,i));
    % Re-project each component onto x y axes for visual representation
    qupx=qup; % This is just to get the size right
    qupx(1:end/2,:)=qup(1:end/2,:)*cos(thetas(1)); % Top
    qupx((end/2+1):end,:)=qup((end/2+1):end,:)*cos(thetas(2)); % Bottom
    qupy=qup;
    qupy(1:end/2,:)=qup(1:end/2,:)*sin(thetas(1));
    qupy((end/2+1):end,:)=qup((end/2+1):end,:)*sin(thetas(2));
    qvpx=qvp;
    qvpx(1:end/2,:)=-qvp(1:end/2,:)*sin(thetas(1));
    qvpx((end/2+1):end,:)=-qvp((end/2+1):end,:)*sin(thetas(2));
    qvpy=qvp;
    qvpy(1:end/2,:)=qvp(1:end/2,:)*cos(thetas(1));
    qvpy((end/2+1):end,:)=qvp((end/2+1):end,:)*cos(thetas(2));
    
    imshow(im, []);
    hold on;
    quiver(qx,qy,qu,qv,0,'r');
    %quiver(qx,qy,qupx,qupy,0,'b');
    %quiver(qx,qy,qvpx,qvpy,0,'b');
    hold off;
    
    % Write image to video
    frame = getframe;
    writeVideo(writerObj,frame);
    
end

% Close video writing code
close(writerObj);

end