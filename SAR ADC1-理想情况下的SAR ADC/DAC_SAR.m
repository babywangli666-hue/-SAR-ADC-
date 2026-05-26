function [Vout]=DAC_SAR(Dout,weight_ADC,enob_ADC,Vref)


N=length(weight_ADC);
len=length(Dout);
Vout=zeros(1,len);

  for i=1:1:len
      Vo=0;
       for j=1:1:N
          Vo=Vo+Dout(i,j)*weight_ADC(j); 
       end   
      Vout(i)=Vo;
  end
  Vout=Vout./2^enob_ADC*Vref+0.5*Vref/(2^enob_ADC);
  
end