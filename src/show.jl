function _tupletypetypeparam(@nospecialize t::Type{<:Tuple})
    if t isa UnionAll
        _T, rewrap = unwrap_rewrap_unionall(t)
        return map(Tuple(_T.parameters)) do _t
            if _t isa TypeVar
                return _t
            else
                return rewrap(_t)
            end
        end
    else
        return Tuple(t.parameters)
    end
end

function show_func(io::IO, _t::Type{<:Tuple})
    t = _tupletypetypeparam(_t)
    print(io, "Tuple")
    length(t) == 0 && return print(io, '{', '}')
    print(io, '{')
    for i in 1:length(t)-1
        show_func(io, t[i], true)
        print(io, ", ")
    end
    show_func(io, t[end])
    print(io, '}')
end

function show_func(io::IO, t::Tuple)
    length(t) == 0 && return print(io, '(', ')')
    print(io, '(')
    for i in 1:length(t)-1
        show_func(io, t[i], true)
        print(io, ", ")
    end
    show_func(io, t[end])
    print(io, ')')
end
show_func(io::IO, f) = show(io, f)
show_func(io::IO, f::Any, top) = show_func(io, f)

function show_func(io::IO, func::FunctionType, top=true)
    top || print(io, '(')
    show_func(io, funcargtype(func), false)
    print(io, " -> ")
    show_func(io, funcrettype(func), false)
    top || print(io, ')')
end

function show_func(io::IO, t::Core.TypeofVararg)
    T = isdefined(t, :T) ? t.T : Any
    if isdefined(t, :N)
        N = t.N
        for i = 1:N-1
            show_func(io, T, true)
            print(io, ", ")
        end
        show_func(io, T, true)
    else
        show_func(io, T, true)
        print(io, "...")
    end
end

function show_func(io::IO, T::TypeVar)
    if T.lb === Union{} && T.ub <: Tuple
        show_func(io, T.ub)
    else
        show(io, T)
    end
end

function show_func_arg(io::IO, T::TypeVar, top)
    if T.lb === Union{} && T.ub <: Tuple
        show_func_arg(io, T.ub)
    else
        show(io, T)
    end
end

show_func_arg(io::IO, t::Type{<:Tuple}, top=true) = show_func_arg(io, _tupletypetypeparam(t), top)
function show_func_arg(io::IO, t::Tuple, top=true)
    length(t) == 0 && return print(io, '(', ')')
    length(t) == 1 && return show_func(io, t[1], false)
    print(io, '(')
    for i in 1:length(t)-1
        show_func(io, t[i], true)
        print(io, ", ")
    end
    show_func(io, t[end])
    print(io, ')')
end

function show_func(io::IO, func::Type{<:FunctionType}, top=true)
    top || print(io, '(')
    params, rewrap = _functypetypeparam(func)
    R, T = params
    if T isa TypeVar
        show_func_arg(io, T, false)
    else
        show_func_arg(io, rewrap(T), false)
    end
    print(io, " -> ")
    if R isa TypeVar
        show_func(io, R, false)
    else
        show_func(io, rewrap(R), false)
    end
    top || print(io, ')')
end

function Base.show(io::IO, ::MIME"text/plain", func::Union{FunctionType, Type{<:FunctionType}})
    print(io, funcname(func), ' ', ':', ' ')
    show_func(io, func)
end
