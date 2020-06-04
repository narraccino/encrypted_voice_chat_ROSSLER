clear all;
k = [ -3.3712 ; - 0.9561 ; 4.3000 ; -5.8126 ];

% Initialize several configuration parameters.
useMicrophone   = true;
IP_address      = '169.254.246.76';
IP_port         = 30000;
sampleRate      = 8000;
nChannels       = 1;
freq            = [100 99];
samplesPerFrame = 1024;

socket = tcpip(IP_address, 1200, 'NetworkRole', 'client');
set(socket, 'InputBufferSize', 100);
set(socket, 'OutputBufferSize', 100);
fopen(socket);
g = fscanf(socket, '%s');
fclose(socket);

c2 = textread('rosslerB.m','%s','delimiter','\n');
x2 = find(~cellfun(@isempty,strfind(c2,'dx(3)')));
fid2 = fopen('rosslerB.m','r');
C2 = textscan(fid2, '%s', 'delimiter', '\n');
C2{1}{x2} = g;
fclose(fid2);

fid2 = fopen('rosslerB.m','w');
[rows,cols]=size(c2);
for row = 1:rows
    fprintf(fid2,'%s',C2{1}{row});
    fprintf(fid2,'\n');
end
fclose(fid2);
t = 0:0.000125:1;
[t0,x0] = ode45('rosslerB',t,[1;2;3;4]);

% Create System objects to send local information to a remote client.
if useMicrophone
    % NOTE: audioDeviceReader requires an Audio System Toolbox (TM) license
    hLocalSource = audioDeviceReader('SampleRate', sampleRate,...
        'NumChannels', nChannels); %#ok<UNRCH>
else
    hLocalSource = dsp.SineWave('SampleRate', sampleRate,...
        'Frequency', freq(1:nChannels),...
        'SamplesPerFrame', samplesPerFrame);
end
hRemoteSink = dsp.UDPSender('RemoteIPAddress', IP_address, ...
    'RemoteIPPort', IP_port);

% Create System objects to listen to data produced by the remote client.
hRemoteSource = dsp.UDPReceiver('LocalIPPort', IP_port,...
    'MaximumMessageLength', samplesPerFrame,...
    'MessageDataType', 'double');
hLocalSink  = audioDeviceWriter('SampleRate', sampleRate);
fiveSeconds = 1000*sampleRate;
for i=1:(fiveSeconds/samplesPerFrame)
    % Connect the local source to the remote sink.
    % In other words, transmit audio data.
    localData = step(hLocalSource);
    for i = 1 : samplesPerFrame
        outputArray(i)=localData(i)+x0(i,1)*x0(i,3)+x0(2,1:4)*k;
    end
    step(hRemoteSink, outputArray(:));
    
    % Connect the remote source to the local sink
    % In other words, receive audio data.
    
   
    remoteData = step(hRemoteSource);
    if ~isempty(remoteData)
        for i=1:samplesPerFrame
            voiceArray(i)= remoteData(i)-(x0(i,1)*x0(i,3)+x0(2,1:4)*k);
        end
    step(hLocalSink, voiceArray');
    end
end
release(hLocalSource);
release(hLocalSink);
release(hRemoteSource);
release(hRemoteSink);