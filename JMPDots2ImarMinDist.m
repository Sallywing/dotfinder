%% comments and errors
% 20101008 AB started function for adding ML passing and non passing spots
% to Imaris in order to see 3D 
% 20150814 JMP Adapted to visualize the minimum distance from auto coloc
% analyzed dots to bipolar cell masks
%
%% 
% send dots found with dotfinder to Imaris
% imaris spots will be displayed as passing and nonpassing dots. 
% can also choose the statistics (dot properties) sent into imaris for both
% passing and non passing dots

%% Set these variables to your preference each time you run the program. All other variables should remain the same.
% Load the necessary files in command window.
DotIDs = ColocAuto.ListDotIDsAutoColocAnalyzed(ColocAuto.ColocFlagFish1 == 1); % Array of the IDS of dots you want to display in Imaris
MinDists = ColocAuto.ColoMinDists(ColocAuto.ColocFlagFish1 == 1); %Array same length as DotIDs that contains the minimum distance (radius) for each corresponding Dot ID

%% connect to Imaris Com interface
try vImarisApplication.mVisible 
catch 
    vImarisApplication = actxserver('Imaris.Application');
    vImarisApplication.mVisible = true;
end

%% Load Dots and either ColocManual or ColocAuto
TPN = GetMyDir;
load([TPN 'Dots.mat']);
load([TPN 'Settings.mat']);
xyum = Settings.ImInfo.xyum;
zum = Settings.ImInfo.zum;

%% create spots from matlab data
ColocAnalyzedDotPos = Dots.Pos(DotIDs,:); %Dot Positions you are interested in
vSpotsAPosXYZ = [ColocAnalyzedDotPos(:,2)*xyum,ColocAnalyzedDotPos(:,1)*xyum,(ColocAnalyzedDotPos(:,3))*zum]; %convert yxz to xyz
vSpotsARadius = MinDists;
vSpotsAPosT = zeros(1,length(ColocAnalyzedDotPos));

%% add new spots pass / non passing
% add passing spots
vSpotsA = vImarisApplication.mFactory.CreateSpots;
vSpotsA.Set(vSpotsAPosXYZ, vSpotsAPosT, vSpotsARadius);
vSpotsA.mName = sprintf('MinDist');
vSpotsA.SetColor(0.0, 1.0, 0.0, 0.0);
vImarisApplication.mSurpassScene.AddChild(vSpotsA);

