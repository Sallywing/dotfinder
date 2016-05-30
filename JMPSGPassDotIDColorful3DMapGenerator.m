function[] = JMPSGPassDotIDColorful3DMapGenerator(TPN, DotType, PassType)

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

if DotType == 'Post';
    % get the passing IDS
    Iprompt = {'SG.passF:','SG.passI:'};
    Idlg_title = 'which Grouping do you want:';
    Inum_lines = 1;
    if isfield(SG, 'passI')
        Idef = {'0','1'};
    else
        Idef = {'1','0'};
    end
    Answer = inputdlg(Iprompt,Idlg_title,Inum_lines ,Idef);
    if isempty(Answer), return, end

    if str2double(cell2mat(Answer(1)))==1
        Pass = SG.passF';
    else
        Pass = SG.passI';
    end

elseif DotType == 'Colo';
    Pass = SG.passF;
    
end
    

% if isfield(SG,'passI')
%     Pass = SG.passI;
% else
%     Pass = SG.passF;
% end
    
if PassType == 'NoPs';
    Pass = Pass == 0; %reverse Pass
elseif PassType == 'Both';
    Pass(:) = 1; %all Pass
end
        
P=find(Pass); %% list of passing puncta
DotIDMapColorful=zeros(Dots.ImSize, 'uint8');
for i = 1: length(P)
    DotIDMapColorful(Dots.Vox(P(i)).Ind)=1+round(rand*254);
end
NumZ = Dots.ImSize(3);

if DotType == 'Post';
    SavingFileName = 'find\PassDotIDColorfulMap3DPost.tif';
    if PassType == 'NoPs';
        SavingFileName = 'find\NoPassDotIDColorfulMap3DPost.tif';
    elseif PassType == 'Both';
        SavingFileName = 'find\BothPassAndNoPassDotIDColorfulMap3DPost.tif';
    end
            
elseif DotType == 'Colo';
    SavingFileName = 'find\PassDotIDColorfulMap3DColo.tif';
    if PassType == 'NoPs';
        SavingFileName = 'find\NoPassDotIDColorfulMap3DColo.tif';
    elseif PassType == 'Both';
        SavingFileName = 'find\BothPassAndNoPassDotIDColorfulMap3DColo.tif';
    end
    
end

imwrite(DotIDMapColorful(:,:,1), [TPN SavingFileName], 'tif', 'compression', 'none'); %write first z plane
if NumZ > 1; %write the rest of the z planes
    for i=2:NumZ
        imwrite(DotIDMapColorful(:,:,i), [TPN SavingFileName], 'tif', 'compression', 'none', 'WriteMode', 'append');
    end
end

