% To do: rename variables such that gut positions are x,y, original velocities are v_x,v_y, and new velocities are v_u,v_v

function gutMeshVels=interpolateVelocities(gutMesh, x, y, u_filt, v_filt)

nT=size(u_filt,1)-1; % For nT frames, there should have only been nT-1 elements, instead they made the nTth element [] for some reason...
gutMeshVels=zeros(size(gutMesh,1),size(gutMesh,2),size(gutMesh,3),nT); % Ordered U=1, V=2

% Progress bar
progtitle = sprintf('Interpolating fram');
progbar = waitbar(0, progtitle);  % will display progress

for i=1:nT 
    
    % Progress bar update
    waitbar(i/nT, progbar, ...
        strcat(progtitle, sprintf('e %d of %d', i, nT)));
    
    Xq=gutMesh(:,:,1);
    Yq=gutMesh(:,:,2);
    ex=x{i};
    why=y{i};
    V=v_filt{i};
    U=u_filt{i};
    %Uq=interp2(ex(:),why(:),U(:),Xq(:),Yq(:));
    %Vq=interp2(ex(:),why(:),V(:),Xq(:),Yq(:));
    %gutMeshVels(:,:,1,i)=reshape(Uq,[size(gutMesh,1), size(gutMesh,2)]);
    %gutMeshVels(:,:,2,i)=reshape(Vq,[size(gutMesh,1), size(gutMesh,2)]);
    SIU=scatteredInterpolant(ex(:),why(:),U(:));
    SIV=scatteredInterpolant(ex(:),why(:),V(:));
    mU=SIU(Xq(:),Yq(:));
    mV=SIV(Xq(:),Yq(:));
    gutMeshVels(:,:,1,i)=reshape(mU,size(Xq));
    gutMeshVels(:,:,2,i)=reshape(mV,size(Xq));
    
end

close(progbar);

end