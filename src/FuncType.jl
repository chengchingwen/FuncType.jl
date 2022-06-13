module FuncType

export FunctionType, funcargtype, funcrettype, WrapFunc,
    @Func, @functype

abstract type AbstractTypedFunction <: Function end
abstract type FunctionType{R, T<:Tuple} <: AbstractTypedFunction end

funcname(f) = sprint(show, f)
funcname(func::FunctionType) = nameof(typeof(func))

funcrettype(::FunctionType{R}) where R = R
funcrettype(::Type{<:FunctionType{R}}) where R = R
funcargtype(::FunctionType{R, T}) where {R, T} = T
funcargtype(::Type{<:FunctionType{R, T}}) where {R, T} = T

function jlfunc end

include("./wrap.jl")
include("./macro.jl")
include("./show.jl")

#=
?

julia> struct Compose{A, B, C,} <: FunctionType{
           FunctionType{C, Tuple{A}},
           Tuple{
               FunctionType{C, Tuple{B}},
               FunctionType{B, Tuple{A}}
           }
       }
       end

julia> cc = Compose{Int, Float64, Bool}()
Compose : (Float64 -> Bool, Int64 -> Float64) -> (Int64 -> Bool)

julia> function (compose::Compose{A, B, C})(
           f::FunctionType{C, Tuple{B}},
           g::FunctionType{B, Tuple{A}}
       ) where {A, B, C}
           return WrapFunc{C, Tuple{A}}(f ∘ g)
       end

julia> function (compose::Compose{A, B, C})(
           f,
           g
       ) where {A, B, C}
           return compose(WrapFunc{C, Tuple{B}}(f), WrapFunc{B, Tuple{A}}(g))
       end

julia> compose = cc(>=(0), sin)
ComposedFunction : Int64 -> Bool

julia> compose(4)
false

=#

end
