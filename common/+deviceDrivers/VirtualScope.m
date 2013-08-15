% VirtualScope aggregates several scopes into one object that appears to contain
% all the channels of the child scopes

classdef VirtualScope < lib.deviceDriverBase

	properties
		timeOut = 10 % in seconds
		numChannels
		scopes = {}
		wfms = {}
		ts = {}
		listeners = {}
		ready = [] % vector to store whether each individual scope has new data
	end

	events
		DataReady
	end

	methods
		function VirtualScope(varargin)
			% Usage: VirtualScope(scope1, scope2, ...)
			% where each "scope" object is a object supporting a digitizer interface
			for ct = 1:nargin
				scopes{ct} = varargin{ct}
			end
			% for now, assume number of channnels is twice the number of child scopes
			obj.numChannels = 2*length(scopes);
			obj.ready = zeros(length(scopes), 1);
		end

		% dummy stubs required by all instruments
		function connect(obj, address)
		end

		function disconnect(obj)
		end

		function acquire(obj)
			c = onCleanup(@() obj.cleanUp());
			% listen to 'DataReady' signal from child scopes
			for ct = 1:length(scopes)
				obj.listeners{ct} = addlistener(obj.scopes{ct}, 'DataReady', @obj.process_data_ready);
			end

			obj.ready(:) = 0;

			cellfun(@(scope) acquire(scope), obj.scopes);
		end

		function process_data_ready(obj, src, ~)
			idx = find(src == obj.scopes, 1);
			obj.ready(idx) = 1;
			[obj.wfms{2*idx-1}, obj.ts{2*idx-1}] = src.transfer_waveform(1);
			[obj.wfms{2*idx}, obj.ts{2*idx}] = src.transfer_waveform(2);
			if all(obj.ready == 1)
				notify('DataReady');
				obj.ready(:) = 0;
			end
		end

		function status = wait_for_acquisition(obj, timeOut)
			status = 0;
			if ~exist('timeOut','var')
				timeOut = obj.timeOut;
			end

			% from IBM:
			bufferct = 0;
			totNumBuffers = round(obj.scopes{1}.settings.averager.nbrRoundRobins/obj.scopes{1}.buffers.roundRobinsPerBuffer);
			
			for n = 1:length(obj.scopes)
				if strcmp(obj.scopes{n}.acquireMode, 'averager')
					sumDataA{n} = zeros([obj.scopes{n}.settings.averager.recordLength, obj.scopes{n}.settings.averager.nbrSegments]);
					sumDataB{n} = zeros([obj.scopes{n}.settings.averager.recordLength, obj.scopes{n}.settings.averager.nbrSegments]);
				end
			end
			
			while bufferct < totNumBuffers
				
				%Move to the next buffer
				bufferNum = mod(bufferct, obj.scopes{1}.buffers.numBuffers) + 1;
				for n = 1:length(obj.scopes)
					
					obj.scopes{n}.download_buffer(timeOut,bufferNum);
					
					if strcmp(obj.scopes{n}.acquireMode, 'averager')
						sumDataA{n} = sumDataA{n} + obj.scopes{n}.data{1};
						sumDataB{n} = sumDataB{n} + obj.scopes{n}.data{2};
					end
					notify(obj.scopes{n}, 'DataReady');
					obj.scopes{n}.clear_buffer(bufferNum);
					
				end
				%Increment the buffer ct and see if it was the last one
				bufferct = bufferct+1;
				
			end
			for n = 1:length(obj.scopes)                
				if strcmp( obj.scopes{n}.acquireMode, 'averager')
					%Average the summed data
					obj.scopes{n}.data{1} = sumDataA{n}/totNumBuffers;
					obj.scopes{n}.data{2} = sumDataB{n}/totNumBuffers;
				end
				obj.scopes{n}.cleanup_buffers();
			end
		end

		function [wfm, t] = transfer_waveform(obj, ch)
			channelIdx = mod(ch-1, 2) + 1;
			scopeIdx = floor((ch-1)/2) + 1;
			[wfm, t] = obj.scopes{scopeIdx}.transfer_waveform(channelIdx);
		end

		function cleanUp(obj)
			cellfun(@delete, obj.listeners);
		end

	end

end