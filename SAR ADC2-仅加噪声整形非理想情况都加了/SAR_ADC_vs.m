function [Dout,VC1p,VC2p,VC1n,VC2n]=SAR_ADC_vs(Vinp,Vinn,VDD,Vcm,C_SAR_weight,C_tot,N,VC1p,VC2p,VC1n,VC2n,V_noise)
%This is an VCM-based split SAR ADC architecture with monolithic switching procedure, and redundant design to tolerate the decision error.

A=zeros(1,N);
Vbp_new=Vcm*ones(1,N+1);%initial Voltage on the bottom plate of split vcm cap
Vbn_new=Vcm*ones(1,N+1);
x=Vcm*ones(1,N+1);
Vtp_new=Vinp;%Voltage on the top plate of split vcm cap
Vtn_new=Vinn;
Q_total_p=(Vinp-Vcm)*C_tot;
Q_total_n=(Vinn-Vcm)*C_tot;
C1p=3*C_tot;
C2p=3*C_tot;
C1n=3*C_tot;
C2n=3*C_tot;
Vresp=0;
Vresn=0;

for i=1:N
    
    Vtp=Vtp_new; Vtn=Vtn_new;
    %Vbp=Vbp_new; Vbn=Vbn_new; %refresh
    
    if comparator(Vtp,Vtn,VC1p,VC2p,VC1n,VC2n,V_noise)==1
        A(i)=1;%MSB output
        Vbp_new(1,i)=0;Vbn_new(1,i)=VDD;
    else
        A(i)=0;%MSB output
        Vbp_new(1,i)=VDD;Vbn_new(1,i)=0;
    end
    Vtp_new=((Q_total_p-sum((x-Vbp_new).*C_SAR_weight))/C_tot)+Vcm;
    Vtn_new=((Q_total_n-sum((x-Vbn_new).*C_SAR_weight))/C_tot)+Vcm;


    if i == N
        Vresp = Vtp_new-Vcm;
        Vresn = Vtn_new-Vcm;
        VC1p = Vresp*C_tot/(C_tot+C1p)+VC1p*C1p/(C_tot+C1p);
        VC1n = Vresn*C_tot/(C_tot+C1n)+VC1n*C1n/(C_tot+C1p);
        VC2p = VC1p*C_tot/(C_tot+C2p)+VC2p*C2p/(C_tot+C2p);
        VC2n = VC1n*C_tot/(C_tot+C2n)+VC2n*C2n/(C_tot+C2n);
    end



end

Dout=A;
end
