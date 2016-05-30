%Dot colocalization manual check, 2 fish version
%written for the colocalization of PSD puncta against CtBP2 immuno.
%HO 2/18/2011 only the option for going through all the PSD puncta written
%HO 10/27/2012 added the option of choosing a path from soma to the
%furthest dendritic end in the image to do manual check
%HO 10/27/2012 added image gain adjustment for each channel during the
%manual check.
%HO 4/2/2015 made it to 2 fish version
%WQY 9/15/2015 added 3D visualization (need to be polished)
%WQY 9/15/2015 added random draw certain dots
%WQY 9/25/2015 change the location of buttons
%WQY 10/15/2015 optimize classification


TPN = GetMyDir;
load([TPN 'Settings.mat']);
load([TPN 'Grouped.mat']); %load the source dot to search for fish
load([TPN 'Post.mat']);
load([TPN 'Dots.mat']);
Dots.Ind = sub2ind(Dots.ImSize, Dots.Pos(:,1), Dots.Pos(:,2), Dots.Pos(:,3));

if exist([TPN 'Colo.mat']);
    load([TPN 'Colo.mat']); %load Colo
else
    Colo = HOtif2mat; %Or, load tif file into mat if the fish is not dot, like BC axons and their markers
    save([TPN 'Colo.mat'], 'Colo'); 
end

if exist([TPN 'Colo2.mat']);
    load([TPN 'Colo2.mat']); %load Colo
else
    Colo2 = HOtif2mat; %Or, load tif file into mat if the fish is not dot, like BC axons and their markers
    save([TPN 'Colo2.mat'], 'Colo2'); 
end


if exist([TPN 'ColocManual.mat']) %load the one in the middle of analysis
    load([TPN 'ColocManual.mat'])
else %start new
    v.Source = 'CMVPSD95tagRFP-T';
    v.Fish1 = 'Gjd2-EGFP';
    v.Fish2 = 'CaBP5DyLight647';
    v = HOgetVars(v,'Enter source&fish information');
    ColocManual = v;

    ManualColocAnalyzingFlag = zeros([1,Grouped.Num], 'uint8');
    ManualAllDotsFlag = input('Manual colocalization analysis. Type 1 for going through all the dots, 2 for using mask to choose dots, 0 for sampling dots along the longest dendrite. \n');
    
    if ManualAllDotsFlag == 1
        ManualColocAnalyzingFlag = ManualColocAnalyzingFlag+1;
    
    elseif ManualAllDotsFlag == 2;
        Mask = HOtif2mat('Load 2-D tif file that shows mask (pixel value 1)'); %plane tif file for RGC, masking for example, visible type 7 in Gus8GFP, not 3-D mask
        for GroupedNum = 1:Grouped.Num;
            if Mask(round(Grouped.Pos(GroupedNum,1)), round(Grouped.Pos(GroupedNum,2))) == 1; %fall within mask
                ManualColocAnalyzingFlag(GroupedNum) = 1;
            end
        end
   
        
    elseif ManualAllDotsFlag == 0;
        load([TPN 'SkelFiner.mat']);
        SomaPtID = Skel.FilStats.SomaPtID;
        [MaxPathLength, MaxPathLengthSkelID] = max(Skel.FilStats.SkelPathLength2Soma);
        MaxPathLengthSkelID = MaxPathLengthSkelID-1; %-1 to fit to HOSkel2PtConnectivityFinder
        'Finding the path from soma to the furtherst dendritic end'
        [Soma2FurthestDendEndSkelIDs Len] = HOSkel2PtConnectivityFinder(Skel, SomaPtID, MaxPathLengthSkelID);
        Soma2FurthestDendEndSkelIDs = Soma2FurthestDendEndSkelIDs+1; %+1 to go back to my skel IDing
        
        SampledDot2DMap = zeros(size(Post,1),size(Post,2));
        for i=1:Grouped.Num;
            if find(Soma2FurthestDendEndSkelIDs == Grouped.ClosestSkelIDs(i));
                ManualColocAnalyzingFlag(i) = 1;
                SampledDot2DMap(ceil(Grouped.Pos(i,1)), ceil(Grouped.Pos(i,2))) = 255;
            end
        end
        'Number of dots manually analyzed for colocalzation is'
        NumDotsManuallyAnalyzed = length(find(ManualColocAnalyzingFlag==1))
        se = strel('disk', 4);
        SampledDot2DMapDilated = imdilate(SampledDot2DMap, se);
        Blank2D = SampledDot2DMapDilated*0;

        %map the sampled dots
        load([TPN 'Dend.mat']);
        DendMaxZ = max(Dend,[],3);
        CombinedI = cat(3, Blank2D, SampledDot2DMapDilated, DendMaxZ);
        figure(1),imshow(CombinedI);
        
        AddAnotherDendFlag = 1;
        while AddAnotherDendFlag
            AddAnotherDendFlag = input('Want to sample at least 100 dots. Type 1 for adding another dendrite, 0 if you are satisfied with the dot number. \n');
            if AddAnotherDendFlag;
                disp('Hit enter after zooming into the tip of the other dendrite.');
                pause();
                disp('No pick the tip of the other dendrite');
                [pX,pY] = ginput;  %needto double check that this is the correct row column/ y x format
                pX = fix(pX);
                pY = fix(pY);
                SkelVoxPosXYZ = ceil([Skel.FilStats.aXYZ(:,1)/Settings.ImInfo.xyum, Skel.FilStats.aXYZ(:,2)/Settings.ImInfo.xyum, Skel.FilStats.aXYZ(:,3)/Settings.ImInfo.zum]);
                Dist2Edge = sqrt((SkelVoxPosXYZ(:,1)-pX).^2 + (SkelVoxPosXYZ(:,2)-pY).^2);
                ChosenSkelID = find(Dist2Edge == min(Dist2Edge),1);
                ChosenSkelID = ChosenSkelID-1; %-1 to fit to HOSkel2PtConnectivityFinder
                'Finding the path from soma to the chosen dendritic point'
                [Soma2ChosenSkelIDs Len] = HOSkel2PtConnectivityFinder(Skel, SomaPtID, ChosenSkelID);
                Soma2ChosenSkelIDs = Soma2ChosenSkelIDs+1; %+1 to go back to my skel IDing
                for i=1:Grouped.Num;
                    if find(Soma2ChosenSkelIDs == Grouped.ClosestSkelIDs(i));
                        ManualColocAnalyzingFlag(i) = 1;
                        SampledDot2DMap(ceil(Grouped.Pos(i,1)), ceil(Grouped.Pos(i,2))) = 255;
                    end
                end
                'Number of dots manually analyzed for colocalzation is'
                NumDotsManuallyAnalyzed = length(find(ManualColocAnalyzingFlag==1))
                se = strel('disk', 4);
                SampledDot2DMapDilated = imdilate(SampledDot2DMap, se);
                CombinedI = cat(3, Blank2D, SampledDot2DMapDilated, DendMaxZ);
                imshow(CombinedI);
            end
            %pause();
        end
        close all;
        
    else %choose some of dots equally from the center to peripheral
        NumDotsManuallyAnalyzed = input('How many dots do you want to sample? \n');
        load([TPN 'SkelFiner.mat']);
        GroupedNum = [];
        SomaVoxPosXYZ = ceil([Skel.FilStats.SomaPtXYZ(:,1)/Settings.ImInfo.xyum, Skel.FilStats.SomaPtXYZ(:,2)/Settings.ImInfo.xyum, Skel.FilStats.SomaPtXYZ(:,3)/Settings.ImInfo.zum]);
        DistDot2Soma = sqrt((Dots.Pos(:,1)-SomaVoxPosXYZ(1)).^2 + (Dots.Pos(:,2)-SomaVoxPosXYZ(2)).^2 + (Dots.Pos(:,2)-SomaVoxPosXYZ(3)).^2);
        % assign dots to 10 bins according to their Dist2Soma
        [m,n] = histc(DistDot2Soma,min(DistDot2Soma):range(DistDot2Soma)/9:max(DistDot2Soma));
        NumSampledDots = floor(m/sum(m)*NumDotsManuallyAnalyzed);
        
        for i = 1:length(m)
            GroupedNum = cat(1, GroupedNum, randsample(find(n == i), NumSampledDots(i)));
        end
        %need to write a code here to sample dots equally from the center to peripheral
        ManualColocAnalyzingFlag(GroupedNum) = 1;
    end

    ColocManual.ListDotIDsManuallyColocAnalyzed = find(ManualColocAnalyzingFlag == 1);
    ColocManual.TotalNumDotsManuallyColocAnalyzed = length(ColocManual.ListDotIDsManuallyColocAnalyzed);
    ColocManual.ColocFlagFish1 = zeros([1,ColocManual.TotalNumDotsManuallyColocAnalyzed], 'uint8');
    ColocManual.ColocFlagFish2 = zeros([1,ColocManual.TotalNumDotsManuallyColocAnalyzed], 'uint8');
