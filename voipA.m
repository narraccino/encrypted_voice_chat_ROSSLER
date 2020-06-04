clear all;
k = [ -3.3712 ; - 0.9561 ; 4.3000 ; -5.8126 ];
t = 0:0.000125:1;
[t0,x0] = ode45('rosslerA',t,[1;2;3;4]);
c1 = textread('rosslerA.m','%s','delimiter','\n');
x1 = find(~cellfun(@isempty,strfind(c1,'dx(3)')));
fid1 = fopen('rosslerA.m','r');
C1 = textscan(fid1, '%s', 'delimiter', '\n');
g = C1{1}{x1};
fclose(fid1);

% Initialize several configuration parameters.
useMicrophone   = true;
IP_address      = '169.254.6.172';
IP_port         = 30000;
sampleRate      = 8000;
nChannels       = 1;
freq            = [100 99];
samplesPerFrame = 1024;

socket = tcpip(IP_address, 1200, 'NetworkRole', 'server');
set(socket, 'InputBufferSize', 320000);
set(socket, 'OutputBufferSize', 320000);
fopen(socket);
fprintf(socket, '%s', g);
fclose(socket);

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