function [nData,sweepP] = prepareScan(g,scanData)
    %% Prepare for a continous lambda scan
    send(g,'sour0:am:stat 0');         %Turn off the source modulation
    send(g,'sour0:wav:swe:mode CONT'); %Set the sweep mode to continous
    
    %Sets start and stop points for the sweep
    send(g,"sour0:wav:swe:star "+num2str(scanData.starWav*1e9,'%4.1f')+ "nm");
    nData.starWav = str2num(send(g,"sour0:wav:swe:star?"));
    send(g,"sour0:wav:swe:stop "+num2str(scanData.stopWav*1e9,'%4.1f')+ "nm");
    nData.stopWav = str2num(send(g,"sour0:wav:swe:stop?"));
    
    if nData.stopWav >  nData.starWav
        %Query the maximum possible power to run the sweep, and sets the power
        %CHANGE TO USE ACTUAL START AND STOP
        send(g,'sens1:pow:unit dbm'); 
        command = "wav:swe:pmax? "+num2str(scanData.starWav*1e9,'%4.1f')+"nm,"+...
            num2str(scanData.stopWav*1e9,'%4.1f')+"nm";
        fprintf(g,command);pmax = 10*log10(str2num(fscanf(g))*1e3);
        pwr = min(scanData.power,pmax);

        fprintf(g,"sour0:pow "+num2str(pwr,'%2.1f'));
        fprintf(g,"sour0:pow?"); nData.power = num2str(pwr,'%2.4f');

        %Set the sweep step size in nm 
        fprintf(g,"wav:swe:step "+num2str(scanData.step*1e9,'%2.3f')+"nm");     pause(0.1);
        fprintf(g,"wav:swe:step?");nData.step = str2num(fscanf(g));

        %Check for the step frequency to be below 40kHz and uptades the speed
        w = scanData.sweepSpeed/nData.step;
        if w >= 4e4
           error('The speed configuration is higher than allowed for the step size input!') 
           %sws =  4e4*nData.step; %max speed for a sampling frequency of 40kHz
        end
        fprintf(g,"wav:swe:spe? Max"); maxs = str2num(fscanf(g))*1e-9;
        scanData.sweepSpeed = min(scanData.sweepSpeed,maxs);

        %Set the sweep speed
        send(g,"sour0:wav:swe:spe "+num2str(scanData.sweepSpeed*1e9,'%3.2f')+"nm/s");
        nData.sweepSpeed = str2num(send(g,"sour0:wav:swe:spe?"));

        send(g,'wav:swe:cycl 1');
        sweepP.cyc = str2double(send(g,'wav:swe:cycl?'));
        sweepP.trigs = str2double(send(g,'sour0:wav:swe:exp?')); %needs to be below 1e5

        sweepP.time = (nData.stopWav - nData.starWav)/nData.sweepSpeed;
        sweepP.avgTime = sweepP.time/ sweepP.trigs;

        %Setup the sensor logging
        send(g,"sens1:func:par:logg "+num2str(sweepP.trigs)+","+num2str(sweepP.avgTime*1e3/2,'%2.0f')+"ms");
        disp(send(g,"sens1:func:par:logg?"));

        %Start the logging of both nthe sensor and the logg
        send(g,'sens1:func:stat logg,star');    
        send(g,'wav:swe:llog 1');           %Starts the logging of data    

        send(g,'trig0:inp SME'); %%
        send(g,'trig0:conf LOOP'); %%
        send(g,'trig0:outp STF');           %Set the trigger at every  sweep step and Arms module


        sweepP.error = send(g,'sour0:wav:swe:chec?');
        sweepP.stat = ~str2double(sweepP.error(1));
    else
        sweepP.error = '1';
        sweepP.stat = 'The configured sweep is not valid';
    end
 end