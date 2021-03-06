function[P,RealDif]=jmboot(Dat1,Dat2,reps);

if ~exist('reps','var'), reps=10000;end

if size(Dat1,2)>1, Dat1=Dat1'; end
if size(Dat2,2)>1, Dat2=Dat2'; end

meanDat1=mean(Dat1);
Size1=size(Dat1,1);
meanDat2=mean(Dat2);
Size2=size(Dat2,1);

RealDif=abs(meanDat1-meanDat2);

poolDat=cat(1,Dat1,Dat2);
SizeP=size(poolDat,1);

Ind=ones(SizeP,1);
Ind(Size1+1:size(Ind,1))=2;
scatter(Ind,poolDat,'Marker','.'),pause


clear tDif
for i = 1:reps
    Pick1=fix(rand(Size1,1)*SizeP)+1;
    Pick2=fix(rand(Size2,1)*SizeP)+1;
    tDat1=poolDat(Pick1);
    tDat2=poolDat(Pick2);
    mDat1=mean(tDat1);
    mDat2=mean(tDat2);
    tDif(i,1)=abs(mDat1-mDat2);
    
    scatter(Ind,[tDat1;tDat2],'Marker','.'), pause
    
end

hist(tDif),pause(.1)
reps;
P=sum(tDif>=RealDif)/size(tDif,1);

