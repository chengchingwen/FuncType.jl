using FuncType
using Documenter

DocMeta.setdocmeta!(FuncType, :DocTestSetup, :(using FuncType); recursive=true)

makedocs(;
    modules=[FuncType],
    authors="chengchingwen <adgjl5645@hotmail.com> and contributors",
    repo="https://github.com/chengchingwen/FuncType.jl/blob/{commit}{path}#{line}",
    sitename="FuncType.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://chengchingwen.github.io/FuncType.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/chengchingwen/FuncType.jl",
    devbranch="main",
)
