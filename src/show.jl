show_func(io::IO, t::Type{<:Tuple}) = show_func(io, Tuple(t.parameters))
function show_func(io::IO, t::Tuple)
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
show_func(io::IO, f) = show(io, f)
show_func(io::IO, f, top) = show_func(io, f)

function show_func(io::IO, func::FunctionType, top=true)
    top || print(io, '(')
    show(io, func)
    top || print(io, ')')
end

function show_func(io::IO, func::Type{<:FunctionType}, top=true)
    top || print(io, '(')
    show_func(io, funcargtype(func), false)
    print(io, " -> ")
    show_func(io, funcrettype(func), false)
    top || print(io, ')')
end

function Base.show(io::IO, func::FunctionType)
    print(io, funcname(func), ' ', ':', ' ')
    show_func(io, funcargtype(func), false)
    print(io, " -> ")
    show_func(io, funcrettype(func), false)
end
