function[] = JMPSGPassDimDotIDGray3DMapGenerator(TPN, DotType)

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

%% Draw pass dots in 3-D in different colors
if isfield(SG,'passI')
    Pass = SG.passI;
else
    Pass = SG.passF;
end


%get dim dots that are border of pass and no pass
v.iTMaxLowerLimit = 0;
v.iTMaxUpperLimit = 6.5;
v.iTSumLowerLimit = 20;
v.iTSumUpperLimit = 80;
v.MeanBrightLowerLimit = 10;
v.MeanBrightUpperLimit = 30;

if DotType == 'Colo';
    v.DotDiameterOverCentroidStdUpperLimit = 0.9;
    v.DotDiameterOverCentroidStdLowerLimit = 0.5;
end
    

v = HOgetVars(v,'Narrow the range of dots that you want to classify into pass or no pass.');

iTMaxDotIDs = find((Dots.ITMax > v.iTMaxLowerLimit) & (Dots.ITMax < v.iTMaxUpperLimit));
iTMaxDots = zeros(Dots.Num,1);
iTMaxDots(iTMaxDotIDs,1)=1;
iTSumDotIDs = find((Dots.ItSum > v.iTSumLowerLimit) & (Dots.ItSum < v.iTSumUpperLimit));
iTSumDots = zeros(Dots.Num,1);
iTSumDots(iTSumDotIDs,1)=1;
MeanBrightDotIDs = find((Dots.MeanBright > v.MeanBrightLowerLimit) & (Dots.MeanBright < v.MeanBrightUpperLimit));
MeanBrightDots = zeros(Dots.Num,1);
MeanBrightDots(MeanBrightDotIDs,1)=1;

if DotType == 'Colo';
    DotDiameterOverCentroidStdDotIDs = find((Dots.DotDiameterOverCentroidStd > v.DotDiameterOverCentroidStdLowerLimit) & (Dots.DotDiameterOverCentroidStd < v.DotDiameterOverCentroidStdUpperLimit));
    DotDiameterOverCentroidStdDots = zeros(Dots.Num,1);
    DotDiameterOverCentroidStdDots(DotDiameterOverCentroidStdDotIDs,1)=1;
end


if DotType == 'Colo';
    Pass1 = Pass & iTMaxDots & iTSumDots & MeanBrightDots;
    Pass2 = Pass & DotDiameterOverCentroidStdDots;
    Pass = Pass1 | Pass2;
else
    Pass = Pass & iTMaxDots & iTSumDots & MeanBrightDots;       
end

P=find(Pass); % list of passing puncta
disp('Number of dots in the chosen conditions is');
length(P)

DotIDMapGray=zeros(Dots.ImSize, 'uint8');
for i = 1: length(P)
    DotIDMapGray(Dots.Vox(P(i)).Ind)=50;
end
NumZ = Dots.ImSize(3);
imwrite(DotIDMapGray(:,:,1), [TPN 'find\PassDimDotIDGrayMap3D.tif'], 'tif', 'compression', 'none'); %write first z plane
if NumZ > 1; %write the rest of the z planes
    for i=2:NumZ
        imwrite(DotIDMapGray(:,:,i), [TPN 'find\PassDimDotIDGrayMap3D.tif'], 'tif', 'compression', 'none', 'WriteMode', 'append');
    end
end

Blank3D = zeros(Dots.ImSize, 'uint8');
imwrite(Blank3D(:,:,1), [TPN 'find\Blank3D.tif'], 'tif', 'compression', 'none'); %write first z plane
if NumZ > 1; %write the rest of the z planes
    for i=2:NumZ
        imwrite(Blank3D(:,:,i), [TPN 'find\Blank3D.tif'], 'tif', 'compression', 'none', 'WriteMode', 'append');
    end
end