end


PostVoxMap = zeros(size(Post), 'uint8');
DotRepeatFlag=0;
PostReScalingFactor=1;
ColoReScalingFactor=1;
Colo2ReScalingFactor=1;

%%
while ~isempty(find(ColocManual.ColocFlagFish1 == 0));
    if DotRepeatFlag == 0;
        RemainingDotIDs = ColocManual.ListDotIDsManuallyColocAnalyzed(ColocManual.ColocFlagFish1 == 0);
        NumRemainingDots = length(RemainingDotIDs);
        dot = ceil(rand*NumRemainingDots); %randomize the order of analyzing dots
        DotNum = RemainingDotIDs(dot);
        %find(ColocManual.ListDotIDsManuallyColocAnalyzed == DotNum)
        %PostVoxMap = PostVoxMap*0; %this takes time, instead return the activated voxels to 0 before going to the next loop (next dot entry).
        %PostVoxMap(Grouped.Vox(DotNum).Ind) = 150;
       
        for x = -5:5
            for y = -5:5
                for z  = -5:5
                    if (Dots.Pos(DotNum,1) + y) > 0 & (Dots.Pos(DotNum,1) + y) <= size(Post,1) & ...
                            (Dots.Pos(DotNum,2) + x) > 0 & (Dots.Pos(DotNum,2) + x) <= size(Post,2) & ....
                            (Dots.Pos(DotNum,3) + z) > 0 & (Dots.Pos(DotNum,3) + z) <= size(Post,3)
                        PostVoxMap(Dots.Pos(DotNum,1) + y, Dots.Pos(DotNum,2) + x, Dots.Pos(DotNum,3) + z) = 150;
                    end
                end
            end
        end

        CutNumVox = [50, 50, 40];
        PostCut = JMPDotImageStackCutter(Post, Dots, DotNum, CutNumVox, []);
        ColoCut = JMPDotImageStackCutter(Colo, Dots, DotNum, CutNumVox, []);
        Colo2Cut = JMPDotImageStackCutter(Colo2, Dots, DotNum, CutNumVox, []);
        
        PostVoxMapCut = JMPDotImageStackCutter(PostVoxMap, Dots, DotNum, CutNumVox,[]);
        
        for x = -5:5
            for y = -5:5
                for z  = -5:5
                    if (Dots.Pos(DotNum,1) + y) > 0 & (Dots.Pos(DotNum,1) + y) <= size(Post,1) & ...
                        (Dots.Pos(DotNum,2) + x) > 0 & (Dots.Pos(DotNum,2) + x) <= size(Post,2) & ....
                        (Dots.Pos(DotNum,3) + z) > 0 & (Dots.Pos(DotNum,3) + z) <= size(Post,3)
                        PostVoxMap(Dots.Pos(DotNum,1) + y, Dots.Pos(DotNum,2) + x, Dots.Pos(DotNum,3) + z) = 0;
                    end
                end
            end
        end
        
        %PostVoxMap([Dots.Pos(DotNum,1)-5:Dots.Pos(DotNum,1)+5, Dots.Pos(DotNum,2)-5:Dots.Pos(DotNum,2)+5, Dots.Pos(DotNum,3)-5:Dots.Pos(DotNum,3)+5]) = 0;
         %Once cut, no need for PostVoxMap, return the activated voxels to 0 for the next dot entry.

