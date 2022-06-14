struct WrapFunc{R, T<:Tuple, F} <: FunctionType{R, T}
    f::F
    function WrapFunc{R, T}(f::F) where {R, T, F}
        R2 = Core.Compiler.return_type(f, T)
        R === Union && throw(MethodError(f, T))
        isconcretetype(R2) && R2 !== R && error("""
        Type inference on $f(::$(join(T.parameters, ", ::"))) results in concrete type $R2 but specified as $R
        """)
        new{R, T, F}(f)
    end
    function WrapFunc{T}(f::F) where {T, F}
        R = Core.Compiler.return_type(f, T)
        R === Union && throw(MethodError(f, T))
        !isconcretetype(R) && error("""
        Type inference on $f(::$(join(T.parameters, ", ::"))) results in non-concrete type. Specify the return type manually.
        """)
        new{R, T, F}(f)
    end
end

function (wf::WrapFunc{R, T})(args...) where {R, T}
    if !(args isa T)
        throw(MethodError(typeof(wf), typeof(args)))
    end
    return invoke(wf.f, T, args...)::R
end

funcname(wf::WrapFunc) = nameof(wf.f)
