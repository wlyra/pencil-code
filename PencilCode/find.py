#! /usr/bin/env python3
# Last Modification: $Id$
#=======================================================================
# find.py
#
# Facilities for analyzing the Pencil Code data.
#
# Chao-Chin Yang, 2013-10-21
#=======================================================================
def time_average(datadir='./data', diagnostics=None, tmin=0, verbose=True):
    """Finds the time average of each given diagnostic variable.

    Returned Values:
        The mean and standard deviation of each diagnostics for
        t >= tmin.

    Keyword Arguments:
        datadir
            Name of the data directory.
        diagnostics
            (A list of) diagnostic variable(s).  If None, all
            diagnostics but it and t are processed.
        tmin
            Starting time of the time average.
        verbose
            Directly print out the averages when True.
    """
    # Chao-Chin Yang, 2014-07-31

    # Read the time series.
    from . import read
    ts = read.time_series(datadir=datadir)

    # Check the time span.
    tmax = max(ts.t)
    if tmax <= tmin:
        print("The minimum time has not been reached. ")
        print("  tmax = ", tmax)
        print("  tmin = ", tmin)
        return None
    indices = ts.t >= tmin
    dtinv = 1 / (tmax - tmin)

    # Local function for conducting statistics.
    def stats(diag):
        from scipy import integrate
        from numpy import sqrt
        mean = dtinv * integrate.simps(ts[diag][indices], ts.t[indices])
        stddev = sqrt(dtinv * integrate.simps((ts[diag][indices] - mean)**2, ts.t[indices]))
        if verbose:
            print("<", diag, "> = ", mean, "+/-", stddev)
        return mean, stddev

    # Default diagnostics is all except it and t.
    if diagnostics is None:
        diagnostics = list(ts.dtype.names)
        for name in ['it', 't']:
            try:
                diagnostics.remove(name)
            except ValueError:
                pass

    # Find and return the time average and its standard deviation of each diagnostics.
    if type(diagnostics) is str:
        return stats(diagnostics)
    else:  # assuming diagnostics is iterable.
        from collections import namedtuple
        Mean = namedtuple('Mean', diagnostics)
        StdDev = namedtuple('StandardDeviation', diagnostics)
        mean, stddev = zip(*(stats(diag) for diag in diagnostics))
        return Mean(*mean), StdDev(*stddev)
