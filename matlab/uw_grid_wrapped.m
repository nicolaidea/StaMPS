function []=uw_grid_wrapped(ph_in,xy_in,pix_size,prefilt_win,goldfilt_flag,lowfilt_flag,gold_alpha)
%UW_GRID_WRAPPED resample unwrapped phase to a grid and filter
%
%   Andy Hooper, June 2006
%
% ============================================================
% 10/2008 AH: Amended to deal with zero phase values
% 08/2009 AH: Goldstein alpha value added to calling parms
% 02/2012 AH: save ij
% 03/2012 AH: Allow for non-complex wrapped phase
% 01/2013 AH: No gridding option (pix_size=0)
% ============================================================

fprintf('Resampling phase to grid...\n')

if nargin<2
    error('not enough arguments')
end
if nargin<3
    pix_size=200
end
if nargin<4
    prefilt_win=32
end
if nargin<5
    goldfilt_flag='y'
end
if nargin<6
    lowfilt_flag='y'
end
if nargin<7
    gold_alpha=0.8
end

[n_ps,n_ifg]=size(ph_in);

disp(sprintf('   Number of interferograms  : %d',n_ifg))
disp(sprintf('   Number of points per ifg  : %d',n_ps))

if ~isreal(ph_in) & sum(ph_in(:)==0)>0
    error('Some phase values are zero')
end
 
xy_in(:,1)=[1:n_ps]';

if pix_size==0
    grid_x_min=1;
    grid_y_min=1;
    n_i=max(xy_in(:,3));
    n_j=max(xy_in(:,2));
    grid_ij=[xy_in(:,3),xy_in(:,2)];
else
    grid_x_min=min(xy_in(:,2));
    grid_y_min=min(xy_in(:,3));

    grid_ij(:,1)=ceil((xy_in(:,3)-grid_y_min+1e-3)/pix_size);
    grid_ij(grid_ij(:,1)==max(grid_ij(:,1)),1)=max(grid_ij(:,1))-1;
    grid_ij(:,2)=ceil((xy_in(:,2)-grid_x_min+1e-3)/pix_size);
    grid_ij(grid_ij(:,2)==max(grid_ij(:,2)),2)=max(grid_ij(:,2))-1;

    n_i=max(grid_ij(:,1));
    n_j=max(grid_ij(:,2));
end

ph_grid=zeros(n_i,n_j,'single');


for i1=1:n_ifg
    if isreal(ph_in)
        ph_this=exp(1i*ph_in(:,i1));
    else
        ph_this=ph_in(:,i1);
    end 
    ph_grid(:)=0;
    
    if pix_size==0
        ph_grid((xy_in(:,2)-1)*n_i+xy_in(:,3))=ph_this;
    else
        for i=1:n_ps     
            ph_grid(grid_ij(i,1),grid_ij(i,2))=ph_grid(grid_ij(i,1),grid_ij(i,2))+ph_this(i);
        end
    end
  
    if i1==1
        nzix=ph_grid~=0;
        n_ps_grid=sum(nzix(:));
        ph=zeros(n_ps_grid,n_ifg,'single');
        if strcmpi(lowfilt_flag,'y')
            ph_lowpass=ph;
        else
            ph_lowpass=[];
        end
    end
    if strcmpi(goldfilt_flag,'y') | strcmpi(lowfilt_flag,'y')
        [ph_this_gold,ph_this_low]=wrap_filt(ph_grid,prefilt_win,gold_alpha,lowfilt_flag);
        if strcmpi(lowfilt_flag,'y')
            ph_lowpass(:,i)=ph_this_low(nzix);
        end
    end
    if strcmpi(goldfilt_flag,'y')
        ph(:,i1)=ph_this_gold(nzix);
    else
        ph(:,i1)=ph_grid(nzix);
    end

end

n_ps=n_ps_grid;

disp(sprintf('   Number of resampled points: %d',n_ps))

[nz_i,nz_j]=find(ph_grid~=0);
if pix_size==0
    xy=xy_in;
else
    xy=[[1:n_ps]',(nz_j-0.5)*pix_size,(nz_i-0.5)*pix_size];
end
ij=[nz_i,nz_j];






save('uw_grid','ph','ph_in','ph_lowpass','xy','ij','nzix','grid_x_min','grid_y_min','n_i','n_j','n_ifg','n_ps','grid_ij','pix_size')    

