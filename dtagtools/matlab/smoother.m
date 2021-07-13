function    y = smoother(x,n)
%
%    y = smoother(x,n)
%     Low pass filter a time series.
%     x is the time series and can be a vector or a matrix with a
%     signal in each column. 
%     n is the smoothing parameter - use a larger number to smooth more.
%        e.g., n=2 filters out frequencies above half of the Nyquist frequency
%        and so halves the bandwidth of the signal.
%
%     Smoother uses a symmetric FIR filter of length 8n. The group delay is
%     removed so that y has no delay with respect to x.
%
%     markjohnson@st-andrews.ac.uk

nf = 8*n ;
fp = 1/(2*n) ;
h = fir1(nf,fp);
noffs = floor(nf/2) ;
if size(x,1)==1,
   x = x(:) ;
end
y = filter(h,1,[x(nf:-1:2,:);x;x(end+(-1:-1:-nf),:)]) ;
y = y(nf+noffs-1+(1:size(x,1)),:);
