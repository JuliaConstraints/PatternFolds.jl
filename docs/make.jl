using PatternFolds
using Documenter

DocMeta.setdocmeta!(PatternFolds, :DocTestSetup, :(using PatternFolds); recursive=true)

makedocs(;
    modules=[PatternFolds],
    authors="Jean-Francois Baffier",
    repo="https://github.com/Humans-of-Julia/PatternFolds.jl/blob/{commit}{path}#{line}",
    sitename="PatternFolds.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://Humans-of-Julia.github.io/PatternFolds.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/Humans-of-Julia/PatternFolds.jl",
    devbranch="main",
)
