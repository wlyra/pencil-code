// Generated by Pencil Code build, yet meant to be edited by the user.
// All needed rhs functions are provided, but unneeded ones are not removed.

duu_dt(int step_num){
#include "../hydro/momentum.h"
}

dlnrho_dt(int step_num){
#include "../density/continuity.h"
}

daa_dt(int step_num){
#include "../magnetic/induction.h"
}

//#include "../entropy/heat_cond_const_chi.h"
denergy_dt(int step_num){
#include "../entropy/heat_ss.h"
}

dlnrhon_dt(int step_num){return 0.}

duun_dt(int step_num){return real3(0.,0.,0.)}

dlncc_dt(int step_num){return 0.}

