function[] = JMPGroupedDotIDGray3DMapGenerator(TPN, DotType, OutputGrayLevel)
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

if OutputGrayLevel > 255;
    OutputGrayLevel = 255;
end

%% Draw pass dots in 3-D in different colors
DotIDMapGray=zeros(Grouped.ImSize, 'uint8');
for i = 1:Grouped.Num;
    DotIDMapGray(Grouped.Vox(i).Ind)=OutputGrayLevel;
end
NumZ = Grouped.ImSize(3);

if DotType == 'Post';
    SavingFileName = 'find\GroupedDotIDGrayMap3DPost.tif';
elseif DotType == 'Colo';
    SavingFileName = 'find\GroupedDotIDGrayMap3DColo.tif';
end

imwrite(DotIDMapGray(:,:,1), [TPN SavingFileName], 'tif', 'compression', 'none'); %write first z plane
if NumZ > 1; %write the rest of the z planes
    for i=2:NumZ
        imwrite(DotIDMapGray(:,:,i), [TPN SavingFileName], 'tif', 'compression', 'none', 'WriteMode', 'append');
    end
end

