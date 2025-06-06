;
;  $Id$
;+
; VARCONTENT STRUCTURE DESCRIPTION
;
; variable (string)
;   Human readable name for the variable
;
; idlvar (string)
;   Name of the variable (usually in the IDL global namespace)
;   in which the variables data will be stored
;
; idlinit (string)
;   IDL command to initialise the storage variable ready for
;   reading in from a file
;
; idlvarloc (string)
;   As idlvar but used when two grid sizes are used eg. global mesh
;   and processor mesh (local -> loc). And used in processes such
;   as in rall.pro.  Eg. uses mesh sizes of (mxloc,myloc,mzloc)
;
; idlinitloc (string)
;   Again as idlinit but used when two mesh sizes are required at once.
;   see idlvarloc
;-
function pc_varcontent, datadir=datadir, dim=dim, param=param, par2=run_param, help=help, $
                        run2D=run2D, scalar=scalar, noaux=noaux, quiet=quiet, down=down, single=single, hdf5=hdf5
;
;    /single: enforces single precision of returned data.
;      /down: data read from downsampled snapshot.
;
COMPILE_OPT IDL2,HIDDEN
;
if (keyword_set(help)) then begin
  doc_library, 'pc_varcontent'
  return, 0
endif
;
;  Read grid dimensions, input parameters and location of datadir.
;
datadir = pc_get_datadir(datadir)
default, down, 0
if not is_defined(dim) then pc_read_dim, obj=dim, datadir=datadir, quiet=quiet, down=down
if not is_defined(param) then pc_read_param, obj=param, datadir=datadir, dim=dim, quiet=quiet
if not is_defined(run_param) then pc_read_param, obj=run_param, /param2, datadir=datadir, dim=dim, quiet=quiet
default, noaux, 0
default, hdf5, 0
default, single, 0
;
;  Read the positions of variables in the f-array from the index file.
;
indices_file = datadir+'/index.pro'
num_lines = file_lines (indices_file)
index_pro = strarr (num_lines)
openr, lun, indices_file, /get_lun
readf, lun, index_pro
close, lun
free_lun, lun

; Read in and make accessible all 'nXXX' variables.
default, ntestfield, 0
default, ntestflow, 0
default, ntestscalar, 0
default, ntestlnrho, 0
default, n_np_ap, 0

found = 0
for line = 0, num_lines-1 do begin
  cmd = stregex (index_pro[line], '^ *n[^= ]+ *= *[0-9]+ *$', /extract)
  if (not execute (cmd)) then $
      message, 'pc_varcontent: there was a problem with "'+indices_file+'" at line '+str (line+1)+'.', /info
  inactive = stregex (index_pro[line], '^ *[^= ]+ *= *(0+|- *1) *$', /extract)
  if (inactive) then index_pro[line] = ""
  if ((line ge 2) and (index_pro[line] ne '')) then begin
    ; Check for (and remove) double entries
    for against = 0, line-2 do begin
      if (index_pro[against] eq '') then continue
      if (index_pro[against] eq index_pro[line]) then begin
        if (found eq 0) then message, "HINT: some module used 'farray_register_*' and 'farray_index_append', twice, where the latter call should be removed!", /info
        message, 'the offending line in "data/index.pro" is: '+index_pro[line], /info
        index_pro[line] = ''
        found++
      end
    end
  end
endfor