%         MaxRawBright = max(Grouped.Vox(DotNum).RawBright);
%         PostMaxRawBright = single(max(PostCut(:)));
%         ColoMaxRawBright = single(max(ColoCut(:)));
%         Colo2MaxRawBright = single(max(Colo2Cut(:)));
        
       MaxRawBright = 0;
        for x = -2:2
            for y = -2:2
                for z  = -2:2
                    if (Dots.Pos(DotNum,1) + y) > 0 & (Dots.Pos(DotNum,1) + y) <= size(Post,1) & ...
                    (Dots.Pos(DotNum,2) + x) > 0 & (Dots.Pos(DotNum,2) + x) <= size(Post,2) & ....
                    (Dots.Pos(DotNum,3) + z) > 0 & (Dots.Pos(DotNum,3) + z) <= size(Post,3)
                        curDotBrightness = Post(Dots.Pos(DotNum,1) + y,Dots.Pos(DotNum,2)+ x,Dots.Pos(DotNum,3) + z);
                        if curDotBrightness > MaxRawBright
                            MaxRawBright = curDotBrightness;
                        end
                    end
                end
            end
        end
        MaxRawBright = single(MaxRawBright);
        PostMaxRawBright = single(max(PostCut(:)));
        ColoMaxRawBright = single(max(ColoCut(:)));
        Colo2MaxRawBright = single(max(Colo2Cut(:)));
        %ColoLocalMaxRawBright = single(max(Colo(Grouped.Vox(DotNum).Ind)));
        PostUpperLimit = 150;
        ColoUpperLimit = 250;
        Colo2UpperLimit = 200;
        %ColoLocalUpperLimit = 100;
        PostScalingFactor = PostUpperLimit/MaxRawBright; %normalized to the dot of interest
        %PostScalingFactor = PostUpperLimit/PostMaxRawBright; %normalized to the brightest dot in PostCut
        ColoScalingFactor = ColoUpperLimit/ColoMaxRawBright; %often dim CtBP2 puncta disspeared when image brightness is adjusted to bright RBC or T6 CtBP2 puncta 
        Colo2ScalingFactor = Colo2UpperLimit/Colo2MaxRawBright;
        %ColoLocalScalingFactor = ColoLocalUpperLimit/ColoLocalMaxRawBright; %this is for dimmer CtBP2 dots possibly hidden near the PSD95 dots
        %ColoLocalScalingFactor = ColoScalingFactor*1.5; %just showing the image with 1.5times stronger intensity works better
        %Colo2LocalScalingFactor = Colo2ScalingFactor*1.5; %just showing the image with 1.5times stronger intensity works better
    else
        PostScalingFactor = PostScalingFactor*PostReScalingFactor;
        ColoScalingFactor = ColoScalingFactor*ColoReScalingFactor;
        Colo2ScalingFactor = Colo2ScalingFactor*Colo2ReScalingFactor;
        PostReScalingFactor = 1; %set the Re-scaling factor back to 1
        ColoReScalingFactor = 1; %set the Re-scaling factor back to 1
        Colo2ReScalingFactor = 1; %set the Re-scaling factor back to 1
        DotRepeatFlag=0; %set the flag back to 0
    end
    
    PostCutScaled = uint8(single(PostCut)*PostScalingFactor);
    ColoCutScaled = uint8(single(ColoCut)*ColoScalingFactor);
    Colo2CutScaled = uint8(single(Colo2Cut)*Colo2ScalingFactor);
    PostCutLocal = uint8(single(PostCutScaled)*2);
    ColoCutLocal = uint8(single(ColoCutScaled)*2);
    Colo2CutLocal = uint8(single(Colo2CutScaled)*2);
    %ColoCutLocal = uint8(single(ColoCut)*ColoLocalScalingFactor);
    %Colo2CutLocal = uint8(single(Colo2Cut)*Colo2LocalScalingFactor);
    ZeroCut = zeros(size(PostCut), 'uint8');
    
    ImStk1 = cat(4, PostCutScaled, PostCutScaled, PostCutScaled);
    ImStk2 = cat(4, PostCutScaled, ZeroCut, PostVoxMapCut);
    ImStk3 = cat(4, PostCutLocal, PostCutLocal, PostCutLocal);
    ImStk4 = cat(4, PostCutLocal, ZeroCut, PostVoxMapCut);
    ImStk5 = cat(4, ColoCutScaled, ColoCutScaled, ColoCutScaled);
    ImStk6 = cat(4, ColoCutLocal, ColoCutLocal, ColoCutLocal);
    ImStk7 = cat(4, PostCutScaled, ColoCutScaled, ZeroCut);
    ImStk8 = cat(4, PostCutLocal, ColoCutLocal, ZeroCut);
    ImStk9 = cat(4, Colo2CutScaled, Colo2CutScaled, Colo2CutScaled);
    ImStk10 = cat(4, Colo2CutLocal, Colo2CutLocal, Colo2CutLocal);
    ImStk11 = cat(4, PostCutScaled, Colo2CutScaled, ZeroCut);
    ImStk12 = cat(4, PostCutLocal, Colo2CutLocal, ZeroCut);
    ImStk13 = cat(4, Colo2CutScaled, ColoCutScaled, PostCutScaled);
    ImStk14 = cat(4, Colo2CutLocal, ColoCutScaled, PostCutScaled);
    ImStk15 = cat(4, Colo2CutScaled, ColoCutLocal, PostCutScaled);
    ImStk16 = cat(4, Colo2CutLocal, ColoCutLocal, PostCutLocal);
    
    ImStk1to4 = cat(1, ImStk1, ImStk3, ImStk2, ImStk4);
    ImStk5to8 = cat(1, ImStk5, ImStk6, ImStk7, ImStk8);
    ImStk9to12 = cat(1, ImStk9, ImStk10, ImStk11, ImStk12);
    ImStk13to16 = cat(1, ImStk13, ImStk14, ImStk15, ImStk16);
    ImStk = cat(2, ImStk1to4, ImStk5to8, ImStk9to12, ImStk13to16);

    
