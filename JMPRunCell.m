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
DoAll.doAll = 0;
DoAll.read = 1;
DoAll.imaris = 0;
DoAll.skeleton = 0;
DoAll.dotfinder = 1;  % Set up new status varible
DoAll.ratio = 1;
DoAll.mask = 1;
DoAll.round = 1;
DoAll.smartGuide = 1;
DoAll.group = 1;

if exist([TPN 'Status.mat'])
    load([TPN 'Status.mat']) %Retreive previous progress
else
    Status = DoAll;
end

Status = JMPgetVars(Status, 'Which programs would you like to run?');
if Status.doAll
    Status = DoAll;
end

save([TPN 'Status.mat'],'Status')
Settings.Status = Status;

%% Set up necessary Directories
if isdir([TPN 'temp'])==0, mkdir([TPN 'temp']); end %create directory to store steps
if isdir([TPN 'data'])==0, mkdir([TPN 'data']); end %create directory to store steps

%% Get More Variables

if exist([TPN 'Settings.mat'])
    load([TPN 'Settings.mat'])
end

if ~isfield(Settings,'ImInfo')
    'Need to collect image info at least once'
    Status.read = 1;
end

%HO added puncta volume to voxel number conversion because images with
%different xyz resolution will be analyzed. 6/8/2010
Answer = inputdlg({sprintf(['xy resolution in um :\n']), sprintf(['z resolution in um :\n']), ...
  sprintf(['xy diameter of the max dot in um (normally 1) :\n']), ... %most largest CtBP2 puncta, which is elipsoid of 1um diameter for xy and 2um diamter for z, this will correspond to ~330 voxels with 0.103um xy 0.3um z step voxel dimention. HO 1/25/2010
  sprintf(['z diameter of the max dot in um (normally 2) :\n']), ...
  sprintf(['xy diameter of the min dot in um (normally 0.25) :\n']), ...
  sprintf(['z diameter of the min dot in um (normally 0.5) :\n'])}, ...
  'Volume to Voxel Number Conversion', 1, {'0.103','0.3','1','2','0.25','0.5'});
if isempty(Answer), return, end

MaxDotSize = (4/3*pi*(str2double(Answer(3))/2)*(str2double(Answer(3))/2)*(str2double(Answer(4))/2)) / (str2double(Answer(1))*str2double(Answer(1))*str2double(Answer(2)));
MinDotSize = (4/3*pi*(str2double(Answer(5))/2)*(str2double(Answer(5))/2)*(str2double(Answer(6))/2)) / (str2double(Answer(1))*str2double(Answer(1))*str2double(Answer(2)));
BlockBuffer = round(1.5/str2double(Answer(1)));

if Status.dotfinder

    clear v
    v.blockSize = 90;
    v.blockBuffer=BlockBuffer; %changing this between 15 to 50 didn't make much difference, 10 could reduce the number of dots found, use 15 for safety. HO 1/5/2010 Then switched from 15 to BlockBuffer to process images with different resolution. HO 6/8/2010
    v.thresholdStep = 2;
    v.maxDotSize = MaxDotSize; %max dot size for single-peak dot DURING ITERATIVE THRESHOLDING, NOT FINAL, switched from 300 to MaxDotSize to process images with different resolution HO 6/8/2010
    v.minDotSize=3; %min dot size DURING ITERATIVE THRESHOLDING, NOT FINAL.
    v.MultiPeakDotSizeCorrectionFactor = 0; %added by HO 2/8/2011, maxDotSize*MultiPeakDotSizeCorrectionFactor will be added for each additional dot joined to the previous dot, see dotfinder. With my PSD95CFP dots, super multipeak dots are rare, so put 0 for this factor.
    %v.percentBackground = 0.90; %this is not used HO
    %v.punctaThreshold = 1; %this is not used HO
    v.itMin = 2; % added by HO 2/9/2011 minimum iterative threshold allowed to be analyzed as voxels belonging to any dot...filter to remove value '1' pass thresholds. value '2' is also mostly noise for PSD95 dots, so 3 is the good starting point HO 2/9/2011
    v.peakCutoffLowerBound = 0.2; %changed to the set threshold for all dots (0.2) after psychophysical testing with linescan and full 8-bit depth normalization HO 6/4/2010
    v.peakCutoffUpperBound = 0.2; %changed to the set threshold for all dots (0.2) after psychophysical testing with linescan and full 8-bit depth normalization HO 6/4/2010
    v.minFinalDotITMax = 3; % minimum ITMax allowed as FINAL dots. Any found dot whose ITMax is below this threshold value is removed from the registration into Dots. 5 will be the best for PSD95. HO 1/5/2010
    v.minFinalDotSize = MinDotSize; %minimum dot size allowed as FINAL dots, switched from 3 to MinDotSize to process images with different resolution HO 6/8/2010
    %v.roundThreshold = 50; %this is not used HO

    v = JMPgetVars(v,'Define Dotfinder Variables for Post dot');
    Settings.dotfinder = v;
    save([TPN 'Settings.mat'], 'Settings')