mvar=dim.mvar & maux=dim.maux
;
;  For EVERY POSSIBLE variable in a snapshot file, store a
;  description of the variable in an indexed array of structures
;  where the indexes line up with those in the saved f array.
;
;  Note: Integrated variables and variables which can be both integrated and auxiliary *must* be included here.
;        Auxiliary variables should go to the table below the following one, but work also here.
;
indices = [ $
  { name:'iuu', label:'Velocity', dims:3 }, $
  { name:'iadv_der_uu', label:'Advective acceleration as auxiliary variable', dims:3}, $
  { name:'ipp', label:'Pressure', dims:1 }, $
  { name:'ippp', label:'Pressure as auxiliary variable', dims:1 }, $
  { name:'iss', label:'Entropy', dims:1 }, $
  { name:'icp', label:'Specific heat as auxiliary variable', dims:1 }, $
  { name:'icv', label:'Specific heat as auxiliary variable', dims:1 }, $
  { name:'igamma', label:'Ratio of specific heat as auxiliary variable', dims:1 }, $
  { name:'inabad', label:'nabla adiabatic as auxiliary variable', dims:1 }, $
  { name:'idelta', label:'delta as auxiliary variable', dims:1 }, $
  { name:'iviscosity', label:'viscosity as auxiliary variable', dims:1 }, $
  { name:'ics', label:'Sound speed as auxiliary variable', dims:1 }, $
  { name:'ivarphi', label:'Bernoulli', dims:1 }, $
  { name:'ilnrho', label:'Log density', dims:1 }, $
  { name:'iGamma', label:'Constraint Gamma', dims:1 }, $
  { name:'irhoe', label:'Charge density', dims:1 }, $
  { name:'irho', label:'Density', dims:1 }, $
  { name:'irho_b', label:'Base density', dims:1 }, $
  { name:'irhs', label:'RHS', dims:3 }, $
  { name:'iss_b', label:'Base Entropy', dims:1 }, $
  { name:'iaa', label:'Magnetic vector potential', dims:3 }, $
  { name:'ia0', label:'Electric potential for Lorenz gauge', dims:1 }, $
  { name:'iinfl_phi', label:'Inflaton phi', dims:1 }, $
  { name:'iinfl_dphi', label:'Inflaton time derivative dphi', dims:1 }, $
  { name:'iinfl_hubble', label:'Comoving Hubble parameter', dims:1 }, $
  { name:'iinfl_lna', label:'Logarithmic scale factor', dims:1 }, $
  { name:'iispecial1', label:'special1', dims:1 }, $
  { name:'iispecial2', label:'special2', dims:1 }, $
  { name:'isigE', label:'sigE', dims:1 }, $
  { name:'isigB', label:'sigB', dims:1 }, $
  { name:'iaphi', label:'A_phi', dims:1 }, $
  { name:'ibphi', label:'B_phi', dims:1 }, $
  { name:'ibb', label:'Magnetic field', dims:3 }, $
  { name:'ijj', label:'Current density', dims:3 }, $
  { name:'iee', label:'Electric field', dims:3 }, $
  { name:'ie', label:'Electric field', dims:3 }, $
  { name:'iemf', label:'Electromotive force', dims:3 }, $
  { name:'iaak', label:'Real part of vector potential', dims:3 }, $
  { name:'iaakim', label:'Imaginary part of vector potential', dims:3 }, $
  { name:'ieek', label:'Real part of electric field', dims:3 }, $
  { name:'ieekim', label:'Imaginary part of electric field', dims:3 }, $
 ;
  { name:'ikappar', label:'kappar', dims:1 }, $
  { name:'itau', label:'tau', dims:1 }, $
  { name:'iggT', label:'ggT', dims:1 }, $
  { name:'iggX', label:'ggX', dims:1 }, $
  { name:'ihhT', label:'hhT', dims:1 }, $
  { name:'ihhX', label:'hhX', dims:1 }, $
  { name:'iggTim', label:'ggTim', dims:1 }, $
  { name:'iggXim', label:'ggXim', dims:1 }, $
  { name:'ihhTim', label:'hhTim', dims:1 }, $
  { name:'ihhXim', label:'hhXim', dims:1 }, $
  { name:'iggT_boost', label:'ggT_boost', dims:1 }, $
  { name:'iggX_boost', label:'ggX_boost', dims:1 }, $
  { name:'ihhT_boost', label:'hhT_boost', dims:1 }, $
  { name:'ihhX_boost', label:'hhX_boost', dims:1 }, $
  { name:'iggTim_boost', label:'ggTim_boost', dims:1 }, $
  { name:'iggXim_boost', label:'ggXim_boost', dims:1 }, $
  { name:'ihhTim_boost', label:'hhTim_boost', dims:1 }, $
  { name:'ihhXim_boost', label:'hhXim_boost', dims:1 }, $
  { name:'ih11_realspace', label:'h11_realspace', dims:1 }, $
  { name:'ih22_realspace', label:'h22_realspace', dims:1 }, $
  { name:'ih33_realspace', label:'h33_realspace', dims:1 }, $
  { name:'ih12_realspace', label:'h12_realspace', dims:1 }, $
  { name:'ih23_realspace', label:'h23_realspace', dims:1 }, $
  { name:'ih31_realspace', label:'h31_realspace', dims:1 }, $
  { name:'ihij', label:'hij', dims:6 }, $
  { name:'igij', label:'gij', dims:6 }, $
  { name:'irrr', label:'Collapse radius', dims:1 }, $
  { name:'ibet', label:'Collapse speed', dims:1 }, $
  { name:'ip11', label:'Polymer Tensor 11', dims:1 }, $
  { name:'ip12', label:'Polymer Tensor 12', dims:1 }, $
  { name:'ip13', label:'Polymer Tensor 13', dims:1 }, $
  { name:'ip22', label:'Polymer Tensor 22', dims:1 }, $
  { name:'ip23', label:'Polymer Tensor 23', dims:1 }, $
  { name:'ip33', label:'Polymer Tensor 33', dims:1 }, $
  { name:'iuut', label:'Integrated velocity', dims:3 }, $
  { name:'iaatest', label:'Testmethod vector potential', dims:ntestfield }, $
  { name:'iuutest', label:'Testmethod velocity', dims:ntestflow }, $
  { name:'icctest', label:'Testmethod scalar', dims:ntestscalar }, $
  { name:'ilnrhotest', label:'Testmethod log(rho)', dims:ntestlnrho }, $
; { name:'ivv', label:'velocity when conservative', dims:3 }, $
  { name:'ivx', label:'x-velocity when conservative', dims:1 }, $
  { name:'ivy', label:'y-velocity when conservative', dims:1 }, $
  { name:'ivz', label:'z-velocity when conservative', dims:1 }, $
  { name:'iox', label:'x-velocity when conservative', dims:1 }, $
  { name:'ioy', label:'y-velocity when conservative', dims:1 }, $
  { name:'ioz', label:'z-velocity when conservative', dims:1 }, $
  { name:'iuun', label:'Velocity of neutrals', dims:3 }, $
  { name:'ispitzer', label:'Heat flux vector according to Spitzer', dims:3 }, $
  { name:'iqq', label:'heatflux vector', dims:3 }, $
  { name:'ilnrhon', label:'Log density of neutrals', dims:1 }, $
  { name:'ifx', label:'Radiation vector', dims:3 }, $
 ;{ name:'ie', label:'Radiation scalar', dims:1 }, $
  { name:'icc', label:'Passive scalar', dims:1 }, $
  { name:'ilncc', label:'Log passive scalar', dims:1 }, $
  { name:'iacc', label:'Active Scalar', dims:1 }, $
  { name:'iXX_chiral', label:'XX chiral', dims:1 }, $
  { name:'iYY_chiral', label:'YY chiral', dims:1 }, $
  { name:'iZZ_chiral', label:'ZZ chiral', dims:1 }, $
  { name:'iXX2_chiral', label:'XX2 chiral', dims:1 }, $
  { name:'iYY2_chiral', label:'YY2 chiral', dims:1 }, $
  { name:'ispecial', label:'Special', dims:1 }, $
  { name:'ispec_3vec', label:'Special vector', dims:3 }, $
  { name:'ilorentz', label:'Lorentz factor', dims:1 }, $
  { name:'ihless', label:'Higgsless field', dims:1 }, $
  { name:'iphi', label:'Electric potential', dims:1 }, $
  { name:'iLam', label:'Gauge potential', dims:1 }, $
  { name:'idiva', label:'divA', dims:1 }, $
  { name:'iecr', label:'Cosmic ray energy density', dims:1 }, $
  { name:'ifcr', label:'Cosmic ray energy flux', dims:3 }, $
  { name:'igtheta5', label:'Chemical potential gradient', dims:3 }, $
  { name:'itheta5', label:'Chemical potential', dims:1 }, $
  { name:'imuS', label:'Chemical potential', dims:1 }, $
  { name:'imu5', label:'Chiral chemical potential', dims:1 }, $
  { name:'iam', label:'Meanfield dynamo', dims:3 }, $
  { name:'ipsi_real', label:'Wave function real part', dims:1 }, $
  { name:'ipsi_imag', label:'Wave function imaginary part', dims:1 }, $
  { name:'iaxi_Q', label:'axi_Q', dims:1 }, $
  { name:'iaxi_Qdot', label:'axi_Qdot', dims:1 }, $
  { name:'iaxi_chi', label:'axi_chi', dims:1 }, $
  { name:'iaxi_chidot', label:'axi_chidot', dims:1 }, $
  { name:'iaxi_psi', label:'axi_psi', dims:1 }, $
  { name:'iaxi_psiL', label:'axi_psiL', dims:1 }, $
  { name:'iaxi_psidot', label:'axi_psidot', dims:1 }, $
  { name:'iaxi_psiLdot', label:'axi_psiLdot', dims:1 }, $
  { name:'iaxi_impsi', label:'axi_impsi', dims:1 }, $
  { name:'iaxi_impsiL', label:'axi_impsiL', dims:1 }, $
  { name:'iaxi_impsidot', label:'axi_impsidot', dims:1 }, $
  { name:'iaxi_impsiLdot', label:'axi_impsiLdot', dims:1 }, $
  { name:'iaxi_TR', label:'axi_TR', dims:1 }, $
  { name:'iaxi_TL', label:'axi_TL', dims:1 }, $
  { name:'iaxi_imTR', label:'axi_imTR', dims:1 }, $
  { name:'iaxi_imTL', label:'axi_imTL', dims:1 }, $
  { name:'iaxi_TRdot', label:'axi_imTRdot', dims:1 }, $
  { name:'iaxi_TLdot', label:'axi_imTLdot', dims:1 }, $
  { name:'iaxi_imTRdot', label:'axi_TRdot', dims:1 }, $
  { name:'iaxi_imTLdot', label:'axi_TLdot', dims:1 }, $
  { name:'ialpm', label:'alpm', dims:1 }, $
  { name:'ietat', label:'etat', dims:1 }, $
  { name:'ieta', label:'Dust resistivity', dims:1 }, $
  { name:'izeta', label:'Ionization rate', dims:1 }, $
  { name:'ichemspec', label:'Chemical species mass fraction', dims:1 }, $
  { name:'iuud', label:'Dust velocity', dims:3 }, $
  { name:'ind', label:'Dust number density', dims:1 }, $
  { name:'imd', label:'Dust density', dims:1 }, $
  { name:'imi', label:'Dust mi ?something?', dims:1 }, $
  { name:'ilnTT', label:'Log temperature', dims:1 }, $
  { name:'iTT', label:'Temperature', dims:1 }, $
  { name:'ieth', label:'Thermal energy', dims:1 }, $
  { name:'igpx', label:'Pressure gradient x', dims:1 }, $
  { name:'igpy', label:'Pressure gradient y', dims:1 }, $
  { name:'iRR', label:'Specific gas constant', dims:1 }, $
  { name:'iss_run_aver', label:'Running mean of entropy', dims:1 } $
  ; don't forget to add a comma above when extending
]

