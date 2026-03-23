#using Pkg
#Pkg.activate(".")
#Pkg.instantiate()
##
using CSV
using DataFrames
using Plots
using TimeSeries
using Dates
using Printf
#####################Config

#####################

## Helper Functions


##
filepaths = readdir("input/", join=true)
##
for path in filepaths
    file = path


    ## Load CSV into Dataframe
    df = DataFrame(CSV.File(file; delim="\t"))

    ## Cut beginning of unneeded Data 
    df = df[5:end, :]

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
            decimal=',',
            dateformat="dd.mm.yyyy HH:MM:SS,sss"
        )
    )

    dftemperature = select(df, Cols("Datum", r"csca_t[1-9]"))
    dfcells = select(df, Cols("Datum", r"csca_uc[1-9]"))
    dfpack = select(df, Cols("Datum", "csca_upack[]"))
    ##
    CSV.write("temperature.csv", dftemperature;)
    CSV.write("cells.csv", dfcells)
    CSV.write("pack.csv", dfpack)
    ##
    tatemperature = readtimearray("temperature.csv", delim=',')
    tacells = readtimearray("cells.csv", delim=',')
    tapack = readtimearray("pack.csv", delim=',')

    tatemperature = retime(tatemperature, Millisecond(100))
    tacells = retime(tacells, Millisecond(100))
    tapack = retime(tapack, Millisecond(100))

    ## Plot the Data 
    tstemperature = timestamp(tatemperature)
    Ytemperature = values(tatemperature)
    lbltemperature = String.(colnames(tatemperature))
    @assert size(Ytemperature, 2) == length(lbltemperature)

    tscells = timestamp(tacells)
    Ycells = values(tacells)
    lblcells = String.(colnames(tacells))
    @assert size(Ycells, 2) == length(lblcells)

    tspack = timestamp(tapack)
    Ypack = values(tapack)
    lblpack = String.(colnames(tapack))
    @assert size(Ypack, 2) == length(lblpack)
    ##
    t0 = tstemperature[1]
    trel_s = Float64.(Dates.value.(tstemperature .- t0)) ./ 1000

    plotlyjs()

    basename_noext = splitext(basename(file))[1]
    htmlnametemperature = "output/html/" * basename_noext * "_temperature.html"
    svgnametemperature = "output/svg/" * basename_noext * "_temperature.svg"

    htmlnamecells = "output/html/" * basename_noext * "_cells.html"
    svgnamecells = "output/svg/" * basename_noext * "_cells.svg"

    htmlnamepack = "output/html/" * basename_noext * "_pack.html"
    svgnamepack = "output/svg/" * basename_noext * "_pack.svg"
    ##
    mmss_formatter = x -> begin
        s = max(0, round(Int, x))
        m, s = divrem(s, 60)
        @sprintf("%02d:%02d", m, s)
    end

    plt = Plots.plot(
        title=basename_noext,
        xlabel="Time",
        xformatter=mmss_formatter,
        size=[1500, 750],
    )

    for i in 1:size(Ytemperature, 2)
        plot!(plt, trel_s, ylabel="Temperature in °C", Ytemperature[:, i], label=lbltemperature[i], lw=1.8)
    end
    display(plt)
    Plots.savefig(htmlnametemperature)
    Plots.savefig(svgnametemperature)

    plt = Plots.plot(
        title=basename_noext,
        xlabel="Time",
        xformatter=mmss_formatter,
        size=[1500, 750],
    )
    for i in 1:size(Ycells, 2)
        plot!(plt, trel_s, ylabel="Cellvoltage in mV", Ycells[:, i], label=lblcells[i], lw=1.8)
    end
    display(plt)

    Plots.savefig(htmlnamecells)
    Plots.savefig(svgnamecells)


    plt = Plots.plot(
        title=basename_noext,
        xlabel="Time",
        xformatter=mmss_formatter,
        size=[1500, 750],
    )

    for i in 1:size(Ypack, 2)
        plot!(plt, trel_s, ylabel="Packvoltage in V", Ypack[:, i], label=lblpack[i], lw=1.8)
    end

    Plots.savefig(htmlnamepack)
    Plots.savefig(svgnamepack)
    display(plt)







end
