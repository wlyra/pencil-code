// Get divergence of velocity.
divu_shock()
{
    // con_bias in (0,1) 0 discards values which do not contain negative divergence
    // 1 absolute divergence applies
    // <1 divergence used with reduced factor con_bias**shock_div_pow 
    dt_div_pow = pow(dtfactor,shock_div_pow-1)
    divu = divergence(UU)
    tmp = max(-divu, con_bias*divu)
    return dt_div_pow * pow(tmp,shock_div_pow)
}
