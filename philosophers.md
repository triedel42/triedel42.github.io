# Philosophers
> "To be is to do" - Socrates<br>
> "To do is to be" - Sartre<br>
> "Do be do be do" - Sinatra<br>

Since this project is about learning how threads work, let's start [there][wiki-thread].

A thread is like a process (see [`fork`][fork]) in that it runs concurrently with other threads. It is unlike a process in that it shares its memory and even the program binary with other threads.

## Functions
- old friends: [`memset`][memset], [`printf`][printf], [`malloc`][malloc], [`free`][free], [`write`][write]
- timing: [`usleep`][usleep], [`gettimeofday`][gettimeofday]
- new enemies: [`pthread_create`][pthread_create], [`pthread_detach`][pthread_detach], [`pthread_join`][pthread_join]
- mutex: [`pthread_mutex_init`][pthread_mutex_init], [`pthread_mutex_destroy`][pthread_mutex_destroy], [`pthread_mutex_lock`][pthread_mutex_lock], [`pthread_mutex_unlock`][pthread_mutex_unlock],

## Race conditions (abridged)
You might wonder what the big deal is with this project. After all, why not just have a boolean for each fork where `true` means "available" and `false` means taken? The problem with that are [race conditions][wiki-race].

Here is what might happen in our case:

```
philosopher 1: "hey look, fork 2 is free!"   (= read state of fork 2)
philosopher 2: "hey look, fork 2 is free!"   (= read state of fork 2)
philosopher 1  sets fork 2 as taken.         (= write state of fork 2)
philosopher 1  sets fork 2 as taken          (= write state of fork 2)
```

After this, *both* philosophers are in possession of the *same fork*. We have created a race condition. This can happen with memory where reads and writes from different threads are interleaved in such a way that the order matters.

The same scenario could have played out like this and all would be "fine".

```
philosopher 1: "hey look, fork 2 is free!"   (= read state of fork 2)
philosopher 1  sets fork 2 as taken.         (= write state of fork 2)
philosopher 2: "Oh no, fork 2 is taken"      (= read state of fork 2)
```

We do not want our program to depend on coincidence, therefore we will make use of [mutual exclusions][wiki-mutex], mutex for short.

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
Mutexes are a way to ensure that a resource like a fork (or memory) is only in use by one thread at a time. For this we call [`pthread_mutex_lock`][pthread_mutex_lock]. If the resource is free, we take it and lock it so that nobody else can interfere. If it isn't, `pthread_mutex_lock` waits until it is. In either case after `pthread_mutex_lock` returns (successfully) we are in possession of the resource. Once we're done we make sure to `pthread_mutex_unlock` the resource.

### Text output
One last thing. Have you noticed this line in the subject?

> A displayed state message should not be mixed up with another message

It's not explicit, but we should regard outputting text as a resource as well. If we want to ensure that text isn't mangled by threads interrupting each other, we should use a mutex for locking the output too.

## Program outline
With all this at our disposal it becomes clear what our program must look like.

Let's translate our task: Philosophers are threads, forks are mutexes. Eating is waiting while holding a mutex, thinking and sleeping are doing so without a mutex.

1. Process arguments
2. Set up Mutexes
3. Start philosopher threads
4. Have the threads acquire and release mutexes and wait as needed
5. Wait for philosopher threads to finish
6. Destroy mutexes and exit

### Philosophers' behavior
Let us try to describe the individual philosopher's behavior. The subject tells us:

> When a philosopher has finished eating, they put their forks back on the table and start sleeping. Once awake, they start thinking again.

Therefore the order of the actions is `eat, sleep, think`. But nowhere does it say which action to start with. We could start with either one.

- try to eat (if there is a fork)
- sleep
- think

While eating and sleeping don't offer much choice (They are `usleep(fixed_duration)` with and without holding a mutex.), waiting is *perhaps* not as simple. Naively, when thinking, we could simply call `pthread_mutex_lock`. That blocks our thread until a fork is available. In the meantime we might have starved however, without having announced it on the output and that is a sin.

How do we solve this then? There is no way for us to *check* if the mutex is free (`pthread_mutex_trylock` is forbidden). To solve that we could have a shared `bool` array and only call `pthread_mutex_lock` when it appears free, but we might not succeed, and wait again. Perhaps, almost realistically, philosophers cannot pronounce *themselves* dead. That also explain this line from the subject.

> A message announcing a philosopher died should be displayed no more than 10 ms
after the actual death of the philosopher.

### Finding the dead - and killing them

Allright then, having found out that we have to identify starved philosophers from the original thread, how do we do that? It should be easy.

In the memory that is shared with the threads we keep a record of each philosopher's last meal time. We check continuously and as soon as we notice that it's more than `time_to_die` milliseconds in the past we write a message and exit the program. 

This does not create a race condition, because each thread only writes to their respective philosopher's meal time and we only read it from the original thread.

Here is what the main thread might look like.

```C
/* This runs in the main thread */
while (check_if_starved(philosophers))
	usleep(1000);
announce_dead(philosophers);
/* then clean up and exit */
```

Once we have found a starved philosopher, we have to tell him that he starved - no really - by killing (or detaching the thread). That is something to take care of in the clean-up function.

---

Another thing to consider or optimize is - maybe you've heard of it - [empathy][wiki-empathy]. I don't know about you, but I wouldn't take another poor starving thread's mutexes away while my belly is full!

Joking aside, there might be something to be gained from `usleep`ing a bit before taking a fork, in order to give those philosophers closer to starving a chance of taking them first. While we cannot communicate among the threads, this is a simple way of doing something similar: coordinating.

When and how long can we delay taking the fork? Well we know for long the fork will be gone. It will be gone for `time_to_eat` milliseconds. Therefore as long as we can survive longer than that we can afford some altruism (aka `usleep`).


### Bonus part
Why would we need [`waitpid`][waitpid] if we can't [`fork`][fork]? Good question.

Have you paid attention to the deeply philosophical implications made? What may look like thinking on the outside is really only waiting to eat.




[wiki-thread]:				https://en.wikipedia.org/wiki/Thread_(computing)
[wiki-mutex]:				https://en.wikipedia.org/wiki/Mutual_exclusion
[wiki-race]:				https://en.wikipedia.org/wiki/Race_condition
[wiki-empathy]:				https://en.wikipedia.org/wiki/Empathy

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