%         % 3D visualization
%     subvolumexyzlim = [30,70,30,70,0,60];
%     figure
% %     subplot(1,2,1)
%     data1 = PostCut;
%     [x,y,z,D] = subvolume(data1,subvolumexyzlim);
%     p1 = patch(isosurface(x,y,z,D,40),...
%         'FaceColor','red','EdgeColor','none','FaceAlpha',.6);
%     isonormals(x,y,z,D,p1)
%     data2 = ColoCut;
%     [x,y,z,D] = subvolume(data2,subvolumexyzlim);
%     p2 = patch(isosurface(x,y,z,D,50),...
%         'FaceColor','green','EdgeColor','none','FaceAlpha',.6);
%     isonormals(x,y,z,D,p2)
% 
%     view(3); 
%     camlight left; 
%     colormap jet
%     lighting gouraud
%     
%     figure
%     data1 = PostCut;
%     [x,y,z,D] = subvolume(data1,subvolumexyzlim);
%     p1 = patch(isosurface(x,y,z,D,40),...
%         'FaceColor','red','EdgeColor','none','FaceAlpha',.6);
%     isonormals(x,y,z,D,p1)
% 
%     data3 = Colo2Cut;
%     [x,y,z,D] = subvolume(data3,subvolumexyzlim);
%     p3 = patch(isosurface(x,y,z,D,70),...
%         'FaceColor','blue','EdgeColor','none','FaceAlpha',.6);
%     isonormals(x,y,z,D,p3)
%     
%     view(3); 
%     camlight left; 
%     colormap jet
%     lighting gouraud
    
    colmap = 'gray(256)';
    FrmPerSec = 5;
    VideoWindowSize = [0 0.05 0.88 0.88];
    HOvideofig(size(ImStk,3), @(frm) HOredraw(frm, ImStk, colmap), FrmPerSec, [], [], VideoWindowSize); % if user bins is 10 this results in 100x real speed
    HOredraw(1, ImStk, colmap);

    set(gcf,'units','centimeters');
    % Place the figure
    set(gcf,'position',[1 3 25 20]);
    % Set figure units back to pixels
    set(gcf,'units','pixel');
    
    %yes, no, save and exit buttons and annotations were added. 2/13/2011 HO
    uicontrol('Style','text','Units','normalized','position',[.1,.98,.2,.02],'String',['TotalNumDots: ' num2str(ColocManual.TotalNumDotsManuallyColocAnalyzed)]);
    uicontrol('Style','text','Units','normalized','position',[.35,.98,.2,.02],'String',['Dot number: ' num2str(DotNum)]);
    uicontrol('Style','text','Units','normalized','position',[.6,.98,.2,.02],'String',['Remaining dot number: ' num2str(NumRemainingDots)]);
    uicontrol('Style','text','Units','normalized','position',[.11,.955,.13,.02],'String',[ColocManual.Source]);
    uicontrol('Style','text','Units','normalized','position',[.3,.955,.13,.02],'String',[ColocManual.Fish1]);
    uicontrol('Style','text','Units','normalized','position',[.47,.955,.13,.02],'String',[ColocManual.Fish2]);
    
%     uicontrol('Style','Pushbutton','Units','normalized','position',[.86,.2,.13,.08],...
%         'String','Both Coloc','CallBack',['ColocManual.ColocFlagFish1(ColocManual.ListDotIDsManuallyColocAnalyzed==DotNum)=1; ColocManual.ColocFlagFish2(ColocManual.ListDotIDsManuallyColocAnalyzed==DotNum)=1; uiresume']);
%     uicontrol('Style','Pushbutton','Units','normalized','position',[.86,.1,.13,.08],...
%         'String','Both Not Coloc','CallBack',['ColocManual.ColocFlagFish1(ColocManual.ListDotIDsManuallyColocAnalyzed==DotNum)=2; ColocManual.ColocFlagFish2(ColocManual.ListDotIDsManuallyColocAnalyzed==DotNum)=2; uiresume']);
%     uicontrol('Style','Pushbutton','Units','normalized','position',[.86,.3,.13,.08],...
%         'String',[ColocManual.Fish1 ' Coloc Only'],'CallBack',['ColocManual.ColocFlagFish1(ColocManual.ListDotIDsManuallyColocAnalyzed==DotNum)=1; ColocManual.ColocFlagFish2(ColocManual.ListDotIDsManuallyColocAnalyzed==DotNum)=2; uiresume']);
%     uicontrol('Style','Pushbutton','Units','normalized','position',[.86,.4,.13,.08],...
%         'String',[ColocManual.Fish2 ' Coloc Only'],'CallBack',['ColocManual.ColocFlagFish1(ColocManual.ListDotIDsManuallyColocAnalyzed==DotNum)=2; ColocManual.ColocFlagFish2(ColocManual.ListDotIDsManuallyColocAnalyzed==DotNum)=1; uiresume']);
    uicontrol('Style','Pushbutton','Units','normalized','position',[.65,.03,.13,.02],...
        'String','Both Coloc','CallBack',['ColocManual.ColocFlagFish1(ColocManual.ListDotIDsManuallyColocAnalyzed==DotNum)=1; ColocManual.ColocFlagFish2(ColocManual.ListDotIDsManuallyColocAnalyzed==DotNum)=1; uiresume']);
    uicontrol('Style','Pushbutton','Units','normalized','position',[.1,.03,.13,.02],...
        'String','Both Not Coloc','CallBack',['ColocManual.ColocFlagFish1(ColocManual.ListDotIDsManuallyColocAnalyzed==DotNum)=2; ColocManual.ColocFlagFish2(ColocManual.ListDotIDsManuallyColocAnalyzed==DotNum)=2; uiresume']);
    uicontrol('Style','Pushbutton','Units','normalized','position',[.3,.03,.13,.02],...
        'String',[ColocManual.Fish1 ' Coloc Only'],'CallBack',['ColocManual.ColocFlagFish1(ColocManual.ListDotIDsManuallyColocAnalyzed==DotNum)=1; ColocManual.ColocFlagFish2(ColocManual.ListDotIDsManuallyColocAnalyzed==DotNum)=2; uiresume']);
    uicontrol('Style','Pushbutton','Units','normalized','position',[.48,.03,.13,.02],...
        'String',[ColocManual.Fish2 ' Coloc Only'],'CallBack',['ColocManual.ColocFlagFish1(ColocManual.ListDotIDsManuallyColocAnalyzed==DotNum)=2; ColocManual.ColocFlagFish2(ColocManual.ListDotIDsManuallyColocAnalyzed==DotNum)=1; uiresume']);
    uicontrol('Style','Pushbutton','Units','normalized','position',[.86,.5,.13,.08],...
        'String','Save','Callback',['save([TPN ''ColocManual.mat''], ''ColocManual'');uiwait(msgbox(''Progress saved.''));']);
    uicontrol('Style','Pushbutton','Units','normalized','position',[.86,.6,.13,.08],...
        'String','Exit','Callback',['clear all;close all;clc']);
    uicontrol('Style','Pushbutton','Units','normalized','position',[.86,.7,.13,.08],...
        'String','False Dot','CallBack',['ColocManual.ColocFlagFish1(ColocManual.ListDotIDsManuallyColocAnalyzed==DotNum)=3; ColocManual.ColocFlagFish2(ColocManual.ListDotIDsManuallyColocAnalyzed==DotNum)=3; uiresume']);
    uicontrol('Style','Pushbutton','Units','normalized','position',[.86,.8,.13,.08],...
        'String','Skip','CallBack',['ColocManual.ColocFlagFish1(ColocManual.ListDotIDsManuallyColocAnalyzed==LastDotNum)=4; ColocManual.ColocFlagFish2(ColocManual.ListDotIDsManuallyColocAnalyzed==DotNum)=4; uiresume']);
    uicontrol('Style','Pushbutton','Units','normalized','position',[.86,.9,.13,.08],...
        'String','Reset Last Dot','CallBack',['ColocManual.ColocFlagFish1(ColocManual.ListDotIDsManuallyColocAnalyzed==LastDotNum)=0; ColocManual.ColocFlagFish2(ColocManual.ListDotIDsManuallyColocAnalyzed==DotNum)=0; uiwait(msgbox(''Last dot will be examined again.''))']);
    
