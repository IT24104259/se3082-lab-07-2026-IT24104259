
Exercise 7: Summary Comparison


1. Execution Time Comparison (seconds)

Program         | np=2   | np=4   | np=8
----------------|--------|--------|-------
sum_bcast       | 0.0062 | 0.0120 | 0.0293
sum_scatter     | 0.0059 | 0.0045 | 0.0047
sum_gather      | 0.0056 | 0.0054 | 0.0051
sum_reduce      | 0.0059 | 0.0051 | 0.0046
sum_allreduce   | 0.0057 | 0.0066 | 0.0099
sum_scan        | 0.0124 | 0.0108 | 0.0088

2. Program Comparison

Program         | Collectives used     | Full array or chunk?          | Manual sum loop?  | Result available on
----------------|----------------------|-------------------------------|-------------------|----------------------------------------
sum_bcast       | Bcast + Send/Recv    | Full array (every process)    | Yes (root)        | Root only
sum_scatter     | Scatter + Send/Recv  | Chunk only                    | Yes (root)        | Root only
sum_gather      | Scatter + Gather     | Chunk only                    | Yes (root)        | Root only
sum_reduce      | Scatter + Reduce     | Chunk only                    | No                | Root only
sum_allreduce   | Scatter + Allreduce  | Chunk only                    | No                | All processes (same value)
sum_scan        | Scatter + Scan       | Chunk only                    | No                | All processes (different value per rank)

3. Which approach is fastest, and why?

sum_bcast was clearly the slowest and worst-scaling approach, growing from 0.0062s (np=2)
to 0.0293s (np=8) -- nearly a 5x increase -- because it broadcasts the entire
1,000,000-element array to every process regardless of process count, so more processes
means more redundant data transfer and memory use. All Scatter-based versions
(sum_scatter, sum_gather, sum_reduce, sum_allreduce) stayed consistently fast
(0.0045-0.0066s) across all process counts, since each process only ever receives its
own small chunk. Among these, sum_scatter and sum_reduce were fastest overall, with
sum_reduce showing the best scaling (0.0059 -> 0.0051 -> 0.0046s), since MPI's internal
reduction algorithm runs in O(log P) steps rather than the O(P) sequential Send/Recv
loop used by sum_bcast and sum_scatter. sum_allreduce was slightly slower at higher
process counts (0.0099s at np=8) since it must deliver the result to every process, not
just root. sum_scan actually improved with more processes (0.0124 -> 0.0108 -> 0.0088s),
likely because smaller per-process chunks reduced local summation work more than the
scan's communication overhead increased it.

Overall, replacing full-array broadcast with targeted chunk distribution (Scatter)
gives the single biggest performance win, and replacing manual point-to-point
communication with purpose-built collectives (Gather, Reduce, Allreduce, Scan) gives
further gains as process count increases.

4. Thinking question: When would you choose MPI_Scan over MPI_Allreduce?

MPI_Scan is the right choice for me when different processes need different, cumulative
results, rather than the single shared final answer MPI_Allreduce provides identically
to everyone. 
Concrete example: parallel prefix-based output indexing. If each process
produces a variable number of results that must be written into one shared output array
in rank order, MPI_Scan on each process's result count gives a running total of "how
many results have been produced up to and including me." Subtracting each process's own
count gives it the exact starting offset to begin writing into the shared array.
MPI_Allreduce cannot provide this, since it gives every process the same total count,
not each process's individual offset.
