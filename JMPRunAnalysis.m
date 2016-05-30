

%% GET DIRECTORY OF CELL
TPN = GetMyDir;
%yxum=0.103;
%zum=0.3;

%% GENERATE USE
close all;
JMPanaMakeUseOnec(TPN)

JMPDotsDD(TPN); %input argument of yxum and zum were removed, instead load Settings to get those within the program.
%Although I don't like the way this program defines stratification-related
%parameters, just keep the format as it is.
%Can be modified in the future for bistratified GCs.

%% GENERATE CA FOR AREA
close all;
[CA] = JMPCAsampleUse(TPN);

%% DRAW OUTPUT
JMPCAsampleCollect(TPN);

%% GENERATE GRAD
[Grad] = JMPGradient(TPN);

%% Path length stats 10/18/2011 HO to check how PSD expression attenuates along dendrites
close all;
JMPPathLengthStats(TPN);



%I should add nearest neighbor analysis plus something like Monte Carlo
%plus nearest neighbor here

%Colocalization analysis
