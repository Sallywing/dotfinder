function[DFN DPN] = GetMyFile()



%% Get Folder 

if ~exist('.\temp'), mkdir('.\temp');end

if exist('.\temp\LastFile.mat')
     load(['.\temp\LastFile.mat']);
     if exist(LastFile.LastDPN)
        [DFN DPN]=uigetfile([LastFile.LastDPN LastFile.LastDFN]);
     else
        [DFN DPN] = uigetfile('*.*');
     end
else
     [DFN DPN] = uigetfile('*.*');
end

LastFile.LastDPN=DPN;
LastFile.LastDFN=DFN;
if LastFile.LastDPN>0
save('.\temp\LastFile.mat','LastFile')
end



