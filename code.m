%------------------------------------------------------------%
%-------SDTMQPSK, Necula Catalin, ETTI, UPB, 2018-2019-------%
%------------------------------------------------------------%
close all
clear all
clc
                %PARAMETRI:

                %amplitudinea semnalului purtator
Asp=1;   
                %frecventa semnalului purtator
fsp=8000
                %biti pe secunda in semnalul modulator I+Q
bps=2000;              
ordinFTB=6;
ordinFTJ=6;
                %1=zgomot existent, 0=zgomot inexistent
RSZon=1;   
                %Raportul semnal-zgomot
RSZ=2:4:14;
                %durata semnalului modulator [secunde]
dsm=1;      

%----------------------------------%               
%----------QPSK MODULATIE----------%
%----------------------------------%    
dsp=dsm;                 %durata semnalului purtator [secunde]
bitipesecunda=bps/2;     %biti pe secunda in semnalele modulatoare I si Q

%calculul 'frecventei de esantionare', frecventa folosita pentru
%efectuarea simularilor
for i=fsp*100:1:fsp*bitipesecunda*20
    if mod(i,bitipesecunda)==0 && mod(i,4*fsp)==0 && mod(i,5*fsp)==0
        Fes=2*i;
        break
    end
end
Fes=fsp*bps/2;

perioada=1/fsp;          %perioada semnalului purtator
Tes=1/Fes;               %timpul intre 2 esantioane

tsm=0:Tes:dsm-Tes;       %vectorul timp pentru semnalul modulator
tsp=0:Tes:dsp-Tes;       %vectorul timp pentru semnalul purtator

%variabile pentru usurarea scrierii codului:
duratabit=1/bitipesecunda;
esantioanepebit=Fes*duratabit;
bitiinsemnal=dsm/duratabit;
esantioanepeperioada=Fes*perioada;
perioadepebit=esantioanepebit/esantioanepeperioada;
perioadapebit2=duratabit/perioada;

%generarea unui sir de valori binare aleatoare
for i=1:1:bitiinsemnal*2
    sirbinar(i)=round(rand(1,1));
end

%conversie serie-paralel
for i=1:1:bitiinsemnal
    sirbinarI(i)=sirbinar(2*i);
    sirbinarQ(i)=sirbinar(2*i-1);
end

%conversie binar-digital(NRZ)
for i=1:1:bitiinsemnal
    
    for j=1:1:esantioanepebit
        if sirbinarI(i)==1
             sm1(esantioanepebit*(i-1)+j)=1;    
        else
            sm1(esantioanepebit*(i-1)+j)=-1;
        end
    end  
    for j=1:1:esantioanepebit
        if sirbinarQ(i)==1
             sm2(esantioanepebit*(i-1)+j)=1;    
        else
            sm2(esantioanepebit*(i-1)+j)=-1;
        end
    end  
    
end

%generarea semnalelor purtatoare
%semnalul purtator I (cos):
sp1=Asp*cos(2*pi*fsp*tsp);    
%semnalul purtator Q (sin):
sp2=sp1;
for i=esantioanepeperioada*3/4:1:length(sp1)
        sp2(i-esantioanepeperioada*3/4+1)=sp1(i);
end

%Circuitele de multiplicare din modulator
sMI=sm1.*sp1;
sMQ=sm2.*sp2;
%Circuitul de adunare din modulator
sMinitial=sMI+sMQ;

%indicatori
PsMinitial=sum(sMinitial.^2)/length(sMinitial)
PsMinitialdB=10*log10(PsMinitial)
PsMinitialdBm=10*log10(PsMinitial/(10^-3))
PsMQdB=10*log10(sum(sMQ.^2)/length(sMQ));
PsMIdB=10*log10(sum(sMI.^2)/length(sMI));

%------------------------------------------%
%----------CANALUL DE COMUNICATIE----------%
%------------------------------------------%
iglobal=1;
%START FOR
%for iglobal=1:1:length(RSZ)

%adaugarea zgomotului
if RSZon==1
    sM=awgn(sMinitial,RSZ(iglobal),PsMinitialdB);
    sMIr=awgn(sMI,RSZ(iglobal),PsMIdB);
    sMQr=awgn(sMQ,RSZ(iglobal),PsMQdB);
else
    sM=sMinitial;
    sMIr=sMI;
    sMQr=sMQ;
end

