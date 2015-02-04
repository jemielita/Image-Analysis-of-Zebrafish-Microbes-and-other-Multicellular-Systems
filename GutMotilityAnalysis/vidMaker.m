nT=size(u,1);
merp=cell2mat(u(1));
nR=size(merp,1);
nC=size(merp,2);
%rMat=zeros(nR,nC,nT,2);
magR=zeros(nR,nC,nT);
granularity=2;
bitDepth=8;
numSTDImage=5;

for i=1:nT
    magR(:,:,i)=real(sqrt(cell2mat(u(i)).^2+cell2mat(v(i)).^2));
end

magR=real(magR);
%%
ex=cell2mat(x(1));
ex=ex(1,:);
why=cell2mat(y(1));
why=why(:,1);
xi=ex(1):granularity:ex(end);
yi=why(1):granularity:why(end);

magR(isnan(magR))=0;

% Scale data
minN=min(magR(:));
maxN=max(magR(:));
%magR=(2^bitDepth-1)*(magR-minN)/(maxN-minN);

% Rescale data
meanN=mean(magR(:));
stdN=std(magR(:));
maxN=(numSTDImage*stdN+meanN)*(numSTDImage*stdN+meanN<2^bitDepth)+(numSTDImage*stdN+meanN>=2^bitDepth)*(2^bitDepth-1);
minN=(meanN-numSTDImage*stdN)*(meanN-numSTDImage*stdN>=0);
magR(magR>maxN)=maxN;
magR(magR<minN)=minN;
magR=((2^bitDepth-1)*(magR-minN)/(maxN-minN));

for i=1:nT
    nerp=uint8(griddata(ex,why,magR(:,:,i),xi,yi'));
    imshow(nerp,[]);
    colormap(jet);
    imwrite(nerp,jet,sprintf('test%04i.png',i),'BitDepth',bitDepth);
end