%     uicontrol('Style','Pushbutton','Units','normalized','position',[.91,.25,.08,.08],...
%         'String','Coloc','CallBack',['ColocManual.ColocFlag(ColocManual.ListDotIDsManuallyColocAnalyzed==DotNum)=1; uiresume']);
%     uicontrol('Style','Pushbutton','Units','normalized','position',[.91,.15,.08,.08],...
%         'String','Not coloc','CallBack',['ColocManual.ColocFlag(ColocManual.ListDotIDsManuallyColocAnalyzed==DotNum)=2; uiresume']);
%     uicontrol('Style','Pushbutton','Units','normalized','position',[.91,.45,.08,.08],...
%         'String','Save','Callback',['save([TPN ''ColocManual.mat''], ''ColocManual'');uiwait(msgbox(''Progress saved.''));']);
%     uicontrol('Style','Pushbutton','Units','normalized','position',[.91,.55,.08,.08],...
%         'String','Exit','Callback',['clear all;close all;clc']);
%     uicontrol('Style','Pushbutton','Units','normalized','position',[.91,.65,.08,.08],...
%         'String','False Dot','CallBack',['ColocManual.ColocFlag(ColocManual.ListDotIDsManuallyColocAnalyzed==DotNum)=3; uiresume']);
%     uicontrol('Style','Pushbutton','Units','normalized','position',[.91,.75,.08,.08],...
%         'String','Reset Last Dot','CallBack',['ColocManual.ColocFlag(ColocManual.ListDotIDsManuallyColocAnalyzed==LastDotNum)=0; uiwait(msgbox(''Last dot will be examined again.''))']);
    
    uicontrol('Style','Pushbutton','Units','normalized','position',[.15,.93,.02,.02],...
        'String','+','CallBack',['DotRepeatFlag=1; PostReScalingFactor=2; uiresume']);
    uicontrol('Style','Pushbutton','Units','normalized','position',[.18,.93,.02,.02],...
        'String','-','CallBack',['DotRepeatFlag=1; PostReScalingFactor=0.5; uiresume']);
    uicontrol('Style','Pushbutton','Units','normalized','position',[.34,.93,.02,.02],...
        'String','+','CallBack',['DotRepeatFlag=1; ColoReScalingFactor=2; uiresume']);
    uicontrol('Style','Pushbutton','Units','normalized','position',[.37,.93,.02,.02],...
        'String','-','CallBack',['DotRepeatFlag=1; ColoReScalingFactor=0.5; uiresume']);
    uicontrol('Style','Pushbutton','Units','normalized','position',[.51,.93,.02,.02],...
        'String','+','CallBack',['DotRepeatFlag=1; Colo2ReScalingFactor=2; uiresume']);
    uicontrol('Style','Pushbutton','Units','normalized','position',[.54,.93,.02,.02],...
        'String','-','CallBack',['DotRepeatFlag=1; Colo2ReScalingFactor=0.5; uiresume']);
    
%     % 3D visualization
%     figure
%     subplot(1,2,1)
%     data1 = PostCut;
%     p1 = patch(isosurface(data1,20),...
%         'FaceColor','red','EdgeColor','none','FaceAlpha',.6);
%     data2 = ColoCut;
%     p2 = patch(isosurface(data2,40),...
%         'FaceColor','green','EdgeColor','none','FaceAlpha',.6);
% %     data3 = Colo2Cut;
% %     p3 = patch(isosurface(data3,60),...
% %        'FaceColor','blue','EdgeColor','none','FaceAlpha',.7);
%     isonormals(data1,p1)
%     isonormals(data2,p2)
% %     isonormals(data3,p3)
%     view(3); 
%     camlight left; 
%     colormap jet
%     lighting gouraud
%     
%     subplot(1,2,2)
%     data1 = PostCut;
%     p1 = patch(isosurface(data1,20),...
%         'FaceColor','red','EdgeColor','none','FaceAlpha',.6);
%     data2 = ColoCut;
% %     p2 = patch(isosurface(data2,40),...
% %         'FaceColor','green','EdgeColor','none','FaceAlpha',.7);
%     data3 = Colo2Cut;
%     p3 = patch(isosurface(data3,70),...
%        'FaceColor','blue','EdgeColor','none','FaceAlpha',.6);
%     isonormals(data1,p1)
% %     isonormals(data2,p2)
%     isonormals(data3,p3)
%     view(3); 
%     camlight left; 
%     colormap jet
%     lighting gouraud
    
    uiwait;
       
    close all;
    
    LastDotNum = DotNum; %register this dot to retrieve the last dot when you push a wrong button.
end

%%
%DON'T FORGET TO SAVE!!
save([TPN 'ColocManual.mat'], 'ColocManual'); 

