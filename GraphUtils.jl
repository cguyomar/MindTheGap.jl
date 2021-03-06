using StatsBase


function cut_edges!(g,node,dir)
    if dir == "R"
        dir1="+" ; dir2="-"
    else
        dir1="-" ; dir2="+"
    end

    inn = inneighbors(g,node)
    it = 1
    while it < length(inn)
        n = inn[it]
        if get_prop(g,n,node,:outdir)==dir2
            rem_edge!(g,Edge(n,node))
        else
            it+=1
        end
    end

    outn = outneighbors(g,node)
    it = 1
    while it < length(outn)
        n = outn[it]
        if get_prop(g,node,n,:indir)==dir1
            rem_edge!(g,Edge(node,n))
        else
            it+=1
        end
    end
    return(g)
end



function graph_stats(g::MetaBiDiGraph)
    node_types = countmap([get_type(v,g) for v in vertices(g)])

    for type in ["contig","gapfilling","super contig"]
        nodes = filter_vertices(g,:type,type)
        total_length = length(join([get_seq(v,g) for v in filter_vertices(g,:type,type)]))
        if type in keys(node_types)
            println("Number of "*type*" : " * string(node_types[type]) * " for a length of " * string(total_length) * "bp")
        else
            println("Number of " * type * " : 0")
        end
    end
end

function get_type(node,g)
    return(get_prop(g,node,:type))
end
function get_seq(node,g)
    return(get_prop(g,node,:seq))
end

function rem_vertices_byname!(g,nodenames)
    for nodename in nodenames
        to_remove = collect(filter_vertices(g,:name,nodename))[1]
        rem_vertex!(g,to_remove)
    end
    return(g)
end

function find_vertex_byname(g,nodename)
    node = collect(filter_vertices(g,:name,nodename))[1]
    return(node)
end



# function neighbors(g::MetaDiGraph,node::Int,dir::String)
#     if dir == "R"
#         dir1="+" ; dir2="-"
#     else
#         dir1="-" ; dir2="+"
#     end
#
#     res=Dict{Int,String}()
#     outn = outneighbors(g,node)
#     for n in outn
#         if get_prop(g,node,n,:indir)==dir1
#             if get_prop(g,node,n,:outdir)==get_prop(g,node,n,:indir)
#                 res[n]="+"
#             else
#                 res[n]="-"
#             end
#         end
#     end
#
#     inn = inneighbors(g,node)
#     for n in inn
#         if get_prop(g,n,node,:outdir)==dir2
#             if get_prop(g,n,node,:outdir)==get_prop(g,n,node,:indir)
#                 res[n]="+"
#             else
#                 res[n]="-"
#             end
#         end
#     end
#     return(res)
# end

function compare_nodes(seqs::Dict{Int,String})
    # Compares a set of vertices sequences, and return vertices numbers to delete
    uniq = Int[]
    push!(uniq,first(keys(seqs)))
    remove = Int[]
    scoremodel = AffineGapScoreModel(EDNAFULL, gap_open=-5, gap_extend=-1)
    for node in keys(seqs)
        if node in uniq
            continue
        end
        foundmatch=false
        for ref in uniq
            if seqs[ref] == seqs[node]
                push!(remove,node)
                foundmatch=true
            else
                aln=pairalign(GlobalAlignment(),seqs[ref],seqs[node],scoremodel)
                # TODO
                # replace score by cout_match/length_aln
                # (Consider overlap length)
                if BioAlignments.score(aln)/5 > max(length(seqs[ref]),length(seqs[node]))*0.9
                    push!(remove,node)
                    foundmatch=true
                end
            end
        end
        if foundmatch==false
            push!(uniq,node)
        end
    end
    return(remove)
end


function rev_dir(dir::String)
    if dir=="R"
        return("L")
    elseif dir=="L"
        return("R")
    else
        error("format error")
    end
end
function rev_strand(strand::String)
    if strand=="+"
        return("-")
    elseif strand=="-"
        return("+")
    else
        error("format error")
    end
end

function remove_self_loops!(g::MetaBiDiGraph)
    v=1
    while v < nv(g)
        if v in outneighbors(g,v)
            rem_vertex!(g,v)
        else v=v+1
        end
    end
    return(g)
end

function component_size(comp::Array{Int64,1},g::MetaDiGraph)
    return(length(join(get_seq.(comp,g)))) # Should be corrected by the number of overlaps
end