end

% if Status.skeleton
% 
%     clear v
%     v.minObjSize = 50;
%     v.minFillSize = 10;
%     v.maxSegLength = 5;
% 
%     v=getVars(v , 'Define Skeletonization Variables');
%     Settings.skeleton = v;
%     save([TPN 'Settings.mat'], 'Settings')
% end

clear Settings

%% Check out files
if Status.read
    JMPanaRead(TPN)
    Status.read=0
    save([TPN 'Status.mat'],'Status')
end

%% make finer Skel, also calculate path distance of skels from soma 10/18/2011 HO
load([TPN 'Skel.mat'])
load([TPN 'Settings.mat'])
Skel = JMPSkelPathLengthCalculator(Skel);
save([TPN 'Skel.mat'],'Skel')
SkelFiner = JMPSkelFinerGenerator(Skel, Settings.ImInfo .xyum);
clear Skel;
Skel = SkelFiner;
save([TPN 'SkelFiner.mat'], 'Skel');
Skel = JMPSkelPathLengthCalculator(Skel);
save([TPN 'SkelFiner.mat'], 'Skel');
clear Skel SkelFiner Settings;

%% Run Dot Processing
%Skip if using Imaris Dot finding - JMP

% if Status.imaris
%     'Loading Imaris Skeleton'
%     JMPanaImar(TPN)
%     Status.imaris = 0;
%     save([TPN 'Status.mat'],'Status')
% end
% if Status.skeleton
%     'Finding Skel'
%     anaSk(TPN)
%     Status.skeleton=0;
%     save([TPN 'Status.mat'],'Status')
% end

%% Run dot finding
%Skip if using Imaris Dot finding - JMP

if Status.dotfinder
    'Finding Dots'
    JMPdotFinderInMaskWS(TPN)
    %anaDF(TPN)
    Status.dotfinder=0;
    save([TPN 'Status.mat'],'Status')
end
if Status.ratio
    'Ratioing'
    JMPanaRa(TPN)
    Status.ratio=0;
    save([TPN 'Status.mat'],'Status')
end
if Status.mask
    'Masking'
    JMPanaMa(TPN) %no point of calculating distance to mask because I am
    %find dots in the mask, also distance to dendrite is not useful for
    %judging positive vs negative dots becasue masking pretty much
    %eliminates dots far from dendrites. Besides distance to dendrite can
    %be calculated in JMPClosestSkelFinder later. Plus, DDm takes up too
    %much memory. HO 10/18/2011
    %However DDm is necessary for RunAnalysis part...so still I need to run
    %anaMa.
    
    JMPanaCB(TPN)
    %     anaFSc(TPN, DPN) %check for shifts
    Status.mask=0;
    save([TPN 'Status.mat'],'Status')
end
if Status.round
    'Rounding'
    JMPanaRd(TPN)
    Status.round=0;
    save([TPN 'Status.mat'],'Status')            
end

'Running SG once'

JMPanaSGPCA(TPN)

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


%% If using imaris dot finding, run this code - JMP 6/16/15
%Beforehand, use JMPiPassingSpots2MLDotsVer
TPN = GetMyDir;
load([TPN 'Dots.mat']);
load([TPN 'Skel.mat']);
load([TPN 'Settings.mat'])
ImageInfo = Settings.ImInfo;
xyum=ImageInfo.xyum; %changed to reflect structure format of ImInfo HO 1/5/2010
zum=ImageInfo.zum; %changed to reflect structure format of ImInfo HO 1/5/2010
CBpos = [ceil(Skel.FilStats.SomaPtXYZ(2)/xyum) ceil(Skel.FilStats.SomaPtXYZ(1)/xyum) ceil(Skel.FilStats.SomaPtXYZ(3)/zum)];
Dots.Im.CBpos=CBpos;
save([TPN 'Dots.mat'], 'Dots');
dotNum = size(Dots.Pos);
dotNum = dotNum(1);
SG.passF = ones(1,dotNum);
mkdir(TPN,'find')
save([TPN 'find\SG.mat'],'SG');
Grouped.Pos = Dots.Pos;
Grouped.Num = dotNum;
Grouped = JMPClosestSkelFinder(Settings, Grouped, Skel);
save([TPN 'Grouped.mat'], 'Grouped');