%indicatori
zgomot=sMinitial-sM;
Pzgomot=sum(zgomot.^2)/length(zgomot)
PzgomotdB=10*log10(Pzgomot)
PzgomotdBm=10*log10(Pzgomot/(10^-3))
energiadesimbol=PsMinitial*duratabit
N0(iglobal)=Pzgomot*duratabit
EsN0dB(iglobal)=10*log10(energiadesimbol/N0(iglobal))

%------------------------------------%
%----------QPSK DEMODULATIE----------%
%------------------------------------%
%refacerea purtatoarei
%^4
s4=sM.^4;
%filtrarea FTB
fc = fsp;
[bFTB,aFTB] = butter(ordinFTB,[3*fc/(Fes/2) 5*fc/(Fes/2)]);
s4FTB=filter(bFTB,aFTB,s4);
%*(-2)
s4FTB2=s4FTB*(-2);
%subesantionare (obtinerea cos refaacut)
m=esantioanepeperioada/5;
for i=1:m:length(s4FTB2)
    for j=1:1:m
        sp1r(j+i-1)=s4FTB2(i);
    end
end
%obtinerea sin refacut
sp2r=sp1r;
for i=esantioanepeperioada*3/4:1:length(s4)
        sp2r(i-esantioanepeperioada*3/4+1)=sp1r(i);
end

%demodulator - circuit de multiplicare
sdI=sM.*sp1r;
sdQ=sM.*sp2r;

%filtrul FTJ
fc = fsp;
[bFTJ,aFTJ] = butter(ordinFTJ,fc/(Fes/2));
%filtrarea FTJ a semnalelor demodulate
sdFTJI=filter(bFTJ,aFTJ,sdI);
sdFTJQ=filter(bFTJ,aFTJ,sdQ);

%circuit de refacere semnal
sdFTJI=sdFTJI*10;
sdFTJQ=sdFTJQ*10;
for i=1:1:bitiinsemnal
    medie1(i)=mean(sdFTJI(esantioanepebit*(i-1)+1:1:esantioanepebit*i));
    medie2(i)=mean(sdFTJQ(esantioanepebit*(i-1)+1:1:esantioanepebit*i));
    
    for j=1:1:esantioanepebit
            if medie1(i)>0 
             sdRSI(esantioanepebit*(i-1)+j)=1;
            else
             sdRSI(esantioanepebit*(i-1)+j)=-1;
            end
            
            if medie2(i)>0
             sdRSQ(esantioanepebit*(i-1)+j)=1;
            else 
             sdRSQ(esantioanepebit*(i-1)+j)=-1;
            end
     end
end

%conversie digital-binar
count=1;
for i=round(esantioanepebit/2):esantioanepebit:esantioanepebit*bitiinsemnal
    if sdRSI(i)==1
        sirbinarIr(count)=1;
    else
        sirbinarIr(count)=0;
    end
     if sdRSQ(i)==1
        sirbinarQr(count)=1;
    else
        sirbinarQr(count)=0;
     end
    count=count+1;
end

%conversie paralel-serie
count=1;
for i=1:2:bitiinsemnal*2
    sirbinarr(i)=sirbinarQr(count);
    sirbinarr(i+1)=sirbinarIr(count);
    count=count+1;
end

%calculul numarului de biti eronati receptionati
errsirbinar=sirbinarr-sirbinar;
errcount=0;
for i=1:1:length(errsirbinar)
    if errsirbinar(i)~=0
        errcount=errcount+1;
    end
end

%indicatori
BER(iglobal)=errcount/(bitiinsemnal*2)
BERestimat(iglobal)=1/2*erfc(1/2*sqrt(RSZ(iglobal)*duratabit*bps))
RSZcalculat(iglobal)=10*log10(PsMinitial/Pzgomot)

%END FOR
%end

%verificare calitativa a bitilor eronati
err1=sm1-sdRSI;
err2=sm2-sdRSQ;

%-------------------------------------%
%----------AFISARE REZULTATE----------%
%-------------------------------------%

%valori folosite pentru afisarea rezultatelor
%numarul biti de afisat
numarbiti=5;  
%parametri pentru calculul fft
Nfft=2048*8;
w=-pi:2*pi/Nfft:pi-2*pi/Nfft; 

%afisarea semnalelor modulatoare I si Q
figure()
subplot(2,1,1)
    plot(tsm,sm1) 
    title('semnalul modulator 1')
    xlabel('timp [s]')
    ylabel('amplitudine')
    ylim([-2,2])
    xlim([0 numarbiti*duratabit])
