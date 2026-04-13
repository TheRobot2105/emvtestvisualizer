## See Readme for installation and usage
## initialising and installing needed Pkgs
#using Pkg
#Pkg.activate(".")
#Pkg.instantiate()

## loading needed Pkgs
using CSV
using DataFrames
using Plots
using TimeSeries
using Dates
using Printf

#Set used decimal separator ',' or '.'
decimalpoint = ','


## loading all files in input directory
filepaths = readdir("input/", join=true)

## stepping through all files
for path in filepaths
    file = path

    ## Load CSV into Dataframe
    df = DataFrame(CSV.File(file; delim="\t"))

    ## Cut beginning of unneeded Data 
    df = df[5:end, :]
    df = replace.(df, "\xb0" => "°")

    ## correctly name the columns
    DataFrames.rename!(df, Symbol.(Vector(df[1, :])))
    df = df[2:end, :]
    display(df)

    ## Correct columns types
    CSV.write("temp.csv", df; delim=(";"))
    df = DataFrame(
        CSV.read(
            "temp.csv",
            DataFrame;
            delim=';',
            decimal=decimalpoint,
            dateformat="dd.mm.yyyy HH:MM:SS,sss"
        )
    )

    ## Select the different types of messurments
    dfarray = [
        select(df, Cols("Datum", r"csca_t[1-4]")),
        select(df, Cols("Datum", r"csca_uc[1-9]")),
        select(df, Cols("Datum", "csca_upack[]"))]

    filename = [
        "temperature",
        "cells",
        "pack"
    ]
    ## Sort them (there is some error because of unsorted timefield no idea why its unsorted)
    for df in dfarray
        sort!(df, :Datum)
    end

    ## Load in Timearray
    taarray = []
    for df in dfarray
        ta = TimeArray(df, timestamp=:Datum)
        push!(taarray, ta)
    end

    ## Seperate Time Data and Labels
    ts = []
    Y = []
    lbl = []
    for ta in taarray
        push!(ts, timestamp(ta))
        push!(Y, values(ta))
        push!(lbl, String.(colnames(ta)))
    end

    ## Get start time for relative plot
    t0 = ts[1][1]
    trel_s = Float64.(Dates.value.(ts[1] .- t0)) ./ 1000

    plotlyjs()

    ## Get filenames from initial file
    basename_noext = splitext(basename(file))[1]
    htmlname = []
    svgname = []

    for name in filename
        push!(htmlname, "output/html/" * basename_noext * "_" * name * ".html")
        push!(svgname, "output/svg/" * basename_noext * "_" * name * ".svg")
    end

    ##Plot and save plots
    mmss_formatter = x -> begin
        s = max(0, round(Int, x))
        m, s = divrem(s, 60)
        @sprintf("%02d:%02d", m, s)
    end

    mkpath("output/html")
    mkpath("output/svg")

    for i in 1:size(taarray, 1)
        plt = Plots.plot(
            title=basename_noext,
            xlabel="Time",
            xformatter=mmss_formatter,
            size=[1500, 750],
        )
        for j in 1:size(Y[i], 2)
            plot!(plt, trel_s, ylabel="Test", Y[i][:, j], label=lbl[i][j], lw=1.8)
        end
        Plots.savefig(htmlname[i])
        Plots.savefig(svgname[i])
    end
end
