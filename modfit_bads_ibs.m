function modfit_bads_ibs(whichSubj,nrun,ndT,FMod)
% evaluate only once.
close all
rng('shuffle')
savefile = ['Realfit/' FMod '_ibs_BADS_subj_',num2str(whichSubj),'_ndT',num2str(ndT),'_run',num2str(nrun)];

if exist(savefile, 'file') == 2
    load(savefile,'ProbFluct')
    if exist('ProbFluct','var')
        return
    end
end
% Reading from real data
SampleUnit = 100;
load(['FixNumLNR',num2str(SampleUnit),'_fromzero'])

load ProcessedData
D = ProcessedData;
AllSubjLabels = unique(D(:,13));
TrialLabels =find(D(:,13)==AllSubjLabels(whichSubj));
SubFixNumLNR = FixNumLNR(TrialLabels);
SubLRating = D(TrialLabels,2);
SubRRating = D(TrialLabels,1);
SubRT = allRT(TrialLabels)-ndT;
SubChoice = D(TrialLabels,3);
nbin = 50;
allRTbins = prctile(allRT,linspace(0,100,nbin+1));

% delete empty trials

switch FMod
    case 'DDM0'
    ScalingFactor = 1./[1,30,.1];
    iniPar = [.5 .5 .5] +[.05*randn(1,3)];
    lb = [-1 * ones(1,length(iniPar)-1)];
    ub = [5*ones(1,length(iniPar)-1)];
    problb =zeros(1,length(iniPar));
    probub = ones(1,length(iniPar));
    
    
    case 'DDM2'
    ScalingFactor = 1./[1,30,.1,70,5];
    iniPar = [.5 .5 .5 .5 .5] +.05*randn(size(ScalingFactor));
    lb = -1 * ones(1,length(iniPar));
    ub=5*ones(1,length(iniPar));
    problb = [0,0,0,0,0];
    probub = ones(1,length(iniPar));
    
    case 'Negstd2'
    ScalingFactor = 1./[100,10,20,30,40,.5]; % real par = ini / SF
    iniPar = [.5 .1 .3 .5 .3 .5] +.1*randn(size(ScalingFactor));
    lb = -1 * ones(size(iniPar));
    ub = 5*ones(size(iniPar));
    problb=[0,-.5,0,0,0,0];
    probub = ones(size(iniPar));
    
    
    case 'Negstdp2'
    ScalingFactor = 1./[100,10,20,30,40,.5,50]; % real par = ini / SF
    iniPar = [.5 .1 .3 .5 .3 .3,.5] +.1*randn(size(ScalingFactor));
    lb = -1 * ones(size(iniPar));
    ub = 5*ones(size(iniPar));
    problb=[0,-.5,0,0,0,0,0];
    probub = ones(size(iniPar));
    %{
    case 'Neg2'
    RandMat = randn(round(ncutoff/10)*2,250);
    ScalingFactor = 1./[200,.2,15,50,30,3];
    iniPar = [2 .6 .85 .9 .83 .67] +.05*randn(size(ScalingFactor));
    lb = -1 * ones(1,6);
    ub = 5*ones(1,6);
    problb=[0,-.5,0,0,0,0];
    probub = ones(1,6);
    
    case 'Nov2'
    RandMat = randn(round(ncutoff/10)*2,250);
    ScalingFactor = 1./[200,15,50,30,3];
    iniPar = [2 .85 .9 .83 .67] +.05*randn(size(ScalingFactor));
    lb = -1 * ones(1,5);
    ub = 5*ones(1,5);
    problb=[0,0,0,0,0];
    probub = ones(1,5);
    
    case 'Neg22'
    RandMat = randn(round(ncutoff/10)*2,250);

    load('novparsd')
    subparsd = novparsd(whichSubj,:);
    subparsd(2)=1;
    ScalingFactor = 0.5./subparsd;
    iniPar =subparsd.*ScalingFactor+.05*randn(size(ScalingFactor));
    lb = -1 * ones(1,6);
    ub = 5*ones(1,6);
    problb=[0,-.5,0,0,0,0];
    probub = ones(1,6);
    
    case 'Inv2' 
    RandMat = randn(ceil(ncutoff/10)*2,250);
    ScalingFactor = 1./[600,10,35,50,30,2];
    iniPar = [.2 .2 .5 .2 .5 .3] +.05*randn(size(ScalingFactor));
    lb = -1 * ones(1,6);
    ub = 5*ones(1,6);
    problb=[0,-.5,0,0,0,0];
    probub = ones(1,6);
    otherwise
        error('input Fmod err')
    %}
end
% add lambda for ibs
iniPar = [iniPar,0.01];
ScalingFactor = [ScalingFactor,1];
lb = [lb,0];
ub = [ub,1];
problb =[problb,0];
probub =[probub,.1];
modfun = ['modfun_' FMod];

%%
% BADS optimization
tic
options = [];                       % Reset the OPTIONS struct
options.UncertaintyHandling = 1;    % Tell BADS that the objective is noisy
options.NoiseSize           = 1;    % Estimate of noise std
options.NoiseFinalSamples   = 10;  % # samples to estimate FVAL at the end


options.MaxIter = 1 % just for debugging 
LLcutoff = 4.6; % -log(1/100) = 4.605, 100 for all possible responses
% start fitting
clear ibs_LPwrapper
[thisFittedPara,LogProb100ms,exitflag,output] = bads('ibs_LPwrapper',iniPar,lb,ub,problb,probub,[],options,modfun,ScalingFactor,SubFixNumLNR, SubLRating,SubRRating, SubChoice,SubRT,allRTbins,LLcutoff,savefile);

% get prob fluct
nrep = 10;
ProbFluct = nan(1,nrep);
for krep = 1:nrep
    ProbFluct(krep) = ibs_LPwrapper(thisFittedPara,modfun,ScalingFactor,SubFixNumLNR, SubLRating,SubRRating, SubChoice,SubRT,allRTbins,LLcutoff,[]);
end
thisFittedPara = thisFittedPara./ScalingFactor;
save(savefile,'ProbFluct','LogProb100ms','ScalingFactor','thisFittedPara','exitflag','output','-append')

end
