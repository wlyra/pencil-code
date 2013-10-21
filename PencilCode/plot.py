#
# plot.py
#
# Facilities for plotting the Pencil Code data.
#
# Chao-Chin Yang, 2013-10-22
# Last Modification: $Id$
#
def time_series(datadir='./data', diagnostics='dt'):
    """Plots diagnostic variable(s) as a function of time.

    Keyword Arguments:
        datadir:  Name of the data directory.
        diagnostics:  (A list of) diagnostic variable(s).
    """
    #
    # Chao-Chin Yang, 2013-10-22
    #
    from . import read
    from pylab import plot, show

    # Read the time series.
    ts = read.time_series(datadir=datadir)

    # Plot the diagnostics.
    if type(diagnostics) is list:
        for diag in diagnostics:
            plot(ts.t, ts[diag])
    else:
        plot(ts.t, ts[diagnostics])
    show()