indices_shortcut = [ $
; { name:'iStr', replace:'iStr' }, $
  { name:'iuu', replace:'iu' }, $
  { name:'iaa', replace:'ia' }, $
  { name:'ibb', replace:'ib' }, $
  { name:'iee', replace:'ie' }, $
  { name:'ijj', replace:'ij' }, $
  { name:'iaak', replace:'iak' }, $
  { name:'ieek', replace:'iek' }, $
  { name:'iaakim', replace:'iakim' }, $
  { name:'ieekim', replace:'iekim' }, $
  { name:'iqq', replace:'iq' } $
  ; don't forget to add a comma above when extending
]

; Auxiliary variables: (see also explanation above)
indices_aux = [ $
  { name:'iQrad', label:'Radiative heating rate', dims:1 }, $
  { name:'ikapparho', label:'Opacity', dims:1 }, $
  { name:'isss', label:'Entropy as auxiliary variable', dims:1 }, $
  { name:'iKR_Frad', label:'Radiative flux scaled with kappa*rho', dims:3 }, $
; { name:'iKR_pres', label:'Radiative pressur scaled with kappa*rho', dims:6 }, $
  { name:'iKR_pres_xx', label:'Radiative pressur scaled with kappa*rho', dims:1 }, $
  { name:'iKR_pres_yy', label:'Radiative pressur scaled with kappa*rho', dims:1 }, $
  { name:'iKR_pres_zz', label:'Radiative pressur scaled with kappa*rho', dims:1 }, $
  { name:'iKR_pres_xy', label:'Radiative pressur scaled with kappa*rho', dims:1 }, $
  { name:'iKR_pres_yz', label:'Radiative pressur scaled with kappa*rho', dims:1 }, $
  { name:'iKR_pres_xz', label:'Radiative pressur scaled with kappa*rho', dims:1 }, $
  { name:'iyH', label:'Hydrogen ionization fraction', dims:1 }, $
  { name:'ishock', label:'Shock profile', dims:1 }, $
  { name:'ishock_perp', label:'B-perpendicular shock profile', dims:1 }, $
  { name:'icooling', label:'ISM cooling term', dims:1 }, $
  { name:'inetheat', label:'Net applied ISM heating term', dims:1 }, $
  { name:'idetonate', label:'Detonation energy', dims:1 }, $
  { name:'inp', label:'Particle number', dims:1 }, $
  { name:'inp_ap', label:'Particle number', dims:1 }, $
  { name:'iphiuu', label:'Potential of curl-free part of velocity field', dims:1 }, $
  { name:'irhop', label:'Particle mass density', dims:1 }, $
  { name:'iuup', label:'Particle velocity field', dims:3 }, $
  { name:'ifgx', label:'Gas terms for stiff drag forces', dims:3 }, $
  { name:'ipviscx', label:'Particle viscosity field', dims:3 }, $
  { name:'ipotself', label:'Self gravity potential', dims:1 }, $
  { name:'igpotselfx', label:'x-der of self gravity potential', dims:1 }, $
  { name:'igpotselfy', label:'y-der of self gravity potential', dims:1 }, $
  { name:'igpotselfz', label:'z-der of self gravity potential', dims:1 }, $
  { name:'ivisc_heat', label:'Viscous dissipation', dims:1 }, $
  { name:'ivisc_forc', label:'Viscous force (acceleration)', dims:3 }, $
  { name:'ihypvis', label:'Hyperviscosity', dims:3 }, $
  { name:'ihypres', label:'Hyperresistivity', dims:3 }, $
  { name:'ihcond', label:'Thermal conductivity', dims:1 }, $
  { name:'iglhc', label:'Gradient of thermal conductivity', dims:3 }, $
  { name:'ippaux', label:'Auxiliary pressure', dims:1 }, $
  { name:'ispecaux', label:'Special auxiliary variable', dims:1 }, $
; { name:'iTij', label:'Tij', dims:6 }, $
  { name:'iTij_xx', label:'iTij_xx', dims:1 }, $
  { name:'iTij_xy', label:'iTij_xx', dims:1 }, $
  { name:'iTij_xz', label:'iTij_xx', dims:1 }, $
  { name:'iTij_yy', label:'iTij_xx', dims:1 }, $
  { name:'iTij_yz', label:'iTij_xx', dims:1 }, $
  { name:'iTij_zz', label:'iTij_xx', dims:1 }, $
  { name:'iTij1', label:'Tij1', dims:1 }, $
  { name:'iTij2', label:'Tij2', dims:1 }, $
  { name:'iTij3', label:'Tij3', dims:1 }, $
  { name:'iTij4', label:'Tij4', dims:1 }, $
  { name:'iTij5', label:'Tij5', dims:1 }, $
  { name:'iTij6', label:'Tij6', dims:1 }, $
; { name:'iStr', label:'Str', dims:6 }, $
  { name:'iSt1', label:'St1', dims:1 }, $
  { name:'iSt2', label:'St2', dims:1 }, $
  { name:'iSt3', label:'St3', dims:1 }, $
  { name:'iSt4', label:'St4', dims:1 }, $
  { name:'iSt5', label:'St5', dims:1 }, $
  { name:'iSt6', label:'St6', dims:1 }, $
  { name:'iStT', label:'StT', dims:1 }, $
  { name:'iStX', label:'StX', dims:1 }, $
;  { name:'iex', label:'ex', dims:1 }, $
;  { name:'iey', label:'ey', dims:1 }, $
;  { name:'iez', label:'ez', dims:1 }, $
;  { name:'ieex', label:'eex', dims:1 }, $
;  { name:'ieey', label:'eey', dims:1 }, $
;  { name:'ieez', label:'eez', dims:1 }, $
  { name:'ieedotx', label:'eedotx', dims:1 }, $
  { name:'ieedoty', label:'eedoty', dims:1 }, $
  { name:'ieedotz', label:'eedotz', dims:1 }, $
  { name:'iStTim', label:'StTim', dims:1 }, $
  { name:'iStXim', label:'StXim', dims:1 }, $
  { name:'ihhT_realspace', label:'ihhT_realspace', dims:1 }, $
  { name:'ihhX_realspace', label:'ihhX_realspace', dims:1 }, $
  { name:'iggT_realspace', label:'iggT_realspace', dims:1 }, $
  { name:'iggX_realspace', label:'iggX_realspace', dims:1 }, $
  { name:'isld_char', label:'SLD characteristic speed', dims:1 }, $
  { name:'ialfven', label:'Alfven speed', dims:1 }, $
  { name:'ipsi', label:'Streamfunction', dims:1 }, $
  { name:'ieee', label:'eee function', dims:1 }, $
  { name:'ibss', label:'bss function', dims:1 }, $
  { name:'ibet', label:'bet function', dims:1 }, $
  { name:'isigma', label:'Column density', dims:1 }, $
  { name:'imdot', label:'Mass accretion rate', dims:1 }, $
  { name:'itmid', label:'Midplane temperature', dims:1 }, $
  { name:'ipotturb', label:'Turbulent potential', dims:1 }, $
  { name:'iff', label:'Forcing function', dims:3 }, $
  { name:'itauascalar', label:'Relaxation time', dims:1 }, $
  { name:'issat', label:'Supersaturation', dims:1 }, $
  { name:'icondensationRate', label:'Condensation rate', dims:1 }, $
  { name:'iwaterMixingRatio', label:'Water mixing ratio', dims:1 }, $
  { name:'inusmag', label:'Smagorinsky viscosity', dims:1 }, $
  { name:'ietasmag', label:'Smagorinsky diffusivity', dims:1 }, $
  { name:'iuxbtest', label:'Testfield EMF', dims:ntestfield }, $
  { name:'ijxbtest', label:'Testfield Lorentz force', dims:ntestfield }, $
  { name:'iugutest', label:'Testflow advective acc.', dims:ntestfield }, $
  { name:'iughtest', label:'Testflow enthalpy advection', dims:ntestfield }, $
  { name:'inucl_rmin', label:'Radius of nucleating particles', dims:1 }, $
  { name:'inucl_rate', label:'Rate of particle nucleation', dims:1 }, $
  { name:'isupersat', label:'Supersaturation', dims:1 } $
  ; don't forget to add a comma above when extending
]
;
; Inconsistent names (IDL-name is inconsistent with name in the main code):
; E.g., in Fortran we use "ifx", but some IDL scrips expect "ff" in varcontent.
; Note: the initial "i" is automatically removed and hence *not* inconsistent.
;
inconsistent = [ $
  { name:'ifx', inconsistent_name:'ff' }, $
  { name:'ichemspec', inconsistent_name:'YY' }, $
  { name:'idetonate', inconsistent_name:'det' }, $
  { name:'ifgx', inconsistent_name:'ffg' }, $
  { name:'ipviscx', inconsistent_name:'pvisc' }, $
  { name:'igpotselfx', inconsistent_name:'gpotself' }, $
  { name:'ihypvis', inconsistent_name:'hyv' }, $
  { name:'ihypres', inconsistent_name:'hyr' }, $
  { name:'ivisc_forc', inconsistent_name:'visc_force' } $
  ; don't forget to add a comma above when extending
]

