# Philosophers
> "To be is to do" - Socrates<br>
> "To do is to be" - Sartre<br>
> "Do be do be do" - Sinatra<br>

Since this project is about learning how threads work, let's start [there][wiki-thread].

A thread is like a process (see [`fork`][fork]) in that it runs concurrently with other threads. It is unlike a process in that it shares its memory and even the program binary with other threads.

You might wonder what the big deal is with this project. After all, why not just have a boolean for each fork where `true` means "available" and `false` means taken? The problem with that are [race conditions][wiki-race].

## Functions
- old friends: [`memset`][memset], [`printf`][printf], [`malloc`][malloc], [`free`][free], [`write`][write]
- timing: [`usleep`][usleep], [`gettimeofday`][gettimeofday]
- new enemies: [`pthread_create`][pthread_create], [`pthread_detach`][pthread_detach], [`pthread_join`][pthread_join]
- mutex: [`pthread_mutex_init`][pthread_mutex_init], [`pthread_mutex_destroy`][pthread_mutex_destroy], [`pthread_mutex_lock`][pthread_mutex_lock], [`pthread_mutex_unlock`][pthread_mutex_unlock],

### Basic thread handling
Creating a simple thread is straightforward. We only need a function that takes and returns a void pointer:

```C
#include <stdio.h>

/* This is the code that our thread will run */
void	*threadfun(void *args)
{
	printf("I'm a thread\n");
	return (NULL);
}

int	main()
{
	pthread_t	thread;

	/* Here we thread starts by calling threadfun */
	pthread_create(&thread, NULL, threadfun, NULL);
	/* Here we wait for our thread to finish */
	pthread_join(thread, NULL);
}
```

### Mutexes
Mutexes are a way to ensure that a recource like a fork (or memory) is only in use by one thread at a time. For this we call [`pthread_mutex_lock`][pthread_mutex_lock]. If the resource is free, we take it and lock it so that nobody else can interfere. If it isn't, `pthread_mutex_lock` waits until it is. In either case after `pthread_mutex_lock` returns (successfully) we are in possession of the resource. Once we're done we make sure to `pthread_mutex_unlock` the resource.

### Text output
One last thing. Have you noticed this line in the subject?

> A displayed state message should not be mixed up with another message

It's not explicit, but we should regard outputting text as a resource as well. If we want to ensure that text isn't mangled by threads interrupting each other, we should use a mutex for locking the output too.

## Program outline
With all this at our disposal it becomes clear what our program must look like.

Let's translate our task: Philosophers are threads, forks are mutexes. Eating is waiting while holding a mutex, thinking and sleeping is doing so without a mutex.

1. Process arguments
2. Set up Mutexes
3. Start philosopher threads
4. Have the threads acquire and release mutexes and wait as needed
5. Wait for philosopher threads to finish
6. Destroy mutexes and exit

### Philosopher's behavior
Let us try to describe the individual philosopher's behavior. The subject tells us:

> When a philosopher has finished eating, they put their forks back on the table and start sleeping. Once awake, they start thinking again.

Therefore the order of the actions is `eat, sleep, think`. But nowhere does it say which action to start with. We could start with either one.

- try to eat (if there is a fork)
- sleep
- think

While eating and sleeping don't offer much choice (they are `usleep` with and without holding a mutex).



Why would we need [`waitpid`][waitpid] if we can't [`fork`][fork]? Good question.

Have you paid attention to the philosophical implications made? What may look like thinking on the outside is really only waiting to eat.




[wiki-thread]:		https://en.wikipedia.org/wiki/Thread_(computing)
[wiki-race]:		https://en.wikipedia.org/wiki/Race_condition

[fork]:						https://www.man7.org/linux/man-pages/man2/fork.2.html
[waitpid]:					https://www.man7.org/linux/man-pages/man2/waitpid.2.html

[memset]:					https://www.man7.org/linux/man-pages/man3/memset.3.html
[printf]:					https://www.man7.org/linux/man-pages/man3/printf.3.html
[malloc]:					https://www.man7.org/linux/man-pages/man3/malloc.3.html
[free]:						https://www.man7.org/linux/man-pages/man3/free.3.html
[write]:					https://www.man7.org/linux/man-pages/man2/write.2.html
[usleep]:					https://www.man7.org/linux/man-pages/man3/usleep.3.html
[gettimeofday]:				https://www.man7.org/linux/man-pages/man2/gettimeofday.2.html
[pthread_create]:			https://www.man7.org/linux/man-pages/man3/pthread_create.3.html
[pthread_detach]:			https://www.man7.org/linux/man-pages/man3/pthread_detach.3.html
[pthread_join]:				https://www.man7.org/linux/man-pages/man3/pthread_join.3.html
[pthread_mutex_init]:		https://pubs.opengroup.org/onlinepubs/9699919799/functions/pthread_mutex_init.html
[pthread_mutex_destroy]:	https://pubs.opengroup.org/onlinepubs/9699919799/functions/pthread_mutex_init.html
[pthread_mutex_lock]:		https://pubs.opengroup.org/onlinepubs/9699919799/functions/pthread_mutex_lock.html
[pthread_mutex_unlock]:		https://pubs.opengroup.org/onlinepubs/9699919799/functions/pthread_mutex_lock.html