subplot(2,1,2)
    plot(tsm,sm2) 
    title('semnalul modulator 2')
    xlabel('timp [s]')
    ylabel('amplitudine')
    ylim([-2,2])
    xlim([0 numarbiti*duratabit])

%afisarea semnalelor purtatoare I si Q
figure()
subplot(2,1,1)
    plot(tsp,sp1)
    title('semnalul purtator cos')
    xlabel('timp [s]')
    xlim([0 numarbiti*duratabit])
    ylabel('amplitudine') 
    ylim([-1.2*Asp 1.2*Asp])
subplot(2,1,2)
    plot(tsp,sp2)
    title('semnalul purtator sin')
    xlabel('timp [s]')
    xlim([0 numarbiti*duratabit])
    ylabel('amplitudine') 
    ylim([-1.2*Asp 1.2*Asp])

%afisarea semnalelor modulate I si Q
figure()
subplot(2,1,1)
    plot(tsm, sMI)
    title('semnalul modulat I')
    xlabel('timp [s]')
    xlim([0 numarbiti*duratabit])
    ylabel('amplitudine')
    ylim([-1.2*Asp 1.2*Asp])
subplot(2,1,2)
    plot(tsm,sMQ)
    title('semnalul modulat Q')
    xlabel('timp [s]')
    xlim([0 numarbiti*duratabit])
    ylabel('amplitudine')
    ylim([-1.2*Asp 1.2*Asp])

%afisarea semnalelor modulate I si Q si a semnalului modulat QPSK
figure()
subplot(2,1,1)
    plot(tsm, sMI)
    title('semnalele modulate I si Q')
    hold on;
    plot(tsm, sMQ, 'LineWidth', 1.2)
    xlabel('timp [s]')
    xlim([0 numarbiti*duratabit])
    ylabel('amplitudine')
    ylim([-1.2*Asp 1.2*Asp])
    legend('semnalul I', 'semnalul Q')
subplot(2,1,2)
    plot(tsm,sMinitial)
    title('semnalul modulat QPSK')
    xlabel('timp [s]')
    xlim([0 numarbiti*duratabit])
    ylabel('amplitudine')
    ylim([-1.8*Asp 1.8*Asp])

%Spectrele semnalelor modulatoare I si Q, spectrele semnalelor purtatoare
%I si Q, si spectrul semnalului modulat QPSK
Sm1=fft(sm1,Nfft);
Sm2=fft(sm2,Nfft);
Sp1=fft(sp1,Nfft);
Sp2=fft(sp2,Nfft);
SMinitial=fft(sMinitial,Nfft);
Zgomot=fft(zgomot,Nfft);

%afisarea spectrelor semnalelor modulatoare I si Q
figure()
subplot(2,1,1)
    stem(w/(2*pi)*Fes, fftshift(abs(Sm1))/length(Sm1)*2)
    title('spectrul semnalului modulator 1')
    xlabel('frecventa [Hz]')
    ylabel('amplitudine')
subplot(2,1,2)
    stem(w/(2*pi)*Fes, fftshift(abs(Sm2))/length(Sm2)*2)
    title('spectrul semnalului modulator 2')
    xlabel('frecventa [Hz]')
    ylabel('amplitudine')

%afisarea spectrelor semnalelor purtatoare I si Q
figure()
subplot(2,1,1)
    stem(w/(2*pi)*Fes, fftshift(abs(Sp1))/length(Sp1)*2)
    title('spectrul semnalului purtator cos')
    xlabel('frecventa [Hz]')
    ylabel('amplitudine')
    xlim([fsp-10/100*fsp fsp+10/100*fsp])
subplot(2,1,2)
    stem(w/(2*pi)*Fes, fftshift(abs(Sp2))/length(Sp2)*2)
    title('spectrul semnalului purtator sin')
    xlabel('frecventa [Hz]')
    ylabel('amplitudine')
    xlim([fsp-10/100*fsp fsp+10/100*fsp])

%afisarea spectrului semnalului modulat QPSK
figure()
subplot(2,1,1)
    stem(w/(2*pi)*Fes, fftshift(abs(SMinitial))/length(SMinitial)*2)
    title('spectrul semnalului QPSK');
    xlabel('frecventa [Hz]')
    ylabel('amplitudine')
 
