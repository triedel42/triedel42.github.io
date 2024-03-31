# Philosophers
> "Have another drink," said Trillian, "Enjoy yourself."
> "Which?" said Arthur, "the two are mutually exclusive." - THG2G

Since this project is about learning to use threads, let's start [there][wiki-thread].

A [thread][wiki-thread] is like a process in that it runs [concurrently][wiki-concur] with other threads. It is unlike a process in that it shares its memory and even the program binary with other threads.

We are given a version of the [Dining philosophers problem][wiki-philo].

## Allowed functions
- old friends: [`memset`][memset], [`printf`][printf], [`malloc`][malloc], [`free`][free], [`write`][write]
- timing: [`usleep`][usleep], [`gettimeofday`][gettimeofday]
- new enemies: [`pthread_create`][pthread_create], [`pthread_detach`][pthread_detach], [`pthread_join`][pthread_join]
- mutex: [`pthread_mutex_init`][pthread_mutex_init], [`pthread_mutex_destroy`][pthread_mutex_destroy], [`pthread_mutex_lock`][pthread_mutex_lock], [`pthread_mutex_unlock`][pthread_mutex_unlock],

## Resources
- [POSIX Threads Programming](https://hpc-tutorials.llnl.gov/posix/)
- [Communicating Sequential Processes][book-hoare]: Tony Hoare's version of the Dining philosopher's problem (Chapter 2.5, page 55)
- [Lecture slides "Concurrency and Race Conditions"][lecture-cs110-08]
- [Lecutre slides "Threads and mutexes"][lecture-cs110-10]

## Threads
Creating threads is straightforward. We only need a function that takes and returns a void pointer:

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

	/* Thread will call threadfun */
	pthread_create(&thread, NULL, threadfun, NULL);
	/* Wait for thread to finish */
	pthread_join(thread, NULL);
}
```

You can also pass on to the thread a pointer to some shared memory (`args`). We will need this later.

## The problem with sharing forks
You might wonder what the big deal is with this project. After all, why not just have a boolean for each fork where `true` means "available" and `false` means taken?

Here is what might happen in our case:

```
philosopher 1 sees that fork 2 is free   (reading state of fork 2)
philosopher 2 sees that fork 2 is free   (reading state of fork 2)
philosopher 1 sets fork 2 as taken       (writing state of fork 2)
philosopher 2 sets fork 2 as taken       (writing state of fork 2)
```

After this, *both* philosophers are in possession of the *same fork*. We have created a [race condition][wiki-race].

The same scenario could have played out like this and all would have been "fine".

```
philosopher 1 sees that fork 2 is free   (reading state of fork 2)
philosopher 1 sets fork 2 as taken       (writing state of fork 2)
philosopher 2 sees that fork 2 is taken  (reading state of fork 2)
```

We do not want our program to depend on coincidence, therefore we will make use of [mutual exclusions][wiki-mutex], mutex for short.

### [Race conditions][wiki-race]
> "A race condition is an unpredictable ordering of events (due to e.g. OS scheduling)
where some orderings may cause undesired behavior." - [cs110-08][lecture-cs110-08]

In our code we have so-called [**critical sections**][wiki-critical] like the reading and writing of the fork state before. A critical section is indivisible in that it must not be interrupted by another thread. If it is, we might have a [**race condition**][wiki-race]. To *ensure* that it isn't interrupted we can make it **atomic**. Locking a [**mutex**][wiki-mutex] before and unlocking it after our critical section does that with respect to code that also locks the same mutex. If we protect critical sections in this way we avoid race conditions.

We always should consider the implications when memory is not only *shared*, but *accessed* concurrently. While it's not a problem when several threads read from the same value, reading *and* writing from different threads easily generates these problems.

### [Mutexes][wiki-mutex]
Mutexes are a way to ensure that a resource like a fork (or memory) are only in use by one thread at a time. For this we call [`pthread_mutex_lock`][pthread_mutex_lock]. If the resource is free, we take it and lock it so that nobody else can interfere. If it isn't, `pthread_mutex_lock` blocks (waits) until it is. In either case after `pthread_mutex_lock` returns (without error) we are in possession of the resource. Once we're done, we `pthread_mutex_unlock` the resource.

## The problem with waiting for forks
Here's another potential problem that arises, even with mutexes as forks. Imagine you have two philosophers and two forks on the table. They each start eating at the same time, both starting by picking up their left fork.

```
Philosopher 1 takes fork 1
Philosopher 2 takes fork 2
Philosopher 1 waits for fork 2, philosopher 2 waits for fork 1
```

Now the philosophers will starve to death, each holding one fork and waiting for the other.

This is called a [deadlock][wiki-deadlock], which apparently is what the [original Dining philosopher's problem][wiki-philo] is mostly concerned with. There are multiple solutions to that problem, two of which I believe are relevant for us.

### The arbitrator solution (unfeasible)
I find the [arbitrator solution][wiki-philo-arb] easiest.

The issue - as before - was that taking the forks isn't *atomic* (uninterruptible). Deadlocks from taking only one fork are undesired behavior, the taking of forks therefore is a *critical section*. We can *make* that section atomic by again using a mutex (the waiter). With that change philosopher's aren't allowed to take forks

```
Philosopher 1 asks waiter for both forks
Philosopher 1 picks up forks
Philosopher 2 asks waiter for both forks (but has to wait)
Philosopher 1 releases the forks
Philosopher 2 picks up forks
...
```

However, the blocking nature of our only available `pthread_mutex_lock` means that asking for currently taken forks keeps far away philosophers from doing the same with unrelated forks, because the "waiter is busy". I don't think therefore that this is solution is feasible.

### The Resource hierarchy solution
If we [order our forks from lowest to highest][wiki-philo-res] and always start by taking the lowest fork, we have also prevented deadlocks. This of course has the disadvantage that taking only one fork is still possible, but we will have to contend with that.

## Text output
Have you noticed this line in the subject?

> A displayed state message should not be mixed up with another message

It's not explicit, but I suppose we should regard outputting text as a resource as well. *Outputting* is something that only one thread at a time should do, or our output might be mangled by `printf`s interrupting each other. We should use a mutex for locking the output too.

While the Linux implementation of `printf` is thread-safe, the C standard as far as I know makes no such guarantee.

## Program outline
With all this at our disposal it becomes clearer what our program must look like.

Let's translate our task: Philosophers are threads, forks are mutexes. Eating is waiting while holding a fork mutex, thinking and sleeping are doing so without.

1. Process arguments
2. Initialize, set up Mutexes, allocate memory
3. Start philosopher threads
4. Have the threads lock and unlock mutexes and wait as needed
5. Monitor shared memory for dead philosophers or error
6. Join threads, destroy mutexes and exit

### Shared memory

What information do we pass on to the thread? A thread must know the program's parameters, the simulation state and have access to the mutexes. So I use a struct like this one and pass it onto the threads.

```C
/* simulation struct */
typedef	struct s_sim
{
	/* program parameters */
	const int		nphilo;			/* total number of seats */
	const int		time_to_die;
	const int		time_to_eat;
	const int		time_to_sleep;
	const int		must_eat;
	/* simulation state (SHARED) */
	int				stopped;		/* whether sim is active */
	int				error;			/* whether an error occurred */
	struct timeval	start;			/* timestamp of sim start */
	t_philo			*philos;		/* philosopher structs */
	int				philo_count;	/* currently seated philos */
	/* mutexes */
	pthread_mutex_t	*forks;			/* forks */
	pthread_mutex_t	output;			/* stdout */
	pthread_mutex_t	count;			/* incrementing philo_count */
}	t_sim;
```

Now this part we have to think very carefully about. Which thread changes which memory? One by one, let's make sure there is no race condition.

- `int stopped`: This variable is only ever set from `0` to `1`. Interspersed reads and writes have the same effect, so all good.
- `int error`: same as above
- `struct timeval start`: Written by main thread once, only read by philosopher threads after
- `t_philo *philos`: Each thread only reads and writes to their part of the array, so not actually shared
- `philo_count`: *Incremented* when a new philosopher thread starts. Yup, that's a problem! More mutexes!

#### Who even am I?
In order to make sure that each philosopher is an individual - with their own `id` - and `id`s only exists once, we need mutexes. When a philosopher thread starts it increments the global `philo_count`. And incrementing shared values is done with mutexes.

Here `errset(t_sim *s, status)` sets `sim->error` if `status` is nonzero.

```C
int	philo_whoami(t_sim *sim)
{
	if (errset(sim, pthread_mutex_lock(&sim->count)))
		return (ERR);
	sim->philo_count++;
	if (errset(sim, pthread_mutex_unlock(&sim->count)))
		return (ERR);
	// ids range from 0 to philo_count - 1
	return (sim->philo_count - 1);
}
```

Alternatively we might increment the value before starting the thread and give each philosopher their own slice of memory (including the shared `t_sim` struct). However then we'd have to worry about more allocations or variable scope.

### Philosophers' behavior
Let us try to describe the individual philosopher's behavior. The subject tells us:

> When a philosopher has finished eating, they put their forks back on the table and start sleeping. Once awake, they start thinking again.

Therefore the order of the actions is `eat, sleep, think`. But nowhere does it say which action to start with. We could start with either one.

- try to eat (if there is a fork)
- sleep
- think

While eating and sleeping don't offer much choice (They are `usleep(fixed_duration)` with and without holding a mutex.), waiting is *perhaps* not as simple. Naively, when thinking, we could simply call `pthread_mutex_lock`. That blocks our thread until a fork is available. In the meantime we might have starved however, without having announced it on the output and that is a sin.

How do we solve this then? There is no way for us to *check* if the mutex is free (`pthread_mutex_trylock` is forbidden). To solve that we could have a shared `bool` array and only call `pthread_mutex_lock` when it appears free, but we might not succeed, and wait again. Perhaps, almost realistically, philosophers cannot pronounce *themselves* dead. That also explains this line from the subject.

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
/* end simulation, clean up and exit */
```

