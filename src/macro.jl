using Base.Meta: isexpr

using ExprTools

function _funcm(m, ex, collected_sym = Set(), top=true)
    if ex isa Expr
        if isexpr(ex, :->)
            arg, body = ex.args
            ret = body.args
            filter!(!Base.Fix2(isa, LineNumberNode), ret)
            length(ret) != 1 && error("contain multi-line in function type")
            _T = _funcm(m, arg, collected_sym)[1]
            T = isexpr(_T, :tuple) ? :(Tuple{$(_T.args...)}) : :(Tuple{$_T})
            _R = _funcm(m, ret[1], collected_sym)[1]
            R = isexpr(_R, :tuple) ? :(Tuple{$(_R.args...)}) : _R
            return :(FunctionType{$R, $T}), collected_sym
        elseif isexpr(ex, :tuple)
            _t = map(a->_funcm(m, a, collected_sym)[1], ex.args)
            T = Expr(:tuple, _t...)
            return T, collected_sym
        elseif isexpr(ex, :curly)
            _T = map(a->_funcm(m, a, collected_sym)[1], ex.args)
            T = Expr(:curly, _T...)
            return T, collected_sym
        elseif isexpr(ex, :macrocall)
            ex = ex.args[1] == Symbol("@Func") ? ex.args[3] : macroexpand(m, ex)
            return _funcm(m, ex, collected_sym)
        else
            error("Unknown expr head $(ex.head)")
        end
    elseif ex isa Symbol
        T = ex
        if isdefined(m, ex)
            # defined type
            return esc(T), collected_sym
        else
            # type var
            push!(collected_sym, ex)
            return T, collected_sym
        end
    else
        return ex, collected_sym
    end
end

function funcm(m, ex)
    if isexpr(ex, :->)
        T, collected_sym = _funcm(m, ex)
        if isempty(collected_sym)
            return T
        else
            return Expr(:where, T, collected_sym...)
        end
    else
        error("function type should be defined with ->")
    end
end

function functype_from_args(m, rtype, args)
    R, collected_sym = _funcm(m, rtype)
    T, fargs, argsym = if isnothing(args)
        :(Tuple{}), (), ()
    else
        _t, _args, _argsym = [], [], []
        for (i, arg) in enumerate(args)
            @assert isexpr(arg, :(::)) "having error or missing type annotation in $i-th argument: $arg"
            sym, ex = arg.args
            _T = _funcm(m, ex, collected_sym)[1]
            _arg = Expr(:(::), sym, _T)
            push!(_t, _T)
            push!(_args, _arg)
            push!(_argsym, sym)
        end
        :(Tuple{$(_t...)}), _args, _argsym
    end
    return R, :(FunctionType{$R, $T}), fargs, argsym, collected_sym
end

function functypem(m, ex)
    def = splitdef(ex)
    name = get(def, :name, nothing)
    @assert name isa Symbol "function name is not a symbol"
    tname = Symbol(titlecase(String(name)))
    fname = Symbol(name, "#func")

    rtype = get!(def, :rtype, :Nothing)
    frtype, ftype, fargs, argsym, collected_sym = functype_from_args(m, rtype, get(def, :args, nothing))

    params = get(def, :whereparams, ())
    if !(params ⊆ collected_sym)
        p = findfirst(!Base.Fix2(in, collected_sym), params)
        throw(AssertionError("where parameter $p not found in type signature"))
    end

    if isempty(collected_sym)
        type = :(struct $tname <: $ftype end)
    else
        type = :(struct $tname{$(collected_sym...)} <: $ftype end)
    end

    tfunc = Dict(
        :args => fargs,
        :body => quote $fname($(argsym...)) end,
        :name => :(::Type{<:$tname}),
        :head => :function,
        :whereparams => collect(collected_sym)
    ) |> combinedef |> esc

    def[:args] = fargs
    def[:name] = fname
    def[:rtype] = frtype
    def[:whereparams] = collect(collected_sym)
    func = combinedef(def) |> esc

    jlfunc = :(FuncType.jlfunc(::Type{<:$tname}) = $fname) |> esc
    return quote
        $type
        $jlfunc
        $tfunc
        $func
    end
end


"""
    @Func(<func type sig>)

Create a [`FunctionType`](@ref) with function type signature syntax. Because Julia function are not curried,
 function with multiple argument need to be explicitly wrap with parenthesis. On the other hand, `Tuple`
 input need to be specified as something like `Tuple{A, B}`.

# Example
```julia-repl
julia> @Func Int -> Int   # single input single output
FunctionType{Int64, Tuple{Int64}}

julia> @Func (Int, Float64) -> Float64   # multiple input single output
FunctionType{Float64, Tuple{Int64, Float64}}

julia> @Func Int -> (Float64, Float64)   # single input multiple output
FunctionType{Tuple{Float64, Float64}, Tuple{Int64}}

julia> @Func (Int, Int) -> (Float64, Float64)   # multiple input multiple output
FunctionType{Tuple{Float64, Float64}, Tuple{Int64, Int64}}

julia> @Func () -> Int   # no input
FunctionType{Int64, Tuple{}}

julia> @Func Tuple{A, A} -> A   # single tuple input
FunctionType{var"#41#A", Tuple{Tuple{var"#41#A", var"#41#A"}}} where var"#41#A"

julia> @Func (Tuple{A, B}, B) -> C   # multiple input with tuple argument
FunctionType{<:Any, Tuple{Tuple{var"#42#A", var"#43#B"}, var"#43#B"}} where {var"#42#A", var"#43#B"}

julia> @Func T -> T   # type var
FunctionType{var"#30#T", Tuple{var"#30#T"}} where var"#30#T"

julia> @Func @NamedTuple{x::A, y::A} -> A   # nested macro
FunctionType{var"#40#A", Tuple{NamedTuple{(:x, :y), Tuple{var"#40#A", var"#40#A"}}}} where var"#40#A"

julia> @Func (@Func(A -> B), Vector{A}) -> Vector{B}   # higher-order function: `map`
FunctionType{Vector{var"#15#B"}, Tuple{FunctionType{var"#15#B", Tuple{var"#14#A"}}, Vector{var"#14#A"}}} where {var"#14#A", var"#15#B"}

julia> @Func ((C, A)->(C, B), C, Vector{A}) -> (C, Vector{B})   # scan :: (c -> a -> (c, b)) -> c -> [a] -> (c, [b])
FunctionType{Tuple{var"#47#C", Vector{var"#46#B"}}, Tuple{FunctionType{Tuple{var"#47#C", var"#46#B"}, Tuple{var"#47#C", var"#45#A"}}, var"#47#C", Vector{var"#45#A"}}} where {var"#45#A", var"#46#B", var"#47#C"}

```
"""
macro Func(ex)
    return funcm(__module__, ex)
end

"""
    @functype function <func name>(<arg with type sig>)::<ret type> where {<parameters, if any>}
        <func body>
    end


If `ret type` is missing, assuming the function return `nothing`
"""
macro functype(ex)
    return functypem(__module__, ex)
end