%afisarea zgomotului si a semnalului QPSK afectat de zgomot
figure()
subplot(2,1,1)
    plot(tsm, zgomot)
    title('Zgomot alb aditiv gaussian')
    xlabel('timp [s]')
    xlim([0 numarbiti*duratabit])
    ylabel('amplitudine')
subplot(2,1,2)
    plot(tsm, sM)
    title('semnalul modulat QPSK afectat de zgomot - la receptie')
    xlabel('timp [s]')
    xlim([0 numarbiti*duratabit])
    ylabel('amplitudine')
    ylim([-2*Asp 2*Asp])

%afisarea semnalului QPSK la emisie, respectiv la receptie
figure()
subplot(2,1,1)
    plot(tsm, sMinitial)
    title('semnalul modulat QPSK - la emisie')
    xlabel('timp [s]')
    xlim([0 numarbiti*duratabit])
    ylabel('amplitudine')
    ylim([-2*Asp 2*Asp])
subplot(2,1,2)
    plot(tsm, sM)
    title('semnalul modulat QPSK afectat de zgomot - la receptie')
    xlabel('timp [s]')
    xlim([0 numarbiti*duratabit])
    ylabel('amplitudine')
    ylim([-2*Asp 2*Asp])

%Semnalele din interiorul circuitului RP
figure()
subplot(2,2,1)
    plot(tsm, s4)
    title('RP - s4')
    xlim([0 (numarbiti-3)*duratabit]) 
    xlabel('timp [s]')
    ylabel('amplitudine')
subplot(2,2,2)
    plot(tsm, s4FTB)
    title('RP - s4FTJ')
    xlim([0 (numarbiti-3)*duratabit]) 
    xlabel('timp [s]')
    ylabel('amplitudine')
subplot(2,2,3)
    plot(tsm, s4FTB2)
    title('RP - s4FTJ2')
    xlim([0 (numarbiti-3)*duratabit]) 
    xlabel('timp [s]')
    ylabel('amplitudine')
subplot(2,2,4)
    plot(tsm, sp1r)
    title('RP - sp1r')
    xlim([0 (numarbiti-3)*duratabit]) 
    xlabel('timp [s]')
    ylabel('amplitudine')
 
%afisarea semnalelor demodulate I si Q, inainte de FTJ
figure()
subplot(2,1,1)
    plot(tsm, sdI)
    title('semnalul demodulat I, inainte de FTJ')
    xlabel('timp [s]')
    xlim([0 numarbiti*duratabit])
    ylabel('amplitudine')   
subplot(2,1,2)
    plot(tsm, sdQ)
    title('semnalul demodulat Q, inainte de FTJ')
    xlabel('timp [s]')
    xlim([0 numarbiti*duratabit])
    ylabel('amplitudine')
    
%Spectrele semnalelor demodulate I si Q, inainte de FTJ
SdI=fft(sdI,Nfft);
SdQ=fft(sdQ,Nfft);

%afisarea spectrelor semnalelor demodulate I si Q, ianinte de FTJ
figure()
    subplot(2,1,1)
    stem(w/(2*pi)*Fes, fftshift(abs(SdI))/length(SdI)*2)
    title('spectrul semnalului demodulat I, inainte de FTJ')
    xlabel('frecventa [Hz]')
    ylabel('amplitudine')
subplot(2,1,2)
    stem(w/(2*pi)*Fes, fftshift(abs(SdQ))/length(SdQ)*2)
    title('spectrul semnalului demodulat Q, inainte de FTJ')
    xlabel('frecventa [Hz]')
    ylabel('amplitudine')

%afisarea semnalelor demodulate I si Q, dupa FTJ
figure()
subplot(2,1,1)
    plot(tsm,sdFTJI) 
    title('semnalul demodulat I, dupa FTJ')
    xlabel('timp [s]')
    ylabel('amplitudine')
    xlim([0 numarbiti*duratabit])
subplot(2,1,2)
    plot(tsm,sdFTJQ) 
    title('semnalul demodulat Q, dupa FTJ')
    xlabel('timp [s]')
    ylabel('amplitudine')
    xlim([0 numarbiti*duratabit])

%Spectrele semnalelor demodulate I si Q, dupa FTJ
SdFTJI=fft(sdFTJI,Nfft);
SdFTJQ=fft(sdFTJQ,Nfft);
figure()
subplot(2,1,1)
    stem(w/(2*pi)*Fes, fftshift(abs(SdFTJI))/length(SdFTJI)*2)
    title('spectrul semnalului demodulat I, dupa FTJ')
    xlabel('frecventa [Hz]')
    ylabel('amplitudine')
