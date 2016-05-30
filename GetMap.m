function[Map]=GetMap()

%% Map the cells in Output folder on raid server


%% Select Folder for Batch analysis and map directory to Dat
%BatchFolder=uigetdir; %get directory containing all data folders
BatchFolder='\\128.208.64.36\wonglab\Josh\Analyzed\Output'
Dat=dir(BatchFolder); %make directory listing
Dat=Dat(3:size(Dat,1));

%% Make list of image folders
'Generating folder list'
for i=1:size(Dat,1), 
    Check=0;
    if Dat(i).isdir %first condition Dat(i) must be folder
        
        %%look for image folder
        TPN=[BatchFolder '\' Dat(i).name '\'];  %create target path name
        Map(i).TPN=TPN; Map(i).CellName = Dat(i).name;
        d=dir(TPN); %map target folder
        d=d(3:size(d,1)); %clip .  ..
        Check=zeros(size(d,1),1);  %how many did you find
        for c=1:size(d,1)  % Check all files in folder
            if  isdir([TPN  d(c).name]) && ...
                ~strcmp(d(c).name,'images') && ...
                ~strcmp(d(c).name,'pics') && ...
                ~strcmp(d(c).name,'data') && ...
                ~strcmp(d(c).name,'dataFix') && ...
                ~strcmp(d(c).name,'mask') && ...
                ~strcmp(d(c).name,'temp') && ...
                ~strcmp(d(c).name,'other'), %% if not another folder type
                
                %Check files in directory
                Files=dir([TPN  d(c).name]);
                Files=Files(3:size(Files,1));
                if size(Files,1)>2 %at least three files
                for f = 2:size(Files,1)-1 %run all but last file 
                    Tag=Files(f).name;
                    if strcmp('.tif',Tag(1,max(1,size(Tag,2)-3):size(Tag,2))) %check if tif
                        OK=1; %check if all the same size
                        if ~Files(f-1).bytes==Files(f).bytes, 
                            OK=0; %not the same size
                        end
                        Check(c)=OK;  
                    end %check all files
                  end %run all middle folders
                end% end if folder big enought
            end% End if directory
        end% End check all files in folder
    end %if Data file is folder
    if sum(Check)==1
        Map(i).IMfolder=[d(find(Check,1)).name];
    else
        Map(i).IMfolder='?';
    end
end %run all data files
   
MapC2=squeeze(struct2cell(Map));
MapC=MapC2(3,:)';
MapC(:,2)=MapC2(2,:)';

%% Run all Cells
for i=1:size(Map,2)
    
    %%Get or make Status
    clear Status
    TPN=Map(i).TPN  
    DPN=[TPN Map(i).IMfolder '\'];
    if exist([TPN 'Status.mat'])
       load([TPN 'Status.mat'])
    else 
       Status.Fix=0;
       Status.Ra=0;
       Status.Ma=0;
       Status.Dr=0;
       Status.Running=0;
       Status.FD=0;
       Status.Sk=0;
       Status.Results=0;
       save([TPN 'Status.mat'],'Status')
    end
   
    
    
    %~strcmp(Map(i).IMfolder,'?')&& 
    
    %%If data folder is found
       if exist([Map(i).TPN 'data\BigFilled.mat']), Status.FD=1;
       else Status.FD=0; end
       
       if exist([Map(i).TPN 'data\AllSeg.mat']), Status.Sk=1;
       else Status.Sk=0; end       
       
       if exist([Map(i).TPN 'data\MaskedAt.mat']), Status.Ma=1;
       else Status.Ma=0; end   
       
       if exist([Map(i).TPN 'data\DotStats.mat']), Status.Ra=1;
       else Status.Ra=0; end  
       
       if exist([Map(i).TPN 'data\Results.mat']), Status.Results=1;
       else Status.DD=0; end   

       if exist([Map(i).TPN 'dataFix']), Status.Fix =1;
       else Status.Fix=0; end
   
       if exist([Map(i).TPN 'images\Combo.tif']), Status.Dr =1;
       else Status.Dr =0; end
       
       Status.Fields=0;
       Status.Fields=fieldnames(Status);
       save([TPN 'Status.mat'],'Status')
    
       %%Write to MapC 
       S=struct2cell(Status)';
        MapC(i,3:2+size(S,2))=S;
        save([BatchFolder '\temp\MapC.mat'],'MapC')
        

        
          
end %run all data


'Done'









