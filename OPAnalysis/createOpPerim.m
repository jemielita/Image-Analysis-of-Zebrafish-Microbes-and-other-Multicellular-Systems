%Save a file containing the 3D points that define the perimeter of the
%opercle.

function [] = createOpPerim(varargin)
if nargin ==1
    fileDir = varargin{1};
elseif nargin==0
    fileDir = uigetdir('C:\Jemielita\markers', 'Select directory to load markers from');
end


for i=1:144
    
    fN = [fileDir filesep 'OP_Scan', sprintf('%03d', i), '.mat'];
    imT = load(fN);
   % imT = imT.mO-imT.mD;
    %imT = imT>0;
    imT = imT.imT;
    
    fN
    %Find the perimeter of these regions
    imPerim = zeros(size(imT));
    for j=1:size(imT,3)
        imPerim(:,:,j) = bwperim(imT(:,:,j));
    end
    
    indP = find(imPerim ==1);
    [xp, yp, zp] = ind2sub(size(imPerim), indP);
    zp = (1/0.1625)*zp;
    
    perimVal = cat(2, xp, yp, zp);
    perimVal = round(perimVal);
    
    %We'll use PCA to define the major axis of the opercle and then we'll get
    %the convex hull of the plane perpendicular to this line
    ind = find(imT==1);
    
    [x, y,z] = ind2sub(size(imT), ind);
    %rescaling the z axis to account for the spacing
    z = (1/0.1625)*z;
    
    X = cat(2, x,y,z);
    
    %Get the principal components
    [coeff,score,roots] = princomp(X);
    %We'll find a plane normal to the principal axis
    basis = coeff(:,2:3);
    
    normal = coeff(:,1); %The principal axis.
    
    [n,p] = size(X);
    meanX = mean(X,1);
    Xfit = repmat(meanX,n,1) + score(:,1:2)*coeff(:,1:2)';
    residuals = X - Xfit;
    
    %Getting points along the principal axis
    dirVect = coeff(:,1);
    t = [min(score(:,1))-.2, max(score(:,1))+.2];
    endpts = [meanX + t(1)*dirVect'; meanX + t(2)*dirVect'];
    
    
    
    conF = [fileDir, filesep,'OP_Scan', sprintf('%03d', i), 'perim.mat'];
    save(conF, 'imPerim','perimVal', 'basis', 'normal', 'endpts');
end

end