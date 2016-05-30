function[TPN] = JMPGetMyDir(title)



%% Get Folder 

if ~exist('.\temp'), mkdir('.\temp');end

if exist('.\temp\Last.mat')
     load(['.\temp\Last.mat']);
     if exist(Last)
        TPN=uigetdir(Last, title);
     else
         TPN=uigetdir([], title);
     end
else
    TPN=uigetdir([], title);
end

TPN= [TPN '\'];

Last=TPN;
if Last>0
save('.\temp\Last.mat','Last')
end
