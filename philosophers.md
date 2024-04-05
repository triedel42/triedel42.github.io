# Philosophers
> "Have another drink," said Trillian, "Enjoy yourself."
> "Which?" said Arthur, "the two are mutually exclusive." - THG2G

We are given a version of the [Dining philosophers problem][wiki-philo].

## Resources
- [Philosophers visualizer](https://nafuka11.github.io/philosophers-visualizer/) (by [nafuka11](https://github.com/nafuka11/philosophers-visualizer?tab=readme-ov-file))
- Threads and Mutexes:
	- [POSIX Threads Programming](https://hpc-tutorials.llnl.gov/posix/)
	- [Lecture slides "Concurrency and Race Conditions"][lecture-cs110-08]
	- [Lecture slides "Threads and mutexes"][lecture-cs110-10]
- Semaphores (Bonus)
	- [Semaphore explanation and examples (plaintext)](https://pages.cs.wisc.edu/~remzi/Classes/537/Fall2008/Notes/threads-semaphores.txt)
	- [Semaphores man page][sem-overview]
- On the "[Dining Philosopher's problem][wiki-philo]:
	- [Dijkstra's Dining Philosopher's Problem](https://www.cs.utexas.edu/users/EWD/ewd03xx/EWD310.PDF) (p. 20)
	- [Communicating Sequential Processes][book-hoare]: Tony Hoare's version (Chapter 2.5, p. 55)

---


## Allowed functions
- old friends: [`memset`][memset], [`printf`][printf], [`malloc`][malloc], [`free`][free], [`write`][write]
- timing: [`usleep`][usleep], [`gettimeofday`][gettimeofday]
- new enemies: [`pthread_create`][pthread_create], [`pthread_detach`][pthread_detach], [`pthread_join`][pthread_join]
- mutex: [`pthread_mutex_init`][pthread_mutex_init], [`pthread_mutex_destroy`][pthread_mutex_destroy], [`pthread_mutex_lock`][pthread_mutex_lock], [`pthread_mutex_unlock`][pthread_mutex_unlock]

## Threads
Since this project is about learning to use threads, let's start [there][wiki-thread].

A [thread][wiki-thread] is like a process in that it runs [concurrently][wiki-concur] with other threads. It is unlike a process in that it shares its memory and even the program binary with other threads.

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
Mutexes are a way to ensure that a resource like a fork (commonly memory) are only in use by one thread at a time. For this we call [`pthread_mutex_lock`][pthread_mutex_lock]. If the resource is free, we take it and lock it so that nobody else can interfere. If it isn't, `pthread_mutex_lock` blocks (waits) until it is. In either case after `pthread_mutex_lock` returns (without error) we are in possession of the resource. Once we're done, we `pthread_mutex_unlock` the resource.

The fact that `pthread_mutex_lock` might block means we should use Mutexes sparingly. There is also `pthread_mutex_trylock`, wich comes without that disadvantage, but we're not allowed to use it.

## The problem with waiting for forks
Here's another potential problem that arises, even when the forks are protected with mutexes. Imagine you have two philosophers and two forks on the table. They each start eating at the same time, both starting by picking up their left fork.

Here "waits for fork" means locking the mutex that protects the fork.

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

However, the blocking nature of our only available `pthread_mutex_lock` means that asking for currently taken forks keeps far away philosophers from doing the same with unrelated forks, because the "waiter is busy". I don't think, therefore, that this is solution is feasible.

### The Resource hierarchy solution
If we [order our forks from lowest to highest][wiki-philo-res] and always start by taking the lowest fork, we have also prevented deadlocks. It is like having one left-handed philosopher at the table, who unlike the others, starts with the other fork.

This method of course has the disadvantage that taking only one fork at a time is still possible, but we will have to contend with that.

## Moral philosophy
How does a good philosopher behave? Good meaning his actions make the simulation run as long as possible.

> When a philosopher has finished eating, they put their forks back on the table and start sleeping. Once awake, they start thinking again.

Hence the order of the actions is given as `eat, sleep, think`. We could start with either one.

Remember though that no communication is allowed between them. If possible, we want them to behave in a coodinated way without the *need* even to communicate.

## Text output
Have you noticed this line in the subject?

> A displayed state message should not be mixed up with another message

It's not explicit, but I suppose we should regard outputting text as a resource as well. *Outputting* is something that only one thread at a time should do, or our output might be mangled by `printf`s interrupting each other. We should use a mutex for locking the output too.

While the Linux implementation of `printf` may be thread-safe, the C standard as far as I know makes no such guarantee.

## Program outline
With all this at our disposal it becomes clearer what our program must look like.

Let's translate our task: Philosophers are threads, forks are mutex-protected booleans. Eating is waiting with a fork, thinking and sleeping are doing so without.

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
typedef struct s_sim
{
	/* program parameters */
	int				nphilos;		/* total number of seats */
	int				time_to_die;
	int				time_to_eat;
	int				time_to_sleep;
	int				must_eat;
	/* simulation state (SHARED) */
	int				stopped;		/* whether sim is active */
	int				error;			/* whether an error occurred */
	struct timeval	start;			/* timestamp of sim start */
	unsigned int	philo_count;	/* currently seated philos */
	t_philo			*philos;		/* philosopher structs */
	int				*forks;			/* fork states */
	/* threads */
	pthread_t		*threads;
	/* mutexes */
	pthread_mutex_t	*mt_forks;		/* forks */
	pthread_mutex_t	mt_count;		/* incrementing philo_count */
	pthread_mutex_t	mt_eat;			/* protect eating and stopped state */
	pthread_mutex_t	mt_output;		/* stdout */
}	t_sim;
```

`t_philo` looks like this, where `t_activity` is a simple `enum`.

```C
/* philosopher struct */
typedef struct s_philo
{
	int				id;				/* id from 0 to n - 1 */
	unsigned int	meals_eaten;
	struct timeval	last_eaten;
	t_activity		act;			/* activity enum (e.g. EAT=0) */
}	t_philo;
```

Now this part we have to think very carefully about. We have memory shared among the threads. So which thread changes which memory? One by one, let's make sure there is no race condition.

- `stopped`: This variable is only ever set from `0` to `1`. Interspersed reads and writes have the same effect, so all good.
- `error`: same as above
- `start`: Written by main thread once, only read by philosopher threads after
- `philo_count`: *Incremented* when a new philosopher thread starts. Yup, that's a problem! Mutex `mt_count` to the rescue!
- `philos`: Each thread only reads and writes to their part of the array. *However*, we will read this from the main thread to stop the simulation, creating a race condition. The critical sections are
  - `main reads last_eaten; main writes stopped`
  - `philo reads stopped; philo writes last_eaten`.
- `forks`: Accessed from all philosophers, protected by `mt_forks`.
  
  If not protected by a mutex, a dead philosopher could end up eating - that's impossible. Let's have an `mt_eat` mutex protecting those sections.

#### Who even am I?
In order to make sure that each philosopher is an individual - with their own `id` - and `id`s only exists once, we need mutexes. When a philosopher thread starts it increments the global `philo_count`. And incrementing shared values is done with mutexes.

Here `errset(t_sim *s, status)` sets `sim->error` if `status` is nonzero (see [error handling](#error-handling)).

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

#### The purely Self-interested philosopher
Only think if necessary and grab the forks first chance you get, would be the simplest routine for a philosopher. However, this means he will take a fork away from a starving neighbor. For only two philosopher this solution is still viable.

#### The self-aware philosopher
Can we do better? A philosopher could delay taking the forks to give those with less time left a chance. A good philosopher will make sure that both his neighbors have had time to eat before he eats again. He ensures this by prolonging his thinking until his time of not having the forks (`time_to_sleep` + time spent thinking) is bigger than `time_to_eat + some_margin`. That was enough for me to make the simulation run well enough in all cases. Some empathy goes a long way!

### Finding the dead - and killing them
> A message announcing a philosopher died should be displayed no more than 10 ms
after the actual death of the philosopher.

How do we do that?

In the memory that is shared with the threads we keep a record of each philosopher's last meal time. We check continuously and as soon as we notice that it's more than `time_to_die` milliseconds in the past we write a message and exit the program. 

This does not create a race condition, because each thread only writes to their respective philosopher's meal time and we only read it from the original thread.

Here is what the main thread might look like.

```C
/* This runs in the main thread */
while (check_if_starved(philosopher) || simulation_ended(sim))
	usleep(1000);
announce_dead(philosopher);
/* end simulation, clean up and exit */
```

### Ending the program
Once we have found a starved philosopher, we have to tell him that he starved - no really - by killing the thread. The [man page of `pthread_create`][pthread_create] tells us the ways a thread can exit. We here can unfortunately only kill a thread by returning from `main()`. That's unfortunate, because before doing so we need to destroy the mutexes and deallocate memory while the threads continue to operate on them.

Alternatively we could politely ask the philosophers to please die and only clean up once they obliged. A simple `bool` flag like `simulation_ended` would be enough. This is in shared memory yes, we'll make sure nothing goes wrong later.

What if a philosopher is in the process of waiting for a mutex? How do we wake him up? Well a thinking philosopher will be interrupted by giving him the fork. The block from `pthread_mutex_lock` is gone. When their neighbours are dead, they will get it. Easy enough.

A sleeping or eating philosopher has to interrupt themselves. We can of course divide up a `usleep(time_to_sleep)` like so to make them respect the end of a simulation.

```C
while (!simulation_ended && !finished_sleeping())
	usleep(1000);
```

Does this mess up the timing? A bit, we can mitigate this by measuring everything in microseconds. But ultimately there will be some extra delay.

### Error handling
Most functions like the mutex locking and unlocking return a value that indicates potential failure. How do we deal with failure? I see two options. You either exit with leaks and say it's okay, because it's an exception or you indicate an error in the shared memory and wait for every thread to recognize it and exit.

I prefer the latter, because it makes sure to free all the resources.

# Bonus

## New functions
- [`fork`][fork], [`kill`][kill], [`exit`][exit] and [`waitpid`][waitpid] join the party.
- semaphore handling: [`sem_open`][sem_open], [`sem_close`][sem_close], [`sem_post`][sem_post], [`sem_wait`][sem_wait], [`sem_unlink`][sem_unlink]

## Semaphores
> "A semaphore is an integer whose value is never allowed to fall below zero" - [`sem_overview`][sem-overview]

Besides [mutexes][wiki-mutex], which we've used in the mandatory part, [semaphores][wiki-semaphore] are another way to synchronize concurrent programs and avoid race conditions. Semaphores are like your bank account. If you want to spend ([`sem_wait`][sem_wait]) something, you first need to deposit ([`sem_post`][sem_post]) it.

The name derives from train signals where a train is only free to enter a section of track when a semaphore signals it. This is much the same for us. Our code is only free to enter a *critical section* when not too many threads are already inside it.

You can think of semaphores like a "resource count", presupposing that those resources can be used interchangeably. Our forks are in the *middle* of the table, within reach of everybody, and so are interchangeable.

The use of semaphores in our case is rather simple. We use it of course as the number of available forks like so:

1. Create a named semaphore with [`sem_open`][sem_open] and initialize it to number of forks
2. Use [`sem_wait`][sem_wait] for taking forks and [`sem_post`][sem_post] when returning
3. [`sem_close`][sem_close] it from each process, then [`sem_unlink`][sem_unlink] from the main process.

Normally one can also read the value of a semaphore with [`sem_getvalue`][sem_getvalue]. But we don't even need the value. As long as forks are returned at *some* point, there is no danger of deadlocks.

## Monitoring
The only means of inter-process communication we have is [`kill`][kill]. But without [`sigaction`][sigaction] that's of no use. So then the problem I see is how does the main process recognize starving processes, since the processes themselves will be stuck in [`sem_wait`][sem_wait]? Well, threads again I suppose. Blocking is a good reason to use another thread.

### (Mis-)Using Semaphores
We can also use semaphores as a form of inter-process communication. The sender calls `sem_post` while the recipient calls `sem_wait`. This comes in handy to keep track of the number of hungry (meaning `times_a_philosopher_has_to_eat > 0`) philosophers. Calling `sem_post` after receiving a signal also enables us to have multiple recipients, which is useful as a global `/exit` signal.

### Am I dead yet?
A philosopher can notice himself when he has starved. We are allowed to use threads, so in parallel to each philosopher process we can have a separate thread that checks if he is dead yet. To notify the other philosophers of his early demise, we can publish a `/death` message.


[wiki-concur]:				https://en.wikipedia.org/wiki/Concurrency_(computer_science)
[wiki-thread]:				https://en.wikipedia.org/wiki/Thread_(computing)
[wiki-philo]:				https://en.wikipedia.org/wiki/Dining_philosophers_problem
[wiki-philo-arb]:			https://en.wikipedia.org/wiki/Dining_philosophers_problem#Arbitrator_solution
[wiki-philo-res]:			https://en.wikipedia.org/wiki/Dining_philosophers_problem#Resource_hierarchy_solution
[wiki-deadlock]:			https://en.wikipedia.org/wiki/Deadlock
[wiki-mutex]:				https://en.wikipedia.org/wiki/Mutual_exclusion
[wiki-semaphore]:			https://en.wikipedia.org/wiki/Semaphore_(programming)
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

[kill]:						https://www.man7.org/linux/man-pages/man2/kill.2.html
[exit]:						https://www.man7.org/linux/man-pages/man3/exit.3.html
[sem_open]:					https://pubs.opengroup.org/onlinepubs/9699919799/functions/sem_open.html
[sem_close]:				https://pubs.opengroup.org/onlinepubs/9699919799/functions/sem_close.html
[sem_post]:					https://pubs.opengroup.org/onlinepubs/9699919799/functions/sem_post.html
[sem_wait]:					https://pubs.opengroup.org/onlinepubs/9699919799/functions/sem_wait.html
[sem_unlink]:				https://pubs.opengroup.org/onlinepubs/9699919799/functions/sem_unlink.html
[sem_getvalue]:				https://pubs.opengroup.org/onlinepubs/9699919799/functions/sem_getvalue.html

[sigaction]:				https://www.man7.org/linux/man-pages/man2/sigaction.2.html

[sem-overview]:				https://www.man7.org/linux/man-pages/man7/sem_overview.7.html


[book-hoare]:				http://www.usingcsp.com/cspbook.pdf
[lecture-cs110-08]:			https://web.stanford.edu/class/archive/cs/cs110/cs110.1214/static/lectures/cs110-lecture-08-race-conditions-deadlock.pdf
[lecture-cs110-10]:			https://web.stanford.edu/class/archive/cs/cs110/cs110.1204/static/lectures/10-threads-and-mutexes.pdf