subplot(2,1,2)
    stem(w/(2*pi)*Fes, fftshift(abs(SdFTJQ))/length(SdFTJQ)*2)
    title('spectrul semnalului demodulat Q, dupa FTJ')
    xlabel('frecventa [Hz]')
    ylabel('amplitudine')

%afisare comparatie inainte si dupa FTJ
figure()
subplot(2,1,1)
    plot(tsm, sdI)
    title('semnalul demodulat I, inainte de FTJ')
    xlabel('timp [s]')
    xlim([0 numarbiti*duratabit])
    ylabel('amplitudine')
subplot(2,1,2)
    plot(tsm,sdFTJI) 
    title('semnalul demodulat I, dupa FTJ')
    xlabel('timp [s]')
    ylabel('amplitudine')
    xlim([0 numarbiti*duratabit])

%afisarea semnalelor demodulate, dupa circuitul RS
figure()
subplot(2,1,1)
    plot(tsm,sdRSI) 
    title('semnalul demodulat refacut I')
    xlabel('timp [s]')
    ylabel('amplitudine')
    ylim([-2,2])
    xlim([0 numarbiti*duratabit])
subplot(2,1,2)
    plot(tsm,sdRSQ) 
    title('semnalul demodulat refacut Q')
    xlabel('timp [s]')
    ylabel('amplitudine')
    ylim([-2,2])
    xlim([0 numarbiti*duratabit])

%afisare comparatie FTJ-RS
figure()
subplot(2,1,1)
    plot(tsm,sdFTJI) 
    title('semnalul demodulat I, dupa FTJ')
    xlabel('timp [s]')
    ylabel('amplitudine')
    xlim([0 numarbiti*duratabit])
subplot(2,1,2)
    plot(tsm,sdRSI) 
    title('semnalul demodulat refacut I')
    xlabel('timp [s]')
    ylabel('amplitudine')
    ylim([-2,2])
    xlim([0 numarbiti*duratabit])

%afisare erori pentru verificare calitativa a bitilor eronati
figure()
subplot(2,1,1)
    plot(tsm,err1) 
    title('eroare semnalul demodulat refacut 1')
    xlabel('timp [s]')
    ylabel('amplitudine')    
subplot(2,1,2)
    plot(tsm,err2) 
    title('eroare semnalul demodulat refacut 2')
    xlabel('timp [s]') 
    ylabel('amplitudine')

%Grafice BER-RSZ si BER-EsN0dV    
figure()
    semilogy(RSZ,BER,'-.or')
    title('RSZ-BER')
    xlabel('RSZ (dB)') 
    xlim([min(RSZ) max(RSZ)+1])
    ylabel('BER')   
figure()
    semilogy(EsN0dB,BER,'-.or')
    title('E_s/N_0 - BER')
    xlabel('E_s/N_0 (dB)') 
    xlim([min(RSZ) max(RSZ)+1])
    ylabel('BER') 

%----------SCATTERPLOT----------%
factordecimare=esantioanepebit/(perioadepebit*2);
    %scatterplot(X, N) generates a scatter plot of X with decimation 
    %factor N. Every Nth point in X is plotted, starting with the first 
    %value.  The default for N is 1.
offset=esantioanepebit/(perioadepebit*8);
    %OFFSET is the number of samples skipped at the beginning of X before
    %plotting.  The default value for OFFSET is zero.

scatterplot(sMI+sMQ*1j,factordecimare,offset,'ored')
    grid on
    hold on
    viscircles([0,0],Asp,'LineStyle','-','EdgeColor','b','LineWidth',1);
    title('constelatie QPSK')
    hold off
    xlabel('Faza')
    xlim([-1.2*Asp 1.2*Asp])
    ylabel('Cuadratura')
    ylim([-1.2*Asp 1.2*Asp])
scatterplot(sMIr+sMQr*1j,factordecimare,offset,'ored')
    grid on
    hold on
    viscircles([0,0],Asp,'LineStyle','-','EdgeColor','b','LineWidth',1);
    title('constelatie QPSK la receptie')
    hold off
    xlabel('Faza')
    xlim([-1.2*Asp 1.2*Asp])
    ylabel('Cuadratura')
    ylim([-1.2*Asp 1.2*Asp])
