%% Run all Programs up to 1/19/09
%%Sets up sequence of programs to run to find puncta on labeled processes
%%Copyright Josh Morgan and Daniel Kerchensteiner 2005-2009

%% Comments and Error
% 
% 052709 Adams Version of Newer started 
% 091009 need to correct anaSG TCrit output of image to match Dots output to
%   imaris. Imaris Dots are correct, but TCrit is wrong.adam
% 110309 -74 'added v.itMaxMin to establish minimum iT threshold first
%   passing; see dotFinder'.adam
% 011010 HO added the saving of TPN, and the saving of the image name (the
% name of the cell etc) under Settings.ImageName.
% 021210 HO changed the cutOff criteria for estimating the contour of dots
% in dotfinding from just setting one cutOff parameter to setting both the 
% upper bound and the lower bound of cutOff. This will give more control
% and also be more intuitive. If upper bound is 0.4 for example, smallest
% ITMax dots (actually the smallest dot was assumed to be ITMax = 0 for
% simplicity although not existing) will take voxels whose iterations 
% counted at least >40% of max iteration of the dot, and cut the bottom 40%
% from the dot contour estimation. If the lower bound is set to 0.1,
% possible largest ITMax dots will keep top 90% of voxels as the contour of
% the dots. See dotFinderInMask for the change.
% 060810 HO since I have to process images with different xyz voxel size
% (for BCs in Grm6tdTom mice), I changed blockbuffer, maxDotSize,
% minDotSize and minFinalDotSize from simply giving some nubmer of voxels
% to the number of voxels converted from desired volume in um3.
% 062510 HO instead of saving the image name under Settings, I generated
% CellInfo.mat that holds all the information about the cell so that later
% in analysis you can use these informations to sort data from many cells.
% 020811 HO added itMin in addition to itMaxMin for dotfinder parameter.
% Now itMin sets minimum iteration threshold to be considered as non-noise
% voxels. Any voxel below this value is removed as potentially a part of
% dots before taken to watershed. Then, itMaxMin removes dots whose ITMax
% is lower than itMaxMin from the registration into Dots.
% 061711 HO added Imaris yes no, which Adam had created.

%%
TPN = GetMyDir; %% Retrieves path for Folder that contains image folder (I)
save([TPN 'TPN.mat'], 'TPN');

%get cell info HO 6/25/2010
v.Animal = 'WT C57BL6';%'Grm6Tom';%'MG6YSTENTC5';%'MG6YSDTA1';%'aPax6CreMG6YSDTA1Grm6GFP';%'aPax6CreMG6YSDTA1';%'MG6YSTENTC3Psubset';%%'Gus8GFP';%
v.CellName = '150531c1';%'120212c5';%'Josh022dC';
v.CellType = 'OFF-transient RGC';%'A-type ON RGC';%'ON alpha RGC';%'G17 DSGC';%'G1 or 2 or 6 or 10 ON GC';%
v.Age = 30;
v.Prep = 'whole-mount';
v.Bullet1 = 'CMVPSD95CFP';%'CMVPSD95mCherry';%
v.Bullet2 = 'CMVtdTomato';%'None';%'CMVCerulean';%
v.Bullet3 = 'None';%
v.Immuno1 = 'None';%'CtBP2Alexa514';%'CtBP2DyLight649';%'Syt2DyLight649';%'CtBP2Alexa568';%
v.Immuno2 = 'None';%'GFPDyLight649';%'None';%'Syt2DyLight649';%'CaBP5DyLight649';%'RibeyeAdomainAlexa568';
v.Immuno3 = 'None';%

v = JMPgetVars(v,'Enter cell information');
CellInfo = v;
save([TPN 'CellInfo.mat'], 'CellInfo')
    
%% Find out what has been done so far
load([TPN 'Settings.mat']);
load([TPN 'data.mat']); %load comma-delimited files of dots position

Dots.Pos = data;
Dots.Pos(:,3) = Dots.Pos(:,3) + 30;
PosX=Dots.Pos(:,1);
PosY=Dots.Pos(:,2);
Dots.Pos(:,1) = PosY;
Dots.Pos(:,2) = PosX;
Dots.Pos(:,1) = - Dots.Pos(:,1) + Settings.ImInfo.yNumVox; + 1;

Dots.Vol = ones(1,size(data,1));
save Dots Dots;

mkdir([TPN 'find']);
SG.passF = ones(1,size(data,1));
save([TPN 'find\SG.mat'],'SG')

%Use spectrum and change intensity 0 to black for both Imaris and Fiji.
%JMPSGPassDotIDColorful3DMapGenerator(TPN, 'Post', 'Pass') %6/17/2011 HO
%JMPSGPassDotIDColorful3DMapGenerator(TPN, 'Post', 'NoPs') %if you want to display nonpass dots
%JMPSGPassDotIDColorful3DMapGenerator(TPN, 'Post', 'Both') %if you want to display all the dots

%open JMPanaDots2Imar %6/17/2011 HO

%Use Imaris to see where is the good minimum threshold for ITMax and ratio.
%Run SG again using that threshold, play with PCA.
%Then come back to Imaris to do yes and no. Use the colorful DotID 3-D map
%in Imaris to find potential noise component in multi-peak dots. Use Spots
%function, HOiPassingSpots2MLDotsVer (not the original grouped version) to
%save passI under SG. Repeat SG. If everything is fine, proceed to grouping.

JMPanaSGPCA(TPN) %do not repeat the first pass, then it will include Imaris yes no at the end.

JMPanaGroup(TPN)%use this code, don't do manually


JMPanaCBGrouped(TPN) %7/6/2010 HO
JMPanaRdGrouped(TPN) %7/6/2010 HO

%add MaxRawBright under Grouped 5/28/2012 HO
load([TPN 'Grouped.mat']);
PostDotMaxRawBright = zeros(1, Grouped.Num);
for i=1:Grouped.Num
    PostDotMaxRawBright(i) = max(Grouped.Vox(i).RawBright);
end
Grouped.MaxRawBright = PostDotMaxRawBright;
save([TPN 'Grouped.mat'], 'Grouped');
clear PostDotMaxRawBright Grouped;

%JMPGroupedDotIDGray3DMapGenerator(TPN, 'Post', 50) %3/6/2012 HO
%JMPGroupedDotIDColorful3DMapGenerator(TPN, 'Post') %3/6/2012 HO

%register the path length of each dot from soma 10/18/2011 HO
%The function will also spit out the distance of dots to the closest Skel.
load([TPN 'Grouped.mat']);
load([TPN 'Settings.mat']);
load([TPN 'SkelFiner.mat']); %use finer version for accuracy
Grouped = JMPClosestSkelFinder(Settings, Grouped, Skel);
save([TPN 'Grouped.mat'], 'Grouped');
clear Skel Grouped;

%open JMPanaGrouped2Imar %6/16/2011 HO

%open JMPRunAnalysis


%% 
