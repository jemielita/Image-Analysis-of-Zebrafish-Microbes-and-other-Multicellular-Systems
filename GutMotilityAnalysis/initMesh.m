% Inputs: impath: String similar to 'C:/User/.../folder'
%         filetype: String of the form '*.png'
% To do: rename variables such that gut positions are x,y, original velocities are v_x,v_y, and new velocities are v_u,v_v

function [gutMesh, mSlopes, x, y, u_filt, v_filt] = initMesh(imPath,subDir)



% Load data and image from directory
matData=dir(strcat(imPath,filesep,subDir,filesep,'PIVData_*.mat'));
maskVars=dir(strcat(imPath,filesep,'maskVars*.mat'));
matFile=strcat(imPath,filesep,subDir,filesep,matData(1).name);
maskFile=strcat(imPath,filesep,maskVars(1).name);
load(matFile);
load(maskFile);
ex=x{1};
why=y{1};
continueBool=0;
splineNFineness=10000;


% Dynamically allocate mesh points
% Determine useful points, dynamically allocate NU, NV (points
% along/away from middle axis)
psIn=inpolygon(ex(:),why(:),gutOutlinePoly(:,1),gutOutlinePoly(:,2));
logicPsIn = reshape(psIn,size(ex));
NVDist=sum(logicPsIn,1); % Assumes gut is roughly horizontal
NV=2*ceil(mean(NVDist)/2);
NUDist=sum(logicPsIn,1);
NUDist(NUDist>0)=1;
NU=sum(NUDist); % "Raw" NU, but I want it nicer
NUrem=idivide(uint8(NU),10);
NU=double((NUrem+1)*10); % Just because I want an even, divisible by 10, NV
finalExesTop=zeros(1,NU+1);
finalExesBottom=zeros(1,NU+1);
gutMesh=zeros(NV,NU,2);
mSlopes=zeros(NU,2,2); % of the form (position down gut, dx or dy, top or bottom)

% Interpolation won't work without removing duplicates
gutMiddlePolyUnTop=unique(gutMiddlePolyTop,'rows');
gutMiddlePolyUnBottom=unique(gutMiddlePolyBottom,'rows');
% Interpolate data, but only for each column
dUTop=ceil(size(gutMiddlePolyUnTop,1)/(NU+1));
dUBottom=ceil(size(gutMiddlePolyUnBottom,1)/(NU+1));
exTop=gutMiddlePolyUnTop(1:dUTop:end,1);
exBottom=gutMiddlePolyUnBottom(1:dUBottom:end,1);
whyTop=gutMiddlePolyUnTop(1:dUTop:end,2);
whyBottom=gutMiddlePolyUnBottom(1:dUBottom:end,2);
csTop=spline(exTop,whyTop);
csBottom=spline(exBottom,whyBottom);

% Subdivide the spline into NU even sections (so NU+1 vertices)
dExTop=(exTop(end)-exTop(1))/splineNFineness;
dExBottom=(exBottom(end)-exBottom(1))/splineNFineness;
exesTop=exTop(1):dExTop:exTop(end);
exesBottom=exBottom(1):dExBottom:exBottom(end);
curvezTop=ppval(csTop,exesTop);
curvezBottom=ppval(csBottom,exesBottom);
STotalTop=sum(sqrt(dExTop^2+diff(curvezTop).^2)); % Obtain the total length of the curve drawn
STotalBottom=sum(sqrt(dExBottom^2+diff(curvezBottom).^2)); % Obtain the total length of the curve drawn
dSTop=STotalTop/NU; % Arc length of N subdivisions
dSBottom=STotalBottom/NU; % Arc length of N subdivisions
partialSSumTop=cumsum(sqrt(dExTop^2+diff(curvezTop).^2)); % Partial sum of arcs
partialSSumBottom=cumsum(sqrt(dExBottom^2+diff(curvezBottom).^2)); % Partial sum of arcs
secSNumTop=uint32(floor(partialSSumTop/dSTop)); % Evenly number exes by arc length
secSNumBottom=uint32(floor(partialSSumBottom/dSBottom)); % Evenly number exes by arc length
for i=1:NU+1
    tempsNTop=find(secSNumTop==i-1);
    tempsNBottom=find(secSNumBottom==i-1);
    finalExesTop(i)=exesTop(tempsNTop(1)); % Vector of the y's in exes for which the y's in secSNum are first unique
    finalExesBottom(i)=exesBottom(tempsNBottom(1));
end

%     % display fitted function
%     close all;
%     imH = imshow( im, [] );
%     imcontrast( imH ) ;
%     hold on;
    fullPolyX=[gutOutlinePoly(:,1); gutOutlinePoly(1,1)];
    fullPolyY=[gutOutlinePoly(:,2); gutOutlinePoly(1,2)];
