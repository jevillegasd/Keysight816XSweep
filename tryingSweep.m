    scanData.output = 0;            % 0 = HighPower (Laser Output Port 2), 1 = LowSSE (Laser Output Port 1)                   
    scanData.power = 5;             % Power in dBm (0dBm = 1mW)  
    scanData.starWav =  1600*1e-9;  % start wavelength in m
    scanData.stopWav =  1601*1e-9;  % stop wavelength in m
    scanData.step =     1*1e-9;  % Stepsize in meters
    scanData.sweepSpeed = 5*1e-9;  % Sweep speed in m/s
    scanData.range = -10;           % Range in dBm in steps of 10, between [-70 and 40];
    
    g = gpib('keysight',32,1);
    fopen(g);    
    
    flushinput(g)
    
    %% Unlock laser
    lockStat = str2double(send(g,'lock?'));
    if lockStat, send(g,'lock 0,1234');end
    
    %% Prepare scan
    [nData,sweepP] = prepareScan(g,scanData);
    
    %% Run Scan
    if sweepP.stat 
        send(g,"outp0 1");
        send(g,'sour0:wav:swe 1');                %Runs the sweep    
    end

    %% Wait for sweep to finish
    sweeping = 1;
    logging = str2num(send(g,'sour0:wav:swe:llog?'));
    while sweeping
        sweeping = str2num(send(g,'sour0:wav:swe?'));
    end
    
    %% Turn off laser
    send(g,"outp0 0");
    if lockStat, send(g,'lock 1,1234');end
    
    %% Read Scan Data
    fprintf(g,'sour0:read:poin? llog');wavpoints = str2double(fscanf(g));

    buffSize = g.InputBufferSize;
    precision = 64;
    vpb = buffSize/precision;
    ti = ceil(wavpoints/vpb);
    
    send(g,'sour0:read:data? llog');
    values =[];
    for i = 1:ti
        values = [values;fread(g,vpb,'double')];
    end
    
    
    
    