; Inconsistent names in special modules (see also explanation above):
inconsistent_special = [ $
  { name:'ikappar', inconsistent_name:'kappar' }, $   ; seems not inconsistent
  { name:'ilambda', inconsistent_name:'lambda' }  $   ; seems not inconsistent
  ; don't forget to add a comma above when extending
]

; Special variables:
file_special = datadir+'/index_special.pro'
if (file_test (file_special)) then begin
  openr, lun, file_special, /get_lun
  line = ''
  line_pos = 0
  num_inconsistent = n_elements (inconsistent_special)
  while (not eof (lun)) do begin
    readf, lun, line
    line_pos += 1
    if (not keyword_set (hdf5)) then begin
      ; Backwards-compatibility for old runs with alphadisk, flux_limdiff, streamfunction, or turbpotential.
      for pos = 0, num_inconsistent-1 do begin
        search = inconsistent_special[pos].inconsistent_name
        replace = inconsistent_special[pos].name
        str = stregex (line, '^ *'+search+' *(=.*)$', /extract, /sub)
        if (str[1] ne '') then begin
          line = replace+str[1]
        endif
      endfor
    endif
    ; Parse line with number of components.
    str = stregex (line, '^ *n[^= ]+[= ]+[0-9]+ *$', /extract)
    if (not execute (str)) then $
        message, 'there was a problem with "'+file_special+'" at line '+str (line_pos)+'.', /info
    ; Parse line with "ispecial = ..." or similar.
    str = stregex (line, '^ *(i[^= ]+)[= ]+.*$', /extract, /sub)
    if (str[1] ne '') then begin
      ; Avoid duplicate entries
      if (total (index_pro eq line) ge 1) then begin
        default, search, str[1]
        message, "duplicate entry '"+search+"', please remove it from 'index_special.pro' or 'index.pro'.", /info
        message, "HINT: a module probably registers this variable twice by using 'farray_register_*' and 'farray_index_append', where the latter should be removed!", /info
      endif else begin
        indices = [ indices, { name:str[1], label:'Special', dims:1 } ]
        index_pro = [ index_pro, line ]
      endelse
    endif
  endwhile
  close, lun
  free_lun, lun
