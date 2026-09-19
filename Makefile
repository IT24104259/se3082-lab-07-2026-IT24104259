CC = mpicc
CFLAGS = -Wall

TARGETS = sum_bcast sum_scatter sum_gather sum_reduce sum_allreduce sum_scan

all: $(TARGETS)

sum_bcast: sum_bcast.c
	$(CC) $(CFLAGS) -o sum_bcast sum_bcast.c

sum_scatter: sum_scatter.c
	$(CC) $(CFLAGS) -o sum_scatter sum_scatter.c

sum_gather: sum_gather.c
	$(CC) $(CFLAGS) -o sum_gather sum_gather.c

sum_reduce: sum_reduce.c
	$(CC) $(CFLAGS) -o sum_reduce sum_reduce.c

sum_allreduce: sum_allreduce.c
	$(CC) $(CFLAGS) -o sum_allreduce sum_allreduce.c

sum_scan: sum_scan.c
	$(CC) $(CFLAGS) -o sum_scan sum_scan.c

run: all
	mpirun -np 4 --oversubscribe ./sum_bcast
	mpirun -np 4 --oversubscribe ./sum_scatter
	mpirun -np 4 --oversubscribe ./sum_gather
	mpirun -np 4 --oversubscribe ./sum_reduce
	mpirun -np 4 --oversubscribe ./sum_allreduce
	mpirun -np 4 --oversubscribe ./sum_scan

clean:
	rm -f $(TARGETS)
