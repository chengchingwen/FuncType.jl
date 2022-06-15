function _show_type_w_func(io::IO, @nospecialize(x), @nospecialize(t = x))
    x = x isa UnionAll ? Base.unwrap_unionall(x) : x
    if x isa Union || x isa TypeVar
        show(io, x)
    else
        print(io, Base.typename(x).name)
        nargs = length(x.parameters)
        if nargs != 0
            print(io, '{')
            for i = 1:nargs
                xi = x.parameters[i]
                if !(xi isa Type)
                    show(io, xi)
                elseif xi <: FunctionType
                    show_func(io, Base.rewrap_unionall(xi, t), false)
                else
                    _show_type_w_func(io, xi, t)
                end
                i != nargs && print(io, ", ")
            end
            print(io, '}')
        end
    end
end

show_func(io::IO, @nospecialize(func::FunctionType)) = show_func(io, typeof(func))

function show_func(io::IO, @nospecialize(F::Type{<:FunctionType}), top=true)
    top || print(io, '(')
    params, rewrap = _functypetypeparam(F)
    _R, _T = params
    T = rewrap(_T)
    narg = length(_T.parameters)
    narg != 1 && print(io, '(')
    for i = 1:narg
        _t = _T.parameters[i]
        t = Base.rewrap_unionall(_t, T)
        if t isa Type && t <: FunctionType
            show_func(io, t, true)
        else
            _show_type_w_func(io, _t, t)
        end
        i != narg && print(io, ", ")
    end
    narg != 1 && print(io, ')')

    print(io, " -> ")

    R = rewrap(_R)
    if R isa Type && R <: Tuple
        nret = length(_R.parameters)
        nret != 1 && print(io, '(')
        for i = 1:nret
            _r = _R.parameters[i]
            r = Base.rewrap_unionall(_r, R)
            if r isa Type && r <: FunctionType
                show_func(io, r, true)
            else
                _show_type_w_func(io, _r, r)
            end
            i != nret && print(io, ", ")
        end
        nret != 1 && print(io, ')')
    elseif R isa Type && R <: FunctionType
        show_func(io, R, false)
    else
        _show_type_w_func(io, _R, R)
    end

    top || print(io, ')')
end

function Base.show(io::IO, ::MIME"text/plain", func::Union{FunctionType, Type{<:FunctionType}})
    print(io, funcname(func), ' ', ':', ' ')
    show_func(io, func)
end