endif
;
;  The number of variables in the snapshot file depends on whether we
;  are writing auxiliary data or not. Auxiliary variables can be turned
;  off by hand by setting noaux=1, e.g. for reading derivative snapshots.
;
if (not keyword_set (noaux)) then begin
  if maux gt 0 then $
    if keyword_set(param.lwrite_aux) or down then $
      indices = [ indices, indices_aux ] $
    else if is_defined(run_param) then $
      if  keyword_set(run_param.lwrite_aux) then indices = [ indices, indices_aux ] else maux=0
endif
;
;  Predefine some variable types used regularly.
;
INIT_DATA = [ 'make_array (mx,my,mz,', 'type='+(single ? '4' : 'type_idl')+')' ]
;
;  For 2-D runs with lwrite_2d=T. Data has been written by the code without
;  ghost zones in the missing direction. We add ghost zones here anyway so
;  that the array can be treated exactly like 3-D data.
;
if (keyword_set(run2D)) then begin
  INIT_DATA_LOC = [ 'reform(make_array (dim.nx eq 1 ? 1 : mxloc,dim.ny eq 1 ? 1 : myloc,dim.nz eq 1 ? 1 : mzloc,', 'type=type_idl))' ]
endif else $
  INIT_DATA_LOC = [ 'make_array (mxloc,myloc,mzloc,', 'type=type_idl)' ]
