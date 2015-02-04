function [gutMeshVelsPCoords, thetas] = mapToLocalCoords(gutMeshVels, mSlopes)

gutMeshVelsPCoords=gutMeshVels;
thetaStarTop=atan2(squeeze(mSlopes(:,2,1)),squeeze(mSlopes(:,1,1)));
thetaStarBottom=atan2(squeeze(mSlopes(:,2,2)),squeeze(mSlopes(:,1,2)));
thetaTop=thetaStarTop-pi/2;
thetaBottom=thetaStarBottom-pi/2;
thetas=[thetaTop, thetaBottom];

for i=1:size(thetaTop,1)
    gutMeshVelsPCoords(1:end/2,i,1,:)=gutMeshVels(1:end/2,i,1,:)*cos(thetaTop(i))+gutMeshVels(1:end/2,i,2,:)*sin(thetaTop(i));
    gutMeshVelsPCoords((end/2+1):end,i,1,:)=gutMeshVels((end/2+1):end,i,1,:)*cos(thetaBottom(i))+gutMeshVels((end/2+1):end,i,2,:)*sin(thetaBottom(i));
    gutMeshVelsPCoords(1:end/2,i,2,:)=-gutMeshVels(1:end/2,i,1,:)*sin(thetaTop(i))+gutMeshVels(1:end/2,i,2,:)*cos(thetaTop(i));
    gutMeshVelsPCoords((end/2+1):end,i,2,:)=-gutMeshVels((end/2+1):end,i,1,:)*sin(thetaBottom(i))+gutMeshVels((end/2+1):end,i,2,:)*cos(thetaBottom(i));
end

end