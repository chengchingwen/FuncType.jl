module FuncType

export FunctionType, funcargtype, funcrettype, WrapFunc,
    @Func, @functype

abstract type AbstractTypedFunction <: Function end
abstract type FunctionType{R, T<:Tuple} <: AbstractTypedFunction end

funcname(f) = sprint(show, f)
function funcname(F::Type{<:FunctionType})
    if Base.typename(F) === Base.typename(FunctionType)
        return "FunctionType"
    else
        return sprint(show, F)
    end
end
funcname(func::FunctionType) = nameof(typeof(func))

unwrap_rewrap_unionall(@nospecialize t) = t, identity
function unwrap_rewrap_unionall(@nospecialize T::UnionAll)
    body, var = T.body, T.var
    wrap = Base.Fix1(UnionAll, var)
    if body isa UnionAll
        body, _wrap = unwrap_rewrap_unionall(body)
        rewrap = wrap ∘ _wrap
    else
        rewrap = wrap
    end

    return body, rewrap
end

function _functypetypeparam(@nospecialize _F::Type{<:FunctionType})
    _F = Base.typename(_F) === Base.typename(FunctionType) ? _F : supertype(_F)
    F, rewrap = unwrap_rewrap_unionall(_F)
    return F.parameters, rewrap
end

functypeparam(F::FunctionType) = funcrettype(F), funcargtype(F)
function functypeparam(@nospecialize _F::Type{<:FunctionType})
    params, rewrap = _functypetypeparam(_F)
    return rewrap(params[1]), rewrap(params[2])
end

"""
    funcrettype(::FunctionType)

Get the return type of the given type signature.
"""
funcrettype(::FunctionType{R}) where R = R
function funcrettype(@nospecialize _F::Type{<:FunctionType})
    params, rewrap = _functypetypeparam(_F)
    return rewrap(params[1])
end

"""
    funcargtype(::FunctionType)

Get the argument type of the given type signature, must be subtype of `Tuple`.
"""
funcargtype(::FunctionType{R, T}) where {R, T} = T
function funcargtype(@nospecialize _F::Type{<:FunctionType})
    params, rewrap = _functypetypeparam(_F)
    return rewrap(params[2])
end

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
