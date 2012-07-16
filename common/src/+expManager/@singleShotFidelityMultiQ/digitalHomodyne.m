%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Module Name :  digitalHomodyne.m
 %
 % Author/Date : Jerry Moy Chow / October 19, 2010
 %
 % Description : This function implements single channel digital homodyne
 % Takes only a single channel of the data, either the I or Q 
 % and digitally mixes into two single points, a digital I and Q,
 % based on the total size of the dataset
 %
 % Version: 1.0
 %
 %    Modified    By    Reason
 %    --------    --    ------
 %    10-19-2010  BRJ   Integration into qlab framework
 %    27 March 2012 CAR Vectorize and low-pass filtering.  
 %
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% This function implements single channel digital homodyne
% Takes only a single channel of the data, either the I or Q (default to
% the I) and digitally mixes into two single points, a digital I and Q,
% based on the total size of the dataset

function [DI DQ] =  digitalHomodyne(signal, IFfreq, sampInterval, integrationStart, integrationPts)
    % first define a variable that takes the total length of the signal
    if nargin < 5
        L = size(signal,1);
		integrationStart = 1;
    else
        L = integrationPts;
    end
    
    %Setup the butterworth low-pass
    %Unfortunately we don't have the Filter toolbox so we have to create
    %our own.  The filter cutoff is arbitrary but we put it at the IF
    %frequency.
    sampRate = 1/sampInterval;
    [b,a] = my_butter(IFfreq/(sampRate/2));
    
    %The signal is a 2D array with acquisition along a column
    
    %Create the scaled reference signal
    refSignal = exp(1i*2*pi*IFfreq*sampInterval*(1:1:size(signal,1)))';
    
    %Demodulate and filter
    demodSignal = filter(b,a, signal.*repmat(refSignal,[1,size(signal,2)]));
    
    %Let's decimate the signal down by a factor of eight
    [b,a] = my_butter(0.5/8);
    demodSignal = filter(b,a, demodSignal);
    demodSignal = demodSignal(1:8:end,:);
    integrationStart = fix(integrationStart/8);
    L = fix(L/8);
%     
%     save(['SSResults-'  datestr(now, 'yyyy-mm-dd-HH-MM-SS')], 'demodSignal');
    %Return the summed real and imaginary parts (as column vectors for no
    %good reason).
    weighting = ones(1, size(demodSignal,1));
    %Add an additional weighting of a filtered (by the cavity) T1 decay
