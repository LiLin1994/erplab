%  Write erplab at command window for help
%
% Author: Javier Lopez-Calderon & Steven Luck
% Center for Mind and Brain
% University of California, Davis,
% Davis, CA
% 2009

%b8d3721ed219e65100184c6b95db209bb8d3721ed219e65100184c6b95db209b
%
% ERPLAB Toolbox
% Copyright � 2007 The Regents of the University of California
% Created by Javier Lopez-Calderon and Steven Luck
% Center for Mind and Brain, University of California, Davis,
% javlopez@ucdavis.edu, sjluck@ucdavis.edu
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.

function [EEGout conti] = eegchanoperator(EEGin, EEGout, expression)

if nargin<1
      help eegchanoperator
      return
end

conti      = 1;
newlabel   = [];

% add a dot for .*, ./ and .^ operations
expression = regexprep(expression, '([*/^])', '.$1','ignorecase');

% looking for eraser command
[materase] = regexpi(expression, '[n]*ch[an]*\d+\s*=\s*\[\]', 'match');

%
% looking for label
%
[matlabel toklabel]    = regexpi(expression, '\s*label\s*\=*\s*(.*)', 'match', 'tokens');
if ~isempty(toklabel) && ~isempty(EEGin.chanlocs)
      newlabel   = toklabel{:}{1};
      
      %
      % erase label from expression
      %
      expression = strrep(expression, matlabel{:}, '');
      
elseif isempty(toklabel) && ~isempty(EEGin.chanlocs)
      newlabel   = 'no_label';
end

%
% Averaged chans?
%
tokavgchan = regexpi(expression, '\s*avgchan\((.*)?\)', 'tokens','ignorecase');

if ~isempty(tokavgchan)
      chavgop    = tokavgchan{1}{1};
      chavgop    = regexprep(chavgop,'[n]*ch[an]*','','ignorecase');
      chavgop    = regexprep(chavgop,',',' ');
      chavgop    = regexprep(chavgop,'\s*:\s*',':');
      rewroteop  = ['avgchan(EEGin, [' chavgop '])'];
      expression = regexprep(expression,'avgchan(.*)', rewroteop, 'ignorecase');
end

%
% Interpolated chan?
%
tokinter = regexpi(expression, '=\s*(chinterpol)\s*', 'tokens');

if isempty(tokinter)
      ischinterpol = 0;
else
      ischinterpol = 1;     
end

