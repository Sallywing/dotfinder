function[] = JMPSGPassDotIDGray3DMapGenerator(TPN, DotType, OutputGrayLevel)

if ~exist('TPN')
    TPN = GetMyDir;
end

if DotType == 'Post';
    load([TPN 'Dots.mat']);
    load([TPN 'find\SG.mat']);
elseif DotType == 'Colo';
    load([TPN 'DotsColo.mat']);
    load([TPN 'find\SGColo.mat']);
end

if OutputGrayLevel > 255;
    OutputGrayLevel = 255;
end

%% Draw pass dots in 3-D in different colors
if isfield(SG,'passI')
    Pass = SG.passI;
else
    Pass = SG.passF;
end
P=find(Pass); % list of passing puncta
DotIDMapGray=zeros(Dots.ImSize, 'uint8');
for i = 1: length(P)
    DotIDMapGray(Dots.Vox(P(i)).Ind)=OutputGrayLevel;
end
NumZ = Dots.ImSize(3);

if DotType == 'Post';
    SavingFileName = 'find\PassDotIDGrayMap3DPost.tif';
elseif DotType == 'Colo';
    SavingFileName = 'find\PassDotIDGrayMap3DColo.tif';
end

imwrite(DotIDMapGray(:,:,1), [TPN SavingFileName], 'tif', 'compression', 'none'); %write first z plane
if NumZ > 1; %write the rest of the z planes
    for i=2:NumZ
        imwrite(DotIDMapGray(:,:,i), [TPN SavingFileName], 'tif', 'compression', 'none', 'WriteMode', 'append');
    end
end