%add stats so that you can remember ColocFlag of 1 is coloc, etc.
ColocManual.NumDotsColocFish1 = length(find(ColocManual.ColocFlagFish1 == 1));
ColocManual.NumDotsNonColocFish1 = length(find(ColocManual.ColocFlagFish1 == 2));
ColocManual.NumDotsColocFish2 = length(find(ColocManual.ColocFlagFish2 == 1));
ColocManual.NumDotsNonColocFish2 = length(find(ColocManual.ColocFlagFish2 == 2));
ColocManual.NumFalseDots = length(find(ColocManual.ColocFlagFish1 == 3));
ColocManual.ColocRateFish1 = ColocManual.NumDotsColocFish1/(ColocManual.NumDotsColocFish1+ColocManual.NumDotsNonColocFish1);
ColocManual.ColocRateFish2 = ColocManual.NumDotsColocFish2/(ColocManual.NumDotsColocFish2+ColocManual.NumDotsNonColocFish2);
ColocManual.FalseDotRate = ColocManual.NumFalseDots/(ColocManual.NumDotsColocFish1+ColocManual.NumDotsNonColocFish1+ColocManual.NumFalseDots);
ColocManual.ColocRateFish1InclugingFalshDots = ColocManual.NumDotsColocFish1/(ColocManual.NumDotsColocFish1+ColocManual.NumDotsNonColocFish1+ColocManual.NumFalseDots);
ColocManual.ColocRateFish2InclugingFalshDots = ColocManual.NumDotsColocFish2/(ColocManual.NumDotsColocFish2+ColocManual.NumDotsNonColocFish2+ColocManual.NumFalseDots);


save([TPN 'ColocManual.mat'], 'ColocManual'); 

%% Analysis of puncta volume, coloc dot vs. non-coloc dot

%load ColocManual and Grouped and Settings
% DotVolColocManual = Grouped.Vol(ColocManual.ColocFlagFish1==1);
% DotVolNonColocManual = Grouped.Vol(ColocManual.ColocFlagFish1==2);
% VoxVol = Settings.ImInfo.xyum^2*Settings.ImInfo.zum
% MeanDotVolColocManualVox = mean(DotVolColocManual)
% MeanDotVolNonColocManualVox = mean(DotVolNonColocManual)
% MeanDotVolColocManual = MeanDotVolColocManualVox*VoxVol
% MeanDotVolNonColocManual = MeanDotVolNonColocManualVox*VoxVol

%% Automatic coloc analysis based on manually gathered data
% use the JMPDots2ImarMinDist function to debug incorrect distance calculations