if isempty(materase)
      
      % looking for ":"
      matint = regexpi(expression, ':ch[an]*', 'match');
      
      if ~isempty(matint)
            error('ERPLAB: Interval of channels are allowed only for deleting process. Example, ch23:ch30=[]')
      end
      
      %
      % looking for the channel indices
      %
      [mat tok] = regexpi(expression, '[n]*ch[an]*(\d+)', 'match', 'tokens');
      
      if isempty(mat) %&& isavgchan == 0
            
            %
            % ONLY for variable setting (no chans)  ---> send to workspace
            %
            
            %
            % Matlab 7.3 and higher %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %
            [expspliter formulasp] = regexp(strtrim(expression), '=','match','split');
            leftsize  =   formulasp{1};
            
            [mater tok2]  = regexpi(leftsize, '(\w+)', 'match', 'tokens');
            
            if isempty(mater)
                  error(['ERPLAB says: eegchanoperator found an error at formula ' expression])
            end
            
            %
            % Sends to workspace your channel definition
            %
            eval(expression)
            
            for j=1:length(mater)
                  outvar = char(tok2{j});
                  assignin('base', outvar, eval(outvar));
            end
            
            conti = 1;
            return
      end
      
      nindices  = size(tok,2);
      
      if nindices==0
            msgboxText= 'Channel indices were not found.';
            title = 'ERPLAB: eegchanoperator() error:';
            errorfound(msgboxText, title);
            conti = 0;
            return
      end
      
      chanpos     = zeros(1,nindices);
      realchanpos = chanpos;
      tf = zeros(1,nindices);
      
      for tk=1:nindices
            
            %
            % indices of channels at the formula
            %
            chanpos(tk) = str2num(tok{1,tk}{1,1});
            
            if tk>1
                  [tf(tk) realchanpos(tk)] = ismember(chanpos(tk), 1:EEGin.nbchan);
            else
                  [tf(1) realchanpos(1)] = ismember(chanpos(1), 1:EEGout.nbchan);
            end
      end
      
      %
      % Check right side
      %
      nonexistingchanpos = find([realchanpos(2:end)]==0);
      
      if ~isempty(nonexistingchanpos)
            msgboxText{1} =  ['Channel(s) [' num2str(chanpos(nonexistingchanpos+1)) '] does not exist!!!'];
            msgboxText{2} =  'Only use channels from the list on the right';
            title = 'ERPLAB: eegchanoperator() error:';
            errorfound(msgboxText, title)
            conti = 0; % No more bin processing...
            return
      end
      
      %
      % Keep label (temporary solution...)
      %
      if length(realchanpos(2:end))==1 && strcmp(newlabel, 'no_label')
            newlabel = EEGin.chanlocs(realchanpos(2)).labels;
      end
      
      newchan = chanpos(1);  %this is the formula's left side channel index.
      eraser  = 0;
            
      %
      % Interpolated chan?
      %
      if ischinterpol
            if newchan<=EEGin.nbchan
                  if isfield(EEGin.chanlocs,'theta')
                        EEGout = chinterpol(EEGin, newchan);  
                        
                        if ~isempty(newlabel)
                              if ~strcmpi(newlabel,'no_label')
                                    EEGout.chanlocs(newchan).labels = newlabel;
                              end
                        end
                  else
                        msgboxText=  'Channel location info was not found!';
                        title = 'ERPLAB: eegchanoperator() interpolation error:';
                        errorfound(msgboxText, title);
                        conti = 0;
                  end
            else
                  msgboxText=  'You cannot interpolate an unexisting channel!';
                  title = 'ERPLAB: eegchanoperator() interpolation error:';
                  errorfound(msgboxText, title);
                  conti = 0;
            end
            return
      end
      
else
      %
      % Test nchan sintax (for erasing!?)
      %
      [nchanerase] = regexpi(expression, 'nch[an]*', 'match');
      
      if ~isempty(nchanerase)
            msgboxText=  'You cannot delete a channel using "nchan" sintax';
            title = 'ERPLAB: eegchanoperator() error:';
            errorfound(msgboxText, title);
            conti = 0;
            return
      end
      if ischinterpol
            msgboxText=  'Sorry. Channel interoplation is not yet available for this mode.';
            title = 'ERPLAB: eegchanoperator() error:';
            errorfound(msgboxText, title);
            conti = 0;
            return
      end      
      
      %
      % look for channel index(ices)
      %
      [mat tok] = regexpi(expression, 'ch[an]*(\d+)', 'match', 'tokens'); % looking for channel index
      nindices = size(tok,2);
      
      if nindices>2
            error('ERPLAB: Interval of channels are described by only two elements. Example, ch23:ch30')
      end
      
      chanpos = zeros(1,nindices);
      
      for tk=1:nindices
            chanpos(tk) = str2double(tok{1,tk}{1,1});  % conteins index of channels in the formula
            [tf realchanpos(tk)] = ismember(chanpos(tk), 1:EEGin.nbchan); %#ok<AGROW>
            
            if ~tf(tk)
                  msgboxText=  ['Channel ' num2str(chanpos(tk)) ' does not  exist yet!'];
                  title = 'ERPLAB: eegchanoperator() error:';
                  errorfound(msgboxText, title)
                  conti = 0;
                  return
            end
      end
      
      if tk>1
            newchan = chanpos(1):chanpos(2);
      else
            newchan = chanpos(1);
      end
      
      eraser = 1;
end