### Ending the program
Once we have found a starved philosopher, we have to tell him that he starved - no really - by killing the thread. The [man page of `pthread_create`][pthread_create] tells us the ways a thread can exit. We here can unfortunately only kill a thread by returning from `main()`. That's unfortunate, because before doing so we need to destroy the mutexes and deallocate memory while the threads continue to operate on them.

Alternatively we could politely ask the philosophers to please die and only clean up once they obliged. A simple `bool` flag like `simulation_ended` would be enough. This is in shared memory yes, but does not create a race condition if we write it centrally from our main thread. The downside is that a philosopher might be stuck thinking, eating or sleeping and it could take a while for them to finish. So let's interrupt.

A thinking philosopher will be interrupted by giving him the fork. The block from `pthread_mutex_lock` is gone. When their neighbours are dead, they will get it. Easy enough.

A sleeping or eating philosopher has to interrupt themselves. We can of course divide up a `usleep(time_to_sleep)` like so to make them respect the end of a simulation.

```C
while (!simulation_ended && !finished_sleeping())
	usleep(1000);
```

Does this mess up the timing a lot? Maybe, but hopefully not too badly.

---

Another thing to consider or optimize is - maybe you've heard of it - [empathy][wiki-empathy]. I don't know about you, but I wouldn't take another poor starving thread's mutexes away while my belly is full!