%     plot(fullPolyX,fullPolyY,'r-');
    finalWhysTop=ppval(csTop,finalExesTop);
    finalWhysBottom=ppval(csBottom,finalExesBottom);
%     plot(finalExesTop,finalWhysTop,'gx-');
%     plot(finalExesBottom,finalWhysBottom,'gx-');

%% Generate mesh based on orthogonal vectors
for i=1:NU
    
    % Obtain mathematical function of the line from which centers will come
    curOrthMTop=-(finalExesTop(i+1)-finalExesTop(i))/(finalWhysTop(i+1)-finalWhysTop(i));
    curOrthMBottom=-(finalExesBottom(i+1)-finalExesBottom(i))/(finalWhysBottom(i+1)-finalWhysBottom(i));% Orthogonal slope
    midPointTop=[(finalExesTop(i+1)+finalExesTop(i))/2,(finalWhysTop(i+1)+finalWhysTop(i))/2 ];
    midPointBottom=[(finalExesBottom(i+1)+finalExesBottom(i))/2,(finalWhysBottom(i+1)+finalWhysBottom(i))/2 ];
    bTop=-curOrthMTop*midPointTop(1)+midPointTop(2);
    bBottom=-curOrthMBottom*midPointBottom(1)+midPointBottom(2);
    y1=1;
    y2=size(im,1);
    x1Top=(y1-bTop)/curOrthMTop;
    x1Bottom=(y1-bBottom)/curOrthMBottom;
    x2Top=(y2-bTop)/curOrthMTop;
    x2Bottom=(y2-bBottom)/curOrthMBottom;
    
    % Find their intersection with the gut edge previously drawn
    [exIntTop,whyIntTop]=polyxpoly([x1Top, x2Top],[y1, y2],fullPolyX,fullPolyY);
    [exIntBottom,whyIntBottom]=polyxpoly([x1Bottom, x2Bottom],[y1, y2],fullPolyX,fullPolyY);
    % This looks complicated: Keep in mind the intersection gives two
    % points, so bottom/top may refer to which gut midline or it may refer
    % to which intersection is in question. Further obfuscated by images
    % being upside down...
    topYITop=max(whyIntTop);
    topYIBottom=max(whyIntBottom);
    topCorXITop=exIntTop(whyIntTop==topYITop);
    topCorXIBottom=exIntBottom(whyIntBottom==topYIBottom);
    bottomYITop=min(whyIntTop);
    bottomYIBottom=min(whyIntBottom);
    bottomCorXITop=exIntTop(whyIntTop==bottomYITop);
    bottomCorXIBottom=exIntBottom(whyIntBottom==bottomYIBottom);
    dYIBottom=topYIBottom-midPointBottom(2);
    dXIBottom=topCorXIBottom-midPointBottom(1);
    dYITop=bottomYITop-midPointTop(2);
    dXITop=bottomCorXITop-midPointTop(1);
    mSlopes(i,1,1)=dXITop;
    mSlopes(i,1,2)=-dXIBottom; % minus for inconsistency
    mSlopes(i,2,1)=dYITop;
    mSlopes(i,2,2)=-dYIBottom; % minus for inconsistency
    
%     % display intersections
%     plot(midPointTop(1),midPointTop(2),'bx');
%     plot(midPointBottom(1),midPointBottom(2),'bx');
%     plot(bottomCorXITop,bottomYITop,'rx');
%     plot(bottomCorXIBottom,bottomYIBottom,'rx');
%     plot(topCorXITop,topYITop,'rx');
%     plot(topCorXIBottom,topYIBottom,'rx');
    
    % Designate mesh locations (divide in to upper and lower for ease of indexing
    for j=1:NV/2
        
        % Top mesh locations
        gutMesh(NV-j+1,i,1)=round(midPointTop(1)+j*dXITop/(NV/2+1)); % curOrthM ratio for sign
        gutMesh(NV-j+1,i,2)=round(midPointTop(2)+j*dYITop/(NV/2+1));
                
        % Bottom mesh locations
        gutMesh(j,i,1)=round(midPointBottom(1)+j*dXIBottom/(NV/2+1)); % curOrthM ratio for sign
        gutMesh(j,i,2)=round(midPointBottom(2)+j*dYIBottom/(NV/2+1));
        
    end
    
end

% % Visualize
% for i=1:NV
%     for j=1:NU
%         plot(gutMesh(i,j,1),gutMesh(i,j,2),'gx');
%         hold on;
%     end
% end
% hold off;
% pause; % Wait till user likes what they see...

% close all;

% In the event there was no postprocessing?
if(~exist('u_filt','var'))
    u_filt=u;
end
if(~exist('v_filt','var'))
    v_filt=v;
end

end