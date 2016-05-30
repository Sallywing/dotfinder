%%READ ME - JMP

%Before running this program, please create a folder for your cell. Within
%that folder, create a folder called "I" and place in it your channels for
%PSD-95 and cell fill in separate TIF Files. In addition, upload your
%dots and skeleton information into your cell's drectory. Dot
%information can be retrieved from Imaris XTension "JMP Imaris Dot Finding
%2 Matlab" and skeleton information from "HO save filament as .mat."

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
% 090315 JMP Adapted to Imaris fot finding


%% Retrieves path for Folder that contains image folder (I)
TPN = GetMyDir; % Retrieves path for Folder that contains image folder (I)
save([TPN 'TPN.mat'], 'TPN');

%get cell info HO 6/25/2010
v.Animal = '5HTR2a-EGFP';%'Grm6Tom';%'MG6YSTENTC5';%'MG6YSDTA1';%'aPax6CreMG6YSDTA1Grm6GFP';%'aPax6CreMG6YSDTA1';%'MG6YSTENTC3Psubset';%%'Gus8GFP';%
v.CellName = '150531c1';%'120212c5';%'Josh022dC';
v.CellType = 'OFF-sustained RGC';%'A-type ON RGC';%'ON alpha RGC';%'G17 DSGC';%'G1 or 2 or 6 or 10 ON GC';%
v.Age = 30;
v.Prep = 'whole-mount';
v.Bullet1 = 'CMVPSD95RFP';%'CMVPSD95mCherry';%
v.Bullet2 = 'CMVTFP-myc';%'None';%'CMVCerulean';%
v.Bullet3 = 'None';%
v.Immuno1 = 'GFP';%'CtBP2Alexa514';%'CtBP2DyLight649';%'Syt2DyLight649';%'CtBP2Alexa568';%
v.Immuno2 = 'Syt2-649';%'GFPDyLight649';%'None';%'Syt2DyLight649';%'CaBP5DyLight649';%'RibeyeAdomainAlexa568';
v.Immuno3 = 'myc405';%

v = JMPgetVars(v,'Enter cell information (Optional)');
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

%Removing because too many dialogue boxes can be confusing - JMP
%Status = JMPgetVars(Status, 'Which programs would you like to run?');

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
  'Volume to Voxel Number Conversion', 1, {'0.1','0.3','1','2','0.25','0.5'});
if isempty(Answer), return, end

MaxDotSize = (4/3*pi*(str2double(Answer(3))/2)*(str2double(Answer(3))/2)*(str2double(Answer(4))/2)) / (str2double(Answer(1))*str2double(Answer(1))*str2double(Answer(2)));
MinDotSize = (4/3*pi*(str2double(Answer(5))/2)*(str2double(Answer(5))/2)*(str2double(Answer(6))/2)) / (str2double(Answer(1))*str2double(Answer(1))*str2double(Answer(2)));
BlockBuffer = round(1.5/str2double(Answer(1)));

Settings.ImInfo.xyum = str2double(cell2mat(Answer(1)));
Settings.ImInfo.zum = str2double(cell2mat(Answer(2)));

if Status.dotfinder

    clear v
    v.blockSize = 90;
    v.blockBuffer=BlockBuffer; %changing this between 15 to 50 didn't make much difference, 10 could reduce the number of dots found, use 15 for safety. HO 1/5/2010 Then switched from 15 to BlockBuffer to process images with different resolution. HO 6/8/2010
    v.thresholdStep = 2;
    v.maxDotSize = MaxDotSize; %max dot size for single-peak dot DURING ITERATIVE THRESHOLDING, NOT FINAL, switched from 300 to MaxDotSize to process images with different resolution HO 6/8/2010
    v.minDotSize=3; %min dot size DURING ITERATIVE THRESHOLDING, NOT FINAL.
    v.MultiPeakDotSizeCorrectionFactor = 0; %added by HO 2/8/2011, maxDotSize*MultiPeakDotSizeCorrectionFactor will be added for each additional dot joined to the previous dot, see dotfinder. With my PSD95CFP dots, super multipeak dots are rare, so put 0 for this factor.
    v.itMin = 2; % added by HO 2/9/2011 minimum iterative threshold allowed to be analyzed as voxels belonging to any dot...filter to remove value '1' pass thresholds. value '2' is also mostly noise for PSD95 dots, so 3 is the good starting point HO 2/9/2011
    v.peakCutoffLowerBound = 0.2; %changed to the set threshold for all dots (0.2) after psychophysical testing with linescan and full 8-bit depth normalization HO 6/4/2010
    v.peakCutoffUpperBound = 0.2; %changed to the set threshold for all dots (0.2) after psychophysical testing with linescan and full 8-bit depth normalization HO 6/4/2010
    v.minFinalDotITMax = 3; % minimum ITMax allowed as FINAL dots. Any found dot whose ITMax is below this threshold value is removed from the registration into Dots. 5 will be the best for PSD95. HO 1/5/2010
    v.minFinalDotSize = MinDotSize; %minimum dot size allowed as FINAL dots, switched from 3 to MinDotSize to process images with different resolution HO 6/8/2010
    %v.roundThreshold = 50; %this is not used HO
    Settings.dotfinder = v;
    save([TPN 'Settings.mat'], 'Settings')
end


%% Check out files located in the folder "I". These are typically the TIF files for channels containing information for cell fill and postsynaptic markers.
if Status.read
    JMPanaRead(TPN)
    Status.read=0;
    save([TPN 'Status.mat'],'Status')
end

%% make finer Skel, also calculate path distance of skels from soma 10/18/2011 HO
load([TPN 'Settings.mat'],'Settings')
try %Checks to see if Dots are in the directory selected by the user. If the file Dots.mat is missing, an exception is thrown, and the message pops up.
    load([TPN,'Skel.mat']) 
catch
    msg = msgbox(['Please upload the skeleton information from Imaris into the directory of your cell. ' ...
        'To do this, first open up your cell in Imaris. Then select the filamen, go to filament tools, and select' ...
        '''HO save filament as .mat.'' When you are done, hit ''OK''']);
    uiwait(msg); % Program execution is halted until message is closed
    load([TPN,'Skel.mat'])
end
Skel = JMPSkelPathLengthCalculator(Skel);
save([TPN 'Skel.mat'],'Skel')
SkelFiner = JMPSkelFinerGenerator(Skel,Settings(1).ImInfo.xyum);
clear Skel;
Skel = SkelFiner;
save([TPN 'SkelFiner.mat'], 'Skel');
Skel = JMPSkelPathLengthCalculator(Skel);
save([TPN 'SkelFiner.mat'], 'Skel');
clear Skel SkelFiner Settings;

%% Ensure that Imaris Dot finding has already been completed - JMP

try %Checks to see if Dots are in the directory selected by the user. If the file Dots.mat is missing, an exception is thrown, and the message pops up.
    load([TPN,'Dots.mat']) 
catch
    msg = msgbox(['Please upload the dot positions from Imaris into the directory of your cell. ' ...
        'To do this, first open up your cell in Imaris. Then select the spots you want to analyze, go to spots tools, then select ' ...
        '''JMP Imaris Dot Finding 2 Matlab.'' When you are done, hit ''OK''']);
    uiwait(msg); % Program execution is halted until message is closed
    load([TPN,'Dots.mat'])
end

%% Prepare for JMPRunAnalysis- JMP 6/16/15
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