AutoColocFlag = str2double(cell2mat(inputdlg('Automatically analyze remaining Dots? 1 for yes, 0 for no.')));
if AutoColocFlag
    %The minimum intensity is most acurrate when you match it to what your
    %naked eye views as the best representation of the cell of interest.
    %Don't worry if there are still some small regions of noise after the minimum
    %intensity threshold is applied, as these are dealt with later. Use Imaris or
    %Amira to determine min intensity.
    prompt = {'Enter minimum intensity for first channel:','Enter minimum intensity for second channel:'};
    dlg_title = 'Setup Mask';
    num_lines = 1;
    def = {'20','20'};
    answer = inputdlg(prompt,dlg_title,num_lines,def);
    ColoMaskMinIntensity = str2double(answer{1});
    Colo2MaskMinIntensity = str2double(answer{2});
    BestMinIntensityNotFound = 1;
    NoiseAcc.MaxNoiseRegions = 0:5:80;
    NoiseAcc.ColoAccuracies = zeros(1,numel(NoiseAcc.MaxNoiseRegions + 1));
    NoiseAcc.Colo2Accuracies = zeros(1,numel(NoiseAcc.MaxNoiseRegions+ 1));
    
    %Prime the Colo Masks
    InitColoMask = zeros(size(Colo),'uint8');
    InitColo2Mask = zeros(size(Colo2),'uint8');
    InitColoMask(Colo >= ColoMaskMinIntensity) = 1; % Apply user defined minimum intensity
    InitColo2Mask(Colo2 >= Colo2MaskMinIntensity) = 1;
    
    while BestMinIntensityNotFound
        tic % start timer to test for loop
        for J = 1:(numel(NoiseAcc.MaxNoiseRegions) + 1)
            if J == (numel(NoiseAcc.MaxNoiseRegions) + 1)
                [M,I] = max(NoiseAcc.ColoAccuracies);
                [M2,I2] = max(NoiseAcc.Colo2Accuracies);
                ColoMaxNoiseRegion = NoiseAcc.MaxNoiseRegions(I);
                Colo2MaxNoiseRegion = NoiseAcc.MaxNoiseRegions(I2);
            else
                %Matlab can slow down due to memory allocation
                clearvars -except Dots Colo Colo2 ColocManual InitColoMask InitColo2Mask BestMinIntensityNotFound ...
                    ColoMaskMinIntensity Colo2MaskMinIntensity TPN Settings J NoiseAcc;
                ColoMaxNoiseRegion = NoiseAcc.MaxNoiseRegions(J);
                Colo2MaxNoiseRegion = NoiseAcc.MaxNoiseRegions(J);
            end
            
            ColoMask = bwareaopen(InitColoMask,ColoMaxNoiseRegion,6);
            Colo2Mask = bwareaopen(InitColo2Mask,Colo2MaxNoiseRegion,6);

            %Get minimum distance for each manual coloc analysis
            ColoMinDists = zeros(1,ColocManual.TotalNumDotsManuallyColocAnalyzed);
            Colo2MinDists = zeros(1,ColocManual.TotalNumDotsManuallyColocAnalyzed);
            CutNumVox = [20, 20, 20];
            idx = 1;
            for DotNum = ColocManual.ListDotIDsManuallyColocAnalyzed
               [ColoMaskCut, ColoCutDotPos] = JMPDotImageStackCutterWithLoc(ColoMask,Dots, DotNum, CutNumVox); % Focus on small section of mask
               [Colo2MaskCut, Colo2CutDotPos] = JMPDotImageStackCutterWithLoc(Colo2Mask,Dots, DotNum, CutNumVox);
               ColoDistMask = JMPCalcDistDot2Mask(Settings,ColoMaskCut,ColoCutDotPos); % Replace 1's in mask with distance to dot
               Colo2DistMask = JMPCalcDistDot2Mask(Settings,Colo2MaskCut,Colo2CutDotPos);
               ColoDistMask(ColoDistMask == 0) = inf; % Set to infinity to exclude in minimum computation
               Colo2DistMask(Colo2DistMask == 0) = inf;
               ColoMinDists(idx) = min(ColoDistMask(:)); % Find the point in mask that is closest to dot
               Colo2MinDists(idx) = min(Colo2DistMask(:));
               idx = idx + 1;
            end

            %find the max threshold to be used for automated analysis
            PassingColoMinDists = ColoMinDists(ColocManual.ColocFlagFish1 == 1);
            PassingColo2MinDists = Colo2MinDists(ColocManual.ColocFlagFish2 == 1);
            StartingColoThreshold = max(PassingColoMinDists);
            StartingColo2Threshold = max(PassingColo2MinDists);
            if isempty(StartingColo2Threshold)
                StartingColo2Threshold = 0;
            end
            if isempty(StartingColoThreshold)
                StartingColoThreshold = 0;
            end

            %Determine the most accurate threshold between 100% - 0% of the max
            [ColoThreshAccuracies,ColoThresholds] = JMPCalcThreshAccuracy(StartingColoThreshold,ColocManual.ColocFlagFish1,ColoMinDists);
            [Colo2ThreshAccuracies,Colo2Thresholds] = JMPCalcThreshAccuracy(StartingColo2Threshold,ColocManual.ColocFlagFish2,Colo2MinDists);
            [MaxColoThreshAccuracy, ColoIdx] = max(ColoThreshAccuracies);
            [MaxColo2DistanceThreshAccuracy, Colo2Idx] = max(Colo2ThreshAccuracies);
            MostAccurateColoDistanceThresh = ColoThresholds(ColoIdx);
            MostAccurateColo2DistanceThresh = Colo2Thresholds(Colo2Idx);
            
            if J ~= (numel(NoiseAcc.MaxNoiseRegions) + 1) %If we are currently testing accuracies
                NoiseAcc.ColoAccuracies(J) = MaxColoThreshAccuracy;
                NoiseAcc.Colo2Accuracies(J) = MaxColo2DistanceThreshAccuracy;
            end
            Progress = (double(J)/(numel(NoiseAcc.MaxNoiseRegions) + 1) * 100); %Percentage of loops completed
            fprintf('Testing most accurate threshold for removing noise regions. This may take a few minutes.\nProgress: %.3g%%\n',Progress);
        end
        toc %stop timer, display elapsed time

        prompt1 = strcat('Max Accuracy for first channel: ', num2str(MaxColoThreshAccuracy), '. Enter new minimum intensity or -1 to use all current thresholds');
        prompt2 = strcat('Max Accuracy for second channel: ', num2str(MaxColo2DistanceThreshAccuracy), '. Enter new minimum intensity or -1 to use all current thresholds');
        prompt = {prompt1,prompt2};
        dlg_title = 'Setup Mask';
        num_lines = [1 60; 1 60];
        def = {num2str(ColoMaskMinIntensity),num2str(Colo2MaskMinIntensity)};
        answer = inputdlg(prompt,dlg_title,num_lines,def);
        ans1 = str2double(answer{1});
        ans2 = str2double(answer{2});

        if ans1 == -1 || ans2 == -1
            BestMinIntensityNotFound = 0;
        else
            ColoMaskMinIntensity = ans1;
            Colo2MaskMinIntensity = ans2;
            InitColoMask = zeros(size(Colo),'uint8');
            InitColo2Mask = zeros(size(Colo2),'uint8');
            InitColoMask(Colo >= ColoMaskMinIntensity) = 1; % Apply user defined minimum intensity
            InitColo2Mask(Colo2 >= Colo2MaskMinIntensity) = 1;
        end
    end
    
    ColocManual.ColoMinDists = ColoMinDists;
    ColocManual.Colo2MinDists = Colo2MinDists;
    save([TPN 'ColocManual.mat'], 'ColocManual'); 
    %Automatically analyze all other Dots
    
    ColocAuto.Fish1 = ColocManual.Fish1;
    ColocAuto.Fish2 = ColocManual.Fish2;
    ColocAuto.ListDotIDsAutoColocAnalyzed = (1:length(Dots.Pos));
    ColocAuto.TotalNumDotsAutoColocAnalyzed = length(ColocAuto.ListDotIDsAutoColocAnalyzed);
    ColocAuto.ColocFlagFish1 = zeros([1,ColocAuto.TotalNumDotsAutoColocAnalyzed], 'uint8');
    ColocAuto.ColocFlagFish2 = zeros([1,ColocAuto.TotalNumDotsAutoColocAnalyzed], 'uint8');
    ColocAuto.ColoMinDists = zeros([1,ColocAuto.TotalNumDotsAutoColocAnalyzed]);
    ColocAuto.Colo2MinDists = zeros([1,ColocAuto.TotalNumDotsAutoColocAnalyzed]);
    CutNumVox = [20, 20, 20];
    ctr = 1;
    DotNums = zeros([1,ColocAuto.TotalNumDotsAutoColocAnalyzed], 'uint8');
    for DotNum = ColocAuto.ListDotIDsAutoColocAnalyzed
       [ColoMaskCut, ColoCutDotPos] = JMPDotImageStackCutterWithLoc(ColoMask,Dots, DotNum, CutNumVox); % Focus on small section of mask
       [Colo2MaskCut, Colo2CutDotPos] = JMPDotImageStackCutterWithLoc(Colo2Mask,Dots, DotNum, CutNumVox);
       ColoDistMask = JMPCalcDistDot2Mask(Settings,ColoMaskCut,ColoCutDotPos); % Replace 1's in mask with distance to dot
       Colo2DistMask = JMPCalcDistDot2Mask(Settings,Colo2MaskCut,Colo2CutDotPos);
       ColoDistMask(ColoDistMask == 0) = inf; % Set to infinity to exclude in minimum computation
       Colo2DistMask(Colo2DistMask == 0) = inf;
       ColoMinDist = min(ColoDistMask(:)); % Find the point in mask that is closest to dot
       Colo2MinDist = min(Colo2DistMask(:));
       ColocAuto.ColoMinDists(ctr) = ColoMinDist;
       ColocAuto.Colo2MinDists(ctr) = Colo2MinDist;
       %Determine colocalization for first channel
       if ColoMinDist <= MostAccurateColoDistanceThresh
           ColocAuto.ColocFlagFish1(ctr) = 1;
       else
           ColocAuto.ColocFlagFish1(ctr) = 2;
       end
       
       %Determine colocalization for second channel
       if Colo2MinDist <= MostAccurateColo2DistanceThresh
           ColocAuto.ColocFlagFish2(ctr) = 1;
       else
           ColocAuto.ColocFlagFish2(ctr) = 2;
       end
       ctr = ctr + 1;
    end
    
    %Get Stats on ColocAuto
    ColocAuto.NoiseAcc = NoiseAcc;
    
    ColocAuto.ColoMaskMinIntensity = ColoMaskMinIntensity;
    ColocAuto.MaxColoThreshAccuracy = MaxColoThreshAccuracy;
    ColocAuto.MostAccurateColoDistanceThresh = MostAccurateColoDistanceThresh;
    ColocAuto.NumDotsColocFish1 = numel(ColocAuto.ColocFlagFish1(ColocAuto.ColocFlagFish1 == 1));
    ColocAuto.NumDotsNonColocFish1 = numel(ColocAuto.ColocFlagFish1(ColocAuto.ColocFlagFish1 == 2));
    ColocAuto.ColocRateFish1 = ColocAuto.NumDotsColocFish1 / double(ColocAuto.TotalNumDotsAutoColocAnalyzed);
    
    ColocAuto.Colo2MaskMinIntensity = Colo2MaskMinIntensity;
    ColocAuto.MaxColo2DistanceThreshAccuracy = MaxColo2DistanceThreshAccuracy;
    ColocAuto.MostAccurateColo2DistanceThresh = MostAccurateColo2DistanceThresh;
    ColocAuto.NumDotsColocFish2 = numel(ColocAuto.ColocFlagFish2(ColocAuto.ColocFlagFish2 == 1));
    ColocAuto.NumDotsNonColocFish2 = numel(ColocAuto.ColocFlagFish2(ColocAuto.ColocFlagFish2 == 2));
    ColocAuto.ColocRateFish2 = ColocAuto.NumDotsColocFish2 / double(ColocAuto.TotalNumDotsAutoColocAnalyzed);
    
    save([TPN 'ColocAuto.mat'], 'ColocAuto');
    
    %Combine Coloc Manual and Coloc Auto into Coloc Total
    ColocTotal.ListDotIDsColocAnalyzed = 1: length(Dots.Pos);
    ColocTotal.TotalNumDotsColocAnalyzed = length(ColocTotal.ListDotIDsColocAnalyzed);
    ColocTotal.Fish1 = ColocManual.Fish1;
    ColocTotal.Fish2 = ColocManual.Fish2;

    ColocTotal.ColocFlagFish1 = ColocAuto.ColocFlagFish1;
    ColocTotal.ColocFlagFish1(ColocManual.ListDotIDsManuallyColocAnalyzed) = ColocManual.ColocFlagFish1;
    ColocTotal.NumDotsColocFish1 = sum(ColocTotal.ColocFlagFish1 == 1);
    ColocTotal.NumDotsNonColocFish1 = sum(ColocTotal.ColocFlagFish1 == 2);
    ColocTotal.ColocRateFish1 = ColocTotal.NumDotsColocFish1 / double(ColocTotal.TotalNumDotsColocAnalyzed);
    
    ColocTotal.ColocFlagFish2 = ColocAuto.ColocFlagFish2;
    ColocTotal.ColocFlagFish2(ColocManual.ListDotIDsManuallyColocAnalyzed) = ColocManual.ColocFlagFish2;
    ColocTotal.NumDotsColocFish2 = sum(ColocTotal.ColocFlagFish2 == 1);
    ColocTotal.NumDotsNonColocFish2 = sum(ColocTotal.ColocFlagFish2 == 2);
    ColocTotal.ColocRateFish2 = ColocTotal.NumDotsColocFish2 / double(ColocTotal.TotalNumDotsColocAnalyzed);
    
