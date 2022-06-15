# FuncType

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://chengchingwen.github.io/FuncType.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://chengchingwen.github.io/FuncType.jl/dev/)
[![Build Status](https://github.com/chengchingwen/FuncType.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/chengchingwen/FuncType.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/chengchingwen/FuncType.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/chengchingwen/FuncType.jl)

```julia
julia> using FuncType

julia> @Func Int -> Int   # single input single output
FunctionType : Int64 -> Int64

julia> @Func (Int, Float64) -> Float64   # multiple input single output
FunctionType : (Int64, Float64) -> Float64

julia> @Func Int -> (Float64, Float64)   # single input multiple output
FunctionType : Int64 -> (Float64, Float64)

julia> @Func (Int, Int) -> (Float64, Float64)   # multiple input multiple output
FunctionType : (Int64, Int64) -> (Float64, Float64)

julia> @Func () -> Int   # no input
FunctionType : () -> Int64

julia> @Func Tuple{A, A} -> A   # single tuple input
FunctionType : Tuple{var"#133#A", var"#133#A"} -> var"#133#A"

julia> @Func (Tuple{A, B}, B) -> C   # multiple input with tuple argument
FunctionType : (Tuple{var"#134#A", var"#135#B"}, var"#135#B") -> var"#136#C"

julia> @Func T -> T   # type var
FunctionType : var"#137#T" -> var"#137#T"

julia> @Func @NamedTuple{x::A, y::A} -> A   # nested macro
FunctionType : NamedTuple{(:x, :y), Tuple{var"#138#A", var"#138#A"}} -> var"#138#A"

julia> @Func (@Func(A -> B), Vector{A}) -> Vector{B}   # higher-order function: `map`
FunctionType : (var"#139#A" -> var"#140#B", Array{var"#139#A", 1}) -> Array{var"#140#B", 1}

julia> @Func Vector{@Func(A->A)} -> A   # container of function
FunctionType : Array{(var"#141#A" -> var"#141#A"), 1} -> var"#141#A"

julia> @Func ((C, A)->(C, B), C, Vector{A}) -> (C, Vector{B})   # scan :: (c -> a -> (c, b)) -> c -> [a] -> (c, [b])
FunctionType : ((var"#145#C", var"#143#A") -> (var"#145#C", var"#144#B"), var"#145#C", Array{var"#143#A", 1}) -> (var"#145#C", Array{var"#144#B", 1})

```