%     T1 = 1e-6;
%     kappa = 2e-6;
%     k = sampInterval/kappa;
%     b = [0, k]; a = [1, k-1];
%     shiftedPts = (1:size(signal,1)) - integrationStart;
%     weighting = filter(b,a, (0.5*(sign(shiftedPts)+1)).*exp(-(shiftedPts*sampInterval/T1)));
    weighting = weighting/sum(weighting);
    demodSignal = demodSignal.*repmat(weighting',1,size(demodSignal,2));
    tmpSum = sum(demodSignal(integrationStart:integrationStart+L-1,:))';
    DI = real(tmpSum);
    DQ = imag(tmpSum);
 
    function [b,a] = my_butter(normIFFreq)
        %Steal variable-order butter-worth filter design from scipy in a table
        %form. These are created in create_butter_table.py.  
        %We discretize at 0.01 of the sampling frequency
        
        %Find the closest cut-off frequency in percentage
        assert(normIFFreq >= 0.01 && normIFFreq < 1, 'Oops! The normalized cutoff is not between 0.02 and 1')
        roundedCutOff = floor(normIFFreq*100)+1;
        
        %Create the arrays of a's and b's
        filterCoeffs.a = {...
            [ 1.         -2.99058254  2.98140538 -0.99082163];...
            [ 1.         -2.98077313  2.96251022 -0.98172746];...
            [ 1.         -2.97057402  2.94332306 -0.97271668];...
            [ 1.         -2.95998751  2.92385237 -0.9637885 ];...
            [ 1.         -2.94901596  2.90410655 -0.95494211];...
            [ 1.         -2.93766178  2.88409394 -0.94617673];...
            [ 1.         -2.92592743  2.86382282 -0.93749157];...
            [ 1.         -2.91381541  2.8433014  -0.92888586];...
            [ 1.         -2.90132828  2.82253783 -0.92035883];...
            [ 1.         -2.88846862  2.80154019 -0.9119097 ];...
            [ 1.         -2.87523906  2.78031653 -0.90353772];...
            [ 1.         -2.86164228  2.75887479 -0.89524213];...
            [ 1.         -2.84768097  2.73722288 -0.88702217];...
            [ 1.         -2.83335788  2.71536864 -0.8788771 ];...
            [ 1.         -2.81867578  2.69331986 -0.87080616];...
            [ 1.         -2.80363748  2.67108426 -0.86280861];...
            [ 1.         -2.78824579  2.6486695  -0.85488372];...
            [ 1.         -2.77250358  2.62608318 -0.84703073];...
            [ 1.         -2.75641373  2.60333286 -0.83924891];...
            [ 1.         -2.73997916  2.58042601 -0.83153752];...
            [ 1.         -2.72320278  2.55737008 -0.82389583];...
            [ 1.         -2.70608755  2.53417244 -0.81632311];...
            [ 1.         -2.68863644  2.51084041 -0.80881862];...
            [ 1.         -2.67085244  2.48738127 -0.80138163];...
            [ 1.         -2.65273855  2.46380222 -0.79401141];...
            [ 1.         -2.6342978   2.44011043 -0.78670723];...
            [ 1.         -2.61553323  2.41631302 -0.77946835];...
            [ 1.         -2.59644788  2.39241703 -0.77229404];...
            [ 1.         -2.57704483  2.36842949 -0.76518357];...
            [ 1.         -2.55732714  2.34435735 -0.75813621];...
            [ 1.         -2.53729791  2.32020753 -0.75115122];...
            [ 1.         -2.51696023  2.29598689 -0.74422787];...
            [ 1.         -2.49631721  2.27170227 -0.73736541];...
            [ 1.         -2.47537196  2.24736042 -0.73056311];...
            [ 1.         -2.45412761  2.2229681  -0.72382023];...
            [ 1.         -2.43258728  2.19853199 -0.71713602];...
            [ 1.         -2.41075412  2.17405873 -0.71050974];...
            [ 1.         -2.38863127  2.14955494 -0.70394065];...
            [ 1.         -2.36622186  2.12502719 -0.69742798];...
            [ 1.         -2.34352906  2.10048201 -0.69097098];...
            [ 1.         -2.32055602  2.07592589 -0.68456891];...
            [ 1.         -2.2973059   2.05136529 -0.67822099];...
            [ 1.         -2.27378186  2.02680664 -0.67192646];...
            [ 1.         -2.24998707  2.00225633 -0.66568455];...
            [ 1.         -2.2259247   1.97772071 -0.65949449];...
            [ 1.         -2.20159791  1.95320611 -0.6533555 ];...
            [ 1.         -2.17700989  1.92871883 -0.64726679];...
            [ 1.         -2.15216379  1.90426514 -0.64122759];...
            [ 1.         -2.1270628   1.87985128 -0.63523709];...
            [ 1.         -2.10171009  1.85548346 -0.6292945 ];...
            [ 1.         -2.07610884  1.83116789 -0.62339901];...
            [ 1.         -2.05026223  1.80691071 -0.61754981];...
            [ 1.         -2.02417343  1.78271809 -0.61174608];...
            [ 1.         -1.99784562  1.75859613 -0.60598699];...
            [ 1.         -1.97128198  1.73455096 -0.60027173];...
            [ 1.         -1.94448569  1.71058864 -0.59459944];...
            [ 1.         -1.91745993  1.68671526 -0.58896927];...
            [ 1.         -1.89020787  1.66293687 -0.58338038];...
            [ 1.         -1.8627327   1.63925949 -0.5778319 ];...
            [ 1.         -1.83503759  1.61568917 -0.57232296];...
            [ 1.         -1.80712572  1.59223192 -0.56685267];...
            [ 1.         -1.77900027  1.56889373 -0.56142014];...
            [ 1.         -1.75066442  1.5456806  -0.55602448];...
            [ 1.         -1.72212135  1.52259853 -0.55066476];...
            [ 1.         -0.97505589  0.55401557];...
            [ 1.         -0.95513845  0.55005202];...
            [ 1.         -0.93513005  0.54617269];...
            [ 1.         -0.9150316   0.54237759];...
            [ 1.         -0.89484397  0.53866673];...
            [ 1.         -0.87456804  0.53504015];...
            [ 1.         -0.85420463  0.53149792];...
            [ 1.         -0.83375456  0.52804009];...
            [ 1.         -0.81321865  0.52466674];...
            [ 1.         -0.79259768  0.52137797];...
            [ 1.         -0.77189241  0.51817388];...
            [ 1.         -0.75110361  0.51505459];...
            [ 1.         -0.73023201  0.51202026];...
            [ 1.         -0.70927834  0.50907102];...
            [ 1.         -0.68824332  0.50620704];...
            [ 1.         -0.66712766  0.50342852];...
            [ 1.         -0.64593206  0.50073564];...
            [ 1.         -0.6246572   0.49812862];...
            [ 1.         -0.60330376  0.4956077 ];...
            [ 1.         -0.58187242  0.49317311];...
            [ 1.         -0.56036385  0.49082512];...
            [ 1.         -0.53877872  0.488564  ];...
            [ 1.         -0.51711769  0.48639006];...
            [ 1.         -0.49538142  0.4843036 ];...
            [ 1.         -0.47357057  0.48230496];...
            [ 1.         -0.45168581  0.48039446];...
            [ 1.         -0.42972779  0.47857249];...
            [ 1.         -0.40769718  0.47683941];...
            [ 1.         -0.38559466  0.47519563];...
            [ 1.         -0.3634209   0.47364155];...
            [ 1.         -0.34117657  0.47217761];...
            [ 1.         -0.31886237  0.47080426];...
            [ 1.         -0.296479    0.46952196];...
            [ 1.         -0.01452229];...
            [ 1.         -0.00666697]};

        filterCoeffs.b = {...
            [ 0.00092921 -0.00092861 -0.00092861  0.00092921];...
            [ 0.00185062 -0.00184581 -0.00184581  0.00185062];...
            [ 0.00276502 -0.00274884 -0.00274884  0.00276502];...
            [ 0.00367317 -0.00363499 -0.00363499  0.00367317];...
            [ 0.00457585 -0.00450161 -0.00450161  0.00457585];...
            [ 0.0054738  -0.00534608 -0.00534608  0.0054738 ];...
            [ 0.00636776 -0.00616585 -0.00616585  0.00636776];...
            [ 0.00725845 -0.00695839 -0.00695839  0.00725845];...
            [ 0.0081466  -0.00772124 -0.00772124  0.0081466 ];...
            [ 0.00903289 -0.00845195 -0.00845195  0.00903289];...
            [ 0.00991803 -0.00914816 -0.00914816  0.00991803];...
            [ 0.01080269 -0.0098075  -0.0098075   0.01080269];...
            [ 0.01168754 -0.01042767 -0.01042767  0.01168754];...
            [ 0.01257324 -0.01100641 -0.01100641  0.01257324];...
            [ 0.01346044 -0.01154148 -0.01154148  0.01346044];...
            [ 0.01434978 -0.01203069 -0.01203069  0.01434978];...
            [ 0.01524189 -0.0124719  -0.0124719   0.01524189];...
            [ 0.0161374  -0.01286296 -0.01286296  0.0161374 ];...
            [ 0.01703692 -0.01320181 -0.01320181  0.01703692];...
            [ 0.01794105 -0.01348638 -0.01348638  0.01794105];...
            [ 0.01885038 -0.01371465 -0.01371465  0.01885038];...
            [ 0.01976552 -0.01388462 -0.01388462  0.01976552];...
            [ 0.02068703 -0.01399435 -0.01399435  0.02068703];...
            [ 0.02161549 -0.01404189 -0.01404189  0.02161549];...
            [ 0.02255147 -0.01402534 -0.01402534  0.02255147];...
            [ 0.02349553 -0.01394283 -0.01394283  0.02349553];...
            [ 0.02444823 -0.01379251 -0.01379251  0.02444823];...
            [ 0.0254101  -0.01357254 -0.01357254  0.0254101 ];...
            [ 0.02638169 -0.01328115 -0.01328115  0.02638169];...
            [ 0.02736353 -0.01291654 -0.01291654  0.02736353];...
            [ 0.02835616 -0.01247696 -0.01247696  0.02835616];...
            [ 0.02936009 -0.01196069 -0.01196069  0.02936009];...
            [ 0.03037585 -0.01136603 -0.01136603  0.03037585];...
            [ 0.03140395 -0.01069127 -0.01069127  0.03140395];...
            [ 0.0324449  -0.00993477 -0.00993477  0.0324449 ];...
            [ 0.0334992  -0.00909486 -0.00909486  0.0334992 ];...
            [ 0.03456735 -0.00816991 -0.00816991  0.03456735];...
            [ 0.03564984 -0.00715833 -0.00715833  0.03564984];...
            [ 0.03674718 -0.00605851 -0.00605851  0.03674718];...
            [ 0.03785985 -0.00486887 -0.00486887  0.03785985];...
            [ 0.03898833 -0.00358785 -0.00358785  0.03898833];...
            [ 0.04013311 -0.00221391 -0.00221391  0.04013311];...
            [ 0.04129466 -0.0007455  -0.0007455   0.04129466];...
            [ 0.04247346  0.00081889  0.00081889  0.04247346];...
            [ 0.04366999  0.00248077  0.00248077  0.04366999];...
            [ 0.04488471  0.00424164  0.00424164  0.04488471];...
            [ 0.04611809  0.00610298  0.00610298  0.04611809];...
            [ 0.04737061  0.00806627  0.00806627  0.04737061];...
            [ 0.04864272  0.01013297  0.01013297  0.04864272];...
            [ 0.04993489  0.01230454  0.01230454  0.04993489];...
            [ 0.05124759  0.01458243  0.01458243  0.05124759];...
            [ 0.05258126  0.01696807  0.01696807  0.05258126];...
            [ 0.05393638  0.01946291  0.01946291  0.05393638];...
            [ 0.05531341  0.02206835  0.02206835  0.05531341];...
            [ 0.05671279  0.02478583  0.02478583  0.05671279];...
            [ 0.05813499  0.02761676  0.02761676  0.05813499];...
            [ 0.05958048  0.03056255  0.03056255  0.05958048];...
            [ 0.0610497   0.03362461  0.03362461  0.0610497 ];...
            [ 0.06254311  0.03680433  0.03680433  0.06254311];...
            [ 0.06406118  0.04010313  0.04010313  0.06406118];...
            [ 0.06560437  0.0435224   0.0435224   0.06560437];...
            [ 0.06717313  0.04706353  0.04706353  0.06717313];...
            [ 0.06876793  0.05072793  0.05072793  0.06876793];...
            [ 0.07038922  0.05451699  0.05451699  0.07038922];...
            [ 0.12246266  0.16494675  0.12246266];...
            [ 0.12509748  0.1709716   0.12509748];...
            [ 0.12776325  0.17705856  0.12776325];...
            [ 0.13045982  0.18320731  0.13045982];...
            [ 0.13318704  0.18941751  0.13318704];...
            [ 0.13594479  0.19568888  0.13594479];...
            [ 0.13873291  0.20202111  0.13873291];...
            [ 0.14155129  0.20841393  0.14155129];...
            [ 0.14439981  0.21486706  0.14439981];...
            [ 0.14727834  0.22138025  0.14727834];...
            [ 0.15018679  0.22795324  0.15018679];...
            [ 0.15312504  0.2345858   0.15312504];...
            [ 0.15609299  0.24127771  0.15609299];...
            [ 0.15909056  0.24802874  0.15909056];...
            [ 0.16211764  0.25483868  0.16211764];...
            [ 0.16517416  0.26170734  0.16517416];...
            [ 0.16826003  0.26863452  0.16826003];...
            [ 0.17137518  0.27562005  0.17137518];...
            [ 0.17451953  0.28266375  0.17451953];...
            [ 0.17769302  0.28976545  0.17769302];...
            [ 0.18089557  0.29692499  0.18089557];...
            [ 0.18412713  0.30414222  0.18412713];...
            [ 0.18738765  0.311417    0.18738765];...
            [ 0.19067706  0.31874918  0.19067706];...
            [ 0.19399531  0.32613863  0.19399531];...
            [ 0.19734236  0.33358523  0.19734236];...
            [ 0.20071817  0.34108885  0.20071817];...
            [ 0.20412268  0.34864937  0.20412268];...
            [ 0.20755586  0.35626668  0.20755586];...
            [ 0.21101768  0.36394067  0.21101768];...
            [ 0.21450809  0.37167124  0.21450809];...
            [ 0.21802706  0.37945827  0.21802706];...
            [ 0.22157457  0.38730168  0.22157457];...
            [ 0.49273885  0.49273885];...
            [ 0.49666652  0.49666652]};

        
        %Pick out the row of coefficients. 
        b = filterCoeffs.b{roundedCutOff-1};
        a = filterCoeffs.a{roundedCutOff-1};
        
    end
    
end