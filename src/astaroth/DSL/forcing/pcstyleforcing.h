// PC-style helical forcing with profiles

real3 AC_kk
real3 AC_coef1
real3 AC_coef2
real3 AC_coef3
real3 AC_fda

real AC_phase
real AC_fact

// PC-style helical forcing with support for profiles
forcing(){
    real3 pos = grid_position()
    complex fx = AC_fact * exp(complex(0.0, AC_kk.x * k1_ff * pos.x + AC_phase))
    complex fy = exp(complex(0.0, AC_kk.y * k1_ff * pos.y))
    complex fz

    if (iforcing_zsym == 0) {
        fz = exp(complex(0.0, AC_kk.z * k1_ff * pos.z))
    }
    else if (iforcing_zsym == 1) {
        fz = complex(cos(AC_kk.z * k1_ff * pos.z), 0.0)
    }
    else if (iforcing_zsym == -1) {
        fz = complex(sin(AC_kk.z * k1_ff * pos.z), 0.0)
    }

    complex fxyz = fx * fy * fz

    force_ampl    = profx_ampl[vertexIdx.x - NGHOST] * profy_ampl[vertexIdx.y] * profz_ampl[vertexIdx.z]
    prof_hel_ampl = profx_hel [vertexIdx.x - NGHOST] * profy_hel [vertexIdx.y] * profz_hel [vertexIdx.z]

    return force_ampl * AC_fda * (complex(AC_coef1.x, prof_hel_ampl * AC_coef2.x) * fxyz).x
}