Joking aside, there might be something to be gained from `usleep`ing a bit before taking a fork, in order to give those philosophers closer to starving a chance of taking them first. While we cannot communicate among the threads, this is a simple way of doing something similar: coordinating.

When and how long can we delay taking the fork? Well we know for long the fork will be gone. It will be gone for `time_to_eat` milliseconds. Therefore as long as we can survive longer than that we can afford some altruism (aka `usleep`).

### Error handling
Most functions like the mutex locking and unlocking return a value that indicates potential failure. How do we deal with failure? I see two options. You either exit with leaks and say it's okay, because it's an exception or you indicate an error in the shared memory and wait for every thread to recognize it and exit.

I prefer the latter, because it makes sure to free all the resources.

### Bonus part
Why would we need [`waitpid`][waitpid] if we can't [`fork`][fork]? Good question.


[wiki-concur]:				https://en.wikipedia.org/wiki/Concurrency_(computer_science)
[wiki-thread]:				https://en.wikipedia.org/wiki/Thread_(computing)
[wiki-philo]:				https://en.wikipedia.org/wiki/Dining_philosophers_problem
[wiki-philo-arb]:			https://en.wikipedia.org/wiki/Dining_philosophers_problem#Arbitrator_solution
[wiki-philo-res]:			https://en.wikipedia.org/wiki/Dining_philosophers_problem#Resource_hierarchy_solution
[wiki-deadlock]:			https://en.wikipedia.org/wiki/Deadlock
[wiki-mutex]:				https://en.wikipedia.org/wiki/Mutual_exclusion
[wiki-race]:				https://en.wikipedia.org/wiki/Race_condition
[wiki-critical]:			https://en.wikipedia.org/wiki/Critical_section
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


[book-hoare]:				http://www.usingcsp.com/cspbook.pdf
[lecture-cs110-08]:			https://web.stanford.edu/class/archive/cs/cs110/cs110.1214/static/lectures/cs110-lecture-08-race-conditions-deadlock.pdf
[lecture-cs110-10]:			https://web.stanford.edu/class/archive/cs/cs110/cs110.1204/static/lectures/10-threads-and-mutexes.pdf