;
;  Parse variables and count total number of variables.
;
num_tags = n_elements (indices)
num_vars = 0

offsetv = down and (mvar eq 0) ? '-pos[0]+1' : ''    ; corrects index for downsampled varfile if no MVAR variables are contained
						     ; as indices in index.pro refer to the varfile not to the downsampled varfile
for tag = 1, num_tags do begin
  original = indices[tag-1].name
  vector = indices[tag-1].dims
; Quick fix to read scalar arrays (e.g. inp_ap1...inp_ap7)
  if (vector eq 7) then begin 
    vector=1
  endif
  ; Identify f-array variables with multiple vectors or components (arrays & arrays of vectors)
  matches = stregex (index_pro, '^ *'+original+'([1-9][0-9]*)[xyz]? *= *(.*) *$', /extract, /sub)
  lines = where (matches[0,*] ne '', num)
  if (num ge 1) then begin
    pos = min (long (matches[2,lines]))
    array = max (long (matches[1,lines]))
    if (num ne vector * array) then begin
      message, 'Dimensions of "'+original+'" do not fit to number of entries in "index.pro"!'
    end
  endif else begin
    array = 0
    ; Translate shortcuts (e.g. iuu => iu[x,y,z])
    search = original
    found = where (search eq indices_shortcut[*].name, num)
    if (num ge 1) then begin
      search = indices_shortcut[found].replace
    ; Identify f-array variables with scalars & vectors (e.g. ilnrho, iu[x,y,z])
      matches = stregex (index_pro, '^ *'+search+'([xyz])? *= *([1-9][0-9]*) *$', /extract, /sub)
    endif else $
      matches = stregex (index_pro, '^ *'+search+'( *)?= *([1-9][0-9]*) *$', /extract, /sub)
    lines = where (matches[0,*] ne '', num)
    
    if (num ge 1) then begin
      pos = min (long (matches[2,lines]))
      if (vector eq 3) then begin
        matches = stregex (index_pro, '^ *'+search+'([xyz]) *= *([1-9][0-9]*) *$', /extract, /sub)
        lines = where (matches[0,*] ne '', num)
      end
      if (num ne vector) then begin
        message, 'Dimensions of "'+original+'" do not fit to number of entries in "index.pro"!'
      end
    endif else begin
      matches = stregex (index_pro, '^ *'+original+'( *)= *(indgen.*)$', /extract, /sub)
      lines = where (matches[0,*] ne '', num)
      if (num lt 1) then  $
        ; Quantity not contained in this run
        continue $
      else begin
        ret=execute('indspos='+matches[2,lines[0]])
        pos = min(indspos)
      endelse
    endelse
  endelse

  if (pos le 0) then continue

  ; Append f-array variable to valid varcontent.
  if (size (selected, /type) eq 0) then begin
    selected = [ tag-1 ]
    position = [ pos ]
    vectors = [ vector ]
    arrays = [ array ]
  end else begin
    selected = [ selected, tag-1 ]
    position = [ position, pos ]
    vectors = [ vectors, vector ]
    arrays = [ arrays, array ]
  end
  num_vars += 1
endfor
;
; Reorder to be ascending w.r.t. position.
;
sorted = sort (position)
selected = selected[sorted]
position = position[sorted]
vectors = vectors[sorted]
arrays = arrays[sorted]
;
; in the *ordered* list of hits
; only the first mvar+maux entries matter
;
totalvars = 0L
for var = 0, num_vars-1 do begin
  totalvars += vectors[var] * (arrays[var] > 1)
  if (totalvars eq mvar+maux) then begin
    selected = selected[0:var]
    num_vars = var + 1
    break
  endif
endfor
;
;  Make an array of structures in which to store their descriptions.
;
varcontent = replicate ({ varcontent_all, variable:'UNKNOWN', idlvar:'dummy', idlinit:'0', $
                          idlvarloc:'dummy_loc', idlinitloc:'0', skip:0 }, totalvars)
;
;  Fill varcontent array.
;
vc_pos = 0
for var = 0, num_vars-1 do begin

  tag = selected[var]
  pos = position[var]
  vector = vectors[var]
  array = arrays[var]
  skip = vector

  name = strmid (indices[tag].name, 1)
  if (not keyword_set (hdf5)) then begin
    ; translate inconsistent names for old binary file format, not for HDF5
    replace = (where (inconsistent[*].name eq indices[tag].name))[0]
    if (replace ge 0) then name = inconsistent[replace].inconsistent_name
  endif

  dim_str = ''
  if (vector gt 1) then dim_str = str (vector)+','

  for component = 1, (array > 1) do begin
    idl_var = name
    if (array ge 1) then idl_var += str (component)
    varcontent[vc_pos].variable = indices[tag].label + ' ('+idl_var+')'
    varcontent[vc_pos].idlvar = idl_var
    varcontent[vc_pos].idlinit = strjoin (INIT_DATA, dim_str)
    varcontent[vc_pos].idlvarloc = idl_var + '_loc'
    varcontent[vc_pos].idlinitloc = strjoin (INIT_DATA_LOC, dim_str)
    varcontent[vc_pos].skip = skip - 1
    vc_pos += skip
  endfor
endfor
;
;  Turn vector quantities into scalars if requested.
;
if (keyword_set(scalar)) then begin
  for i = 0L, totalvars-1L do begin
    if (varcontent[i].skip eq 2) then begin
      varcontent[i+2].variable  = varcontent[i].variable + ' 3rd component'
      varcontent[i+1].variable  = varcontent[i].variable + ' 2nd component'
      varcontent[i  ].variable  = varcontent[i].variable + ' 1st component'
      varcontent[i+2].idlvar    = varcontent[i].idlvar + '3'
      varcontent[i+1].idlvar    = varcontent[i].idlvar + '2'
      varcontent[i  ].idlvar    = varcontent[i].idlvar + '1'
      varcontent[i+2].idlvarloc = varcontent[i].idlvarloc + '3'
      varcontent[i+1].idlvarloc = varcontent[i].idlvarloc + '2'
      varcontent[i  ].idlvarloc = varcontent[i].idlvarloc + '1'
      varcontent[i:i+2].idlinit    = strjoin (INIT_DATA)
      varcontent[i:i+2].idlinitloc = strjoin (INIT_DATA_LOC)
      varcontent[i:i+2].skip       = 0
      i=i+2
    endif
  endfor
endif
;
return, varcontent
;
end