else
    ColocTotal = ColocManual;
end

save([TPN 'ColocTotal.mat'], 'ColocTotal');

%% after manual coloc analysis for Gjd2GFP and CaBP5, analyze and visualize those dots
load([TPN 'Settings.mat']);
load([TPN 'Grouped.mat']); %load the source dot to search for fish
load([TPN 'ColocTotal.mat']);
%2-D map
Iall = zeros(Settings.ImInfo.yNumVox, Settings.ImInfo.xNumVox, 'uint8');
IFish2 = Iall;
IFish1 = Iall;
IGjdNegCaBP5Pos = Iall;

for dot = ColocAuto.ListDotIDsAutoColocAnalyzed
    if ColocAuto.ColocFlagFish1(dot)~=3 && ColocAuto.ColocFlagFish1(dot)~=4; %false dot
        Iall(ceil(Grouped.Pos(dot,1)), ceil(Grouped.Pos(dot,2))) = 255;
    end    
    if ColocAuto.ColocFlagFish2(dot)==1; %Fish2 positive
        IFish2(ceil(Grouped.Pos(dot,1)), ceil(Grouped.Pos(dot,2))) = 255;
    end  
    if ColocAuto.ColocFlagFish1(dot)==1; %Fish1 positive
        IFish1(ceil(Grouped.Pos(dot,1)), ceil(Grouped.Pos(dot,2))) = 255;
    end
end

se = strel('disk', 4);
IallDilate = imdilate(Iall, se);
IFish2Dilate = imdilate(IFish2, se);
IFish1Dilate = imdilate(IFish1, se);
figure(1),imshow(IallDilate)
figure(2),imshow(IFish2Dilate)
figure(3),imshow(IFish1Dilate)

imwrite(IallDilate, [TPN 'DotMapAllTrueDots.tif'], 'tif', 'compression', 'none');
imwrite(IFish2Dilate, [TPN 'DotMap' ColocAuto.Fish2 'PosDots.tif'], 'tif', 'compression', 'none');
imwrite(IFish1Dilate, [TPN 'DotMap' ColocAuto.Fish1 'PosDots.tif'], 'tif', 'compression', 'none');

close all;
clear all;
