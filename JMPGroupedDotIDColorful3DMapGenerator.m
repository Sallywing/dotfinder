function[] = JMPGroupedDotIDColorful3DMapGenerator(TPN, DotType)
%modified from Dots version 3/6/2012 HO
if ~exist('TPN')
    TPN = GetMyDir;
end

if DotType == 'Post';
    load([TPN 'Grouped.mat']);
    %load([TPN 'find\SG.mat']);
elseif DotType == 'Colo';
    load([TPN 'GroupedColo.mat']);
    %load([TPN 'find\SGColo.mat']);
end

%% Draw pass dots in 3-D in different colors
DotIDMapColorful=zeros(Grouped.ImSize, 'uint8');
for i = 1:Grouped.Num;
    DotIDMapColorful(Grouped.Vox(i).Ind)=1+round(rand*254);
end
NumZ = Grouped.ImSize(3);

if DotType == 'Post';
    SavingFileName = 'find\GroupedDotIDColorfulMap3DPost.tif';
elseif DotType == 'Colo';
    SavingFileName = 'find\GroupedDotIDColorfulMap3DColo.tif';
end

imwrite(DotIDMapColorful(:,:,1), [TPN SavingFileName], 'tif', 'compression', 'none'); %write first z plane
if NumZ > 1; %write the rest of the z planes
    for i=2:NumZ
        imwrite(DotIDMapColorful(:,:,i), [TPN SavingFileName], 'tif', 'compression', 'none', 'WriteMode', 'append');
    end
end

