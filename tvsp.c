#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <getopt.h>
#include <unistd.h>
#include <fcntl.h>
#include <sched.h>
#include <linux/sched.h>
#include <sys/mman.h>
#include <sys/wait.h>

#define STACK_SIZE (1024 * 16)

struct args
{
    int threads;
    int parallelism;
    int iterations;
};

int parse_args(int argc, char *argv[], struct args *args)
{
    args->threads = 0;

    // Parse arguments using getopt
    int opt;
    while ((opt = getopt(argc, argv, "tp:i:")) != -1)
    {
        switch (opt)
        {
        case 't':
            args->threads = 1;
            break;
        case 'p':
            args->parallelism = atoi(optarg);
            break;
        case 'i':
            args->iterations = atoi(optarg);
            break;
        default:
            fprintf(stderr, "Usage: %s [-t] [-p parallelism]\n", argv[0]);
            return 1;
        }
    }

    // Check that the arguments are valid
    if (args->parallelism < 1)
    {
        fprintf(stderr, "Parallelism must be at least 1\n");
        return 1;
    }

    return 0;
};

struct thread_args
{
    int id;
    int read_pipe;
    int write_pipe;
    int iterations;
    pid_t pid;
};

int thread(void *arg)
{
    struct thread_args *args = (struct thread_args *)arg;

    // printf("Thread %d pid=%d/%d\n", args->id, getpid(), args->pid);

    int send_buf = 0, recv_buf = 0;
    for (int i = 0; i < args->iterations; i++)
    {
        if (args->id == 0)
        {
            write(args->write_pipe, &send_buf, sizeof(int));
            read(args->read_pipe, &recv_buf, sizeof(int));
            send_buf = recv_buf + 1;
        }
        else
        {
            read(args->read_pipe, &recv_buf, sizeof(int));
            send_buf = recv_buf + 1;
            write(args->write_pipe, &send_buf, sizeof(int));
        }
    }

    // fprintf(stderr, "Thread %d pid=%d/%d r=%d w=%d buf=%d\n", args->id, getpid(), args->pid, args->read_pipe, args->write_pipe, recv_buf);

    return 0;
}

int main(int argc, char *argv[])
{
    struct args args;

    if (parse_args(argc, argv, &args) != 0)
    {
        return 1;
    }

    // Print arguments
    printf("Threads: %d\n", args.threads);
    printf("Parallelism: %d\n", args.parallelism);

    // Create pipes for each thread
    int *all_pipes = malloc(sizeof(int) * args.parallelism * 2);
    for (int i = 0; i < args.parallelism; i++)
    {
        int *cur_pipe = all_pipes + (i * 2);
        if (pipe(cur_pipe) == -1)
        {
            perror("pipe");
            return 1;
        }
    }

    // Create threads
    for (int i = 0; i < args.parallelism; i++)
    {
        int ret;
        int *prev_pipe = all_pipes + ((i + args.parallelism - 1) % args.parallelism) * 2;
        int *next_pipe = all_pipes + i * 2;
        struct thread_args *thread_args = malloc(sizeof(struct thread_args));

        void *stack = NULL;
        /* Allocate memory to be used for the stack of the child. */

        stack = mmap(NULL, STACK_SIZE, PROT_READ | PROT_WRITE,
                     MAP_PRIVATE | MAP_ANONYMOUS | MAP_STACK, -1, 0);
        if (stack == MAP_FAILED)
            perror("mmap");

        void *stack_top = stack + STACK_SIZE;

        thread_args->id = i;
        thread_args->read_pipe = prev_pipe[0];
        thread_args->write_pipe = next_pipe[1];
        thread_args->iterations = args.iterations;

        // Clone the process
        int flags = CLONE_CHILD_CLEARTID | CLONE_CHILD_SETTID | SIGCHLD | CLONE_FILES | CLONE_FS;
        if (args.threads)
        {
            flags |= CLONE_VM | CLONE_SIGHAND | SIGCHLD;
            ret = clone(thread, stack_top, flags, thread_args, NULL, NULL, &thread_args->pid);
        }
        else
        {
            ret = clone(thread, stack_top, flags, thread_args, NULL, NULL, &thread_args->pid);
        }
        if (ret == -1)
        {
            perror("clone");
            return 1;
        }
    }

    // Wait for threads to finish
    for (int i = 0; i < args.parallelism; i++)
    {
        int status;
        wait(&status);
    }

    fork();
}