%
%  Test New Channel
%
lastslot = EEGout.nbchan;

if isempty(lastslot)
      lastslot= 0;
end

if tf(1) && newchan(1)>=1
      
      if ~eraser
            
            %
            % Gui memory
            %
            wchmsgon = erpworkingmemory('wchmsgon');
            
            if isempty(wchmsgon)
                  wchmsgon = 1;
                  erpworkingmemory('wchmsgon',1);
            end
            
            if wchmsgon==0
                  button = 'yes';
            else
                  question{1} = ['Channel ' num2str(newchan) ' already exist!'];
                  question{2} = 'Would you like to overwrite it?';
                  title      = 'ERPLAB: Overwriting Channel Confirmation';
                  button      = askquest(question, title);
            end
            
            if strcmpi(newlabel,'no_label')
                  newlabel = EEGin.chanlocs(newchan).labels; % keep the original label
            end
      else
            question{1} = ['Channel ' num2str(newchan) ' will be erased!'];
            question{2} = 'Are you completely sure about this?';
            title      = 'ERPLAB: Channel Erasing Confirmation';
            button      = askquest(question, title);
      end
      
      if strcmpi(button,'no')
            confirma = 0;
            conti = 0;
            disp(['Channel ' num2str(newchan) ' was not modified'])
            
      elseif strcmpi(button,'yes')
            confirma = 1;
            fprintf(['\nWARNING: Channel ' num2str(newchan) ' was overwritten.\n\n'])
      else
            disp('User selected Cancel')
            conti = 0;
            return
      end
      
elseif (~tf(1) && newchan(1)>=1 && newchan(1) <= lastslot+1)
      
      confirma = 1;  % Everything is ok!
      realchanpos(1) = lastslot+1;
else
      msgboxText{1} =  ['Error: Channel ' num2str(newchan) ' is out of order!'];
      msgboxText{2} =  '';
      msgboxText{3} =  '"chan" equations must be define in ascending order.';
      msgboxText{4} =  '"nchan" equations must be define in ascending order, from 1 to the highest channel.';
      title = 'ERPLAB: eegchanoperator:';
      errorfound(msgboxText, title)
      conti = 0; % No more bin processing...
      return
end

if confirma
      
      try
            newexp = regexprep(expression, '[n]*ch[an]*(\d+)', 'chan(@$1)','ignorecase');
            
            for p = 1:nindices
                  newexp = regexprep(newexp, '@\d+', num2str(realchanpos(p)),'ignorecase','once');
            end
            
            if ~eraser
                  
                  ntrial = EEGin.trials;
                  
                  newexp = regexprep(newexp, '[n]*chan\((\d+)\)', 'EEGin.data($1,:, 1:ntrial)','ignorecase');
                  newexp = regexprep(newexp, 'EEGin\.data\((.*)?\)\s*=', 'EEGout.data($1) = ','ignorecase');
                  
                  %
                  % Evaluate final expression
                  %
                  eval([newexp ';']);
                  
                  %
                  % New Label
                  %
                  if ~isempty(newlabel)
                        EEGout.chanlocs(realchanpos(1)).labels = newlabel;
                  end
                  
                  EEGout.nbchan = size(EEGout.data, 1);
                  EEGout = eeg_checkset( EEGout );
                  disp(['Channel ' num2str(newchan) ' was  created'])
                  EEGout = update_rejEfields(EEGout);  % update rej fields
            else
                  EEGout = pop_select( EEGin, 'nochannel', newchan );
                  EEGout.nbchan = size(EEGout.data, 1);
                  disp(['Channel ' num2str(newchan) ' was  erased'])
            end
      catch
            
            serr = lasterror;
            msgboxText{1} =  'Please, check your formula: ';
            msgboxText{2} =  expression;
            msgboxText{3} =  serr.message;
            title = 'ERPLAB: eegchanoperator() error:';
            errorfound(msgboxText, title)
            conti = 0;
            return
      end
end
