# Issue

If a thread is started before a worker child processes is forked, the worker can fail to respawn. In the context of CPython, the thread state must be updated after forking if there will be calls to the Python interpreter. This is handled by `PyOS_AfterFork_Child` in Python 3 and `PyOS_AfterFork` in Python 2. In the uWSGI lifecycle of a forked worker child process, there is an attempt to acquire the GIL in `master_fixup` before `PyOS_AfterFork[_Child]` is called. This leads to a deadlock which explains the failure for workers to respawn.

This issue is a duplicate of:

- https://github.com/unbit/uwsgi/issues/1149
- https://github.com/unbit/uwsgi/issues/1369

This issue includes a minimal reproduction of a deadlock worker by starting a thread in a `sitecustomize.py` that enters a busy loop. This ensures that the current thread in the Python interpreter is not the main thread when uWSGI forks the child. The result is an invalid thread state in the child process.

## Reproduction

We install the debug version of CPython so that we can debug uWSGI and the Python plugin with gdb. 

The reproduction consists of a simple hello world wsgi application and a `sitecustomize` that starts a thread which enters a busy loop for 5 seconds. 

The `uwsgi.ini` enables a master process and threads along with one worker process with a max worker lifetime of 15 seconds. This allows us to more easily observe the failed attempt to respawn the worker process.

To build and run the reproduction with Python 2.7 and uWSGI 2.0.20, run:

```
docker run --rm -it $(docker build -q .)
```

If the worker was respawning properly, we would expect the output of the process to be:

```
*** uWSGI is running in multiple interpreter mode ***
spawned uWSGI master process (pid: 35)
spawned uWSGI worker 1 (pid: 37, cores: 1)
spawned uWSGI http 1 (pid: 38)
[thread=140112973076224] run: finished.
worker 1 lifetime reached, it was running for 16 second(s)
Respawned uWSGI worker 1 (new pid: 39)
worker 1 lifetime reached, it was running for 16 second(s)
Respawned uWSGI worker 1 (new pid: 40)
```

However, the worker never respawns with uWSGI 2.0.2 in this reproduction.

We can test out the fix provided in #1234 which shows the worker to respawn as expected.

```
docker run --rm -it $(docker build -q --build-arg UWSGI_GIT=majorgreys/uwsgi@4fe3802912726012e632174292ccf765e318f494 .)
```


# Pull Request

This PR adds `pre_uwsgi_fork` and `post_uwsgi_fork` to `uwsgi_plugin` in order to ensure that any necessary changes can be made before and after the call to `uwsgi_fork`. This is used here by the Python plugin to modify the Python interpreter state before forking and then again after forking as is done by `os.fork()` in CPython. With the addition of these two functions, we can drop the `master_fixup` plugin hook and the call to `PyOS_AfterFork[_Child]`. Having made these changes, we need to also change existing hooks that had assumed the GIL was in a given state but will now be responsible for acquiring and releasing the GIL when calls are made to the Python interpreter.

Tests are included for the following configurations:

- master https://uwsgi-docs.readthedocs.io/en/latest/Options.html#master
- workers https://uwsgi-docs.readthedocs.io/en/latest/Options.html#workers
- enabled threads https://uwsgi-docs.readthedocs.io/en/latest/Options.html#enable-threads
- single interpeter https://uwsgi-docs.readthedocs.io/en/latest/Options.html#single-interpreter
- threads https://uwsgi-docs.readthedocs.io/en/latest/Options.html#threads
- emperor https://uwsgi-docs.readthedocs.io/en/latest/Options.html#emperor
- spooler https://uwsgi-docs.readthedocs.io/en/latest/Options.html#spooler

Fixes #1234

# Notes

## Forking and the Python plugin

If `PyOS_AfterFork()` is called immediately following `uwsgi_fork()`, uwsgi aborts with a fatal error raised when using a debug version of cPython.

``` 
Fatal Python error: Invalid thread state for this thread
```

Add a breakpoint to `Py_FatalError`:

```
break Py_FatalError
run
where
```

The output ends with:

```
[Switching to Thread 0x7f4b8fc6c780 (LWP 17)]

Thread 2.1 "uwsgi" hit Breakpoint 1, Py_FatalError (msg=0x564bc857a140 "Invalid thread state for this thread") at Python/pythonrun.c:1689
1689        fprintf(stderr, "Fatal Python error: %s\n", msg);
(gdb) where
#0  Py_FatalError (msg=0x55f1e77c3140 "Invalid thread state for this thread") at Python/pythonrun.c:1689
#1  0x000055f1e76f39b6 in PyThreadState_Swap ()
#2  0x000055f1e76b5889 in PyEval_RestoreThread ()
#3  0x000055f1e77109ed in lock_PyThread_acquire_lock ()
#4  0x000055f1e7645323 in PyCFunction_Call ()
#5  0x000055f1e75f1ceb in PyObject_Call ()
#6  0x000055f1e75f298c in PyObject_CallFunctionObjArgs ()
#7  0x000055f1e76c054f in PyEval_EvalFrameEx ()
#8  0x000055f1e76c3921 in PyEval_EvalCodeEx ()
#9  0x000055f1e7621f98 in function_call ()
#10 0x000055f1e75f1ceb in PyObject_Call ()
#11 0x000055f1e75f1e47 in call_function_tail ()
#12 0x000055f1e75f2237 in PyObject_CallMethod ()
#13 0x000055f1e76b56f3 in PyEval_ReInitThreads ()
#14 0x000055f1e7714ee5 in PyOS_AfterFork ()
#15 0x000055f1e75bfe0b in uwsgi_python_post_uwsgi_fork ()
#16 0x000055f1e7573c4b in uwsgi_respawn_worker ()
#17 0x000055f1e75b0d2e in uwsgi_start ()
#18 0x000055f1e75b39a6 in uwsgi_setup ()
#19 0x000055f1e755ce19 in main ()
```

This call stack shows how the invalid thread state is restored once `threading._after_fork()` is called.

We can inspect the thread state by adding a breakpoint at `PyEval_RestoreThread` after `PyOS_AfterFork`:

```
break PyOS_AfterFork
end
run
break PyEval_RestoreThread
continue
print tstate->thread_id
```

The thread id of the thread being restored matches the thread id of the busy loop thread started in the master process:

```
[thread=139976154965760] run: start busy loop for 5 seconds.
....
(gdb) print tstate->thread_id
$1 = 139976154965760
```
