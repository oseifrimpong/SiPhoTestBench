% © Copyright 2013-2015 Shon Schmidt, Jonas Flueckiger, and WenXuan Wu
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU Lesser General Public License as published by
% the Free Software Foundation, version 3 of the License.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU Lesser General Public License for more details.
% 
% You should have received a copy of the GNU Lesser General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.

function [ rtnVal ] = sendEmail(recipients,subject,message, varargin)

% Set email and SMTP server address in MATLAB.
setpref('Internet','E_mail','ubcuwbio@gmail.com');
setpref('Internet','SMTP_Username','ubcuwbio@gmail.com');
setpref('Internet','SMTP_Password','Silicon2012');
setpref('Internet','SMTP_Server','smtp.gmail.com');
props = java.lang.System.getProperties;
props.setProperty('mail.smtp.auth','true');
props.setProperty('mail.smtp.socketFactory.class', 'javax.net.ssl.SSLSocketFactory');
props.setProperty('mail.smtp.socketFactory.port','465');

% require user to specify email address, subject, and body
if isempty(varargin)
    sendmail(recipients,subject,message);    
else
    attachments = varargin{1};
    sendmail(recipients,subject,message,attachments);
end

rtnVal